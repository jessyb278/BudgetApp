// Supabase Edge Function: Exchange Plaid public_token and sync data
// 1. Exchanges public_token for access_token
// 2. Fetches accounts and transactions from Plaid
// 3. Stores connection, accounts, and transactions in Supabase

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const PLAID_BASE = "https://sandbox.plaid.com"

// Map Plaid personal_finance_category.primary to app categories
function mapPlaidCategoryToApp(primary: string): string {
  const p = (primary || "").toUpperCase()
  if (p.includes("TRANSFER")) return "Transfer"
  if (p.includes("LOAN_PAYMENT") || p.includes("CREDIT_CARD_PAYMENT")) return "Payment"
  if (p.includes("FOOD") || p.includes("RESTAURANT") || p.includes("GROCERIES")) return "Food"
  if (p.includes("TRANSPORT") || p.includes("GAS") || p.includes("AUTOMOTIVE")) return "Transport"
  if (p.includes("MERCHANDISE") || p.includes("SHOPPING") || p.includes("RETAIL")) return "Shopping"
  if (p.includes("RENT") || p.includes("HOUSING") || p.includes("MORTGAGE")) return "Housing"
  if (p.includes("UTILITIES") || p.includes("GAS") || p.includes("ELECTRICITY")) return "Utilities"
  if (p.includes("INCOME") || p.includes("WAGES") || p.includes("SALARY")) return "Income"
  return "Other"
}

function getTransactionType(primary: string): "purchase" | "transfer" | "payment" {
  const p = (primary || "").toUpperCase()
  if (p.includes("TRANSFER")) return "transfer"
  if (p.includes("LOAN_PAYMENT") || p.includes("CREDIT_CARD_PAYMENT")) return "payment"
  return "purchase"
}

// Part 1: Map Plaid type/subtype to category_group
function getCategoryGroup(plaidType: string, subtype: string): string {
  const t = (plaidType || "depository").toLowerCase()
  const st = (subtype || "").toLowerCase()
  if (t === "depository") {
    if (st.includes("checking")) return "Checking"
    if (st.includes("savings")) return "Savings"
    return "Checking"
  }
  if (t === "credit") return "Credit Cards"
  if (t === "loan") return "Loans"
  if (t === "investment" || st.includes("brokerage") || st.includes("401") || st.includes("ira") || st.includes("retirement")) return "Investments"
  return "Checking"
}

// Part 3: Normalize balance sign - assets positive, liabilities negative
function normalizeBalance(rawBalance: number | null, classification: string): number {
  const bal = rawBalance ?? 0
  if (classification === "liability") return -Math.abs(bal)
  return Math.abs(bal)
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: { "Access-Control-Allow-Origin": "*" } })
  }

  try {
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return Response.json({ error: "Missing Authorization header" }, { status: 401 })
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? ""
    const supabaseAnon = Deno.env.get("SUPABASE_ANON_KEY") ?? ""
    const supabaseService = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""

    const authClient = createClient(supabaseUrl, supabaseAnon, {
      global: { headers: { Authorization: authHeader } },
    })
    const { data: { user }, error: authError } = await authClient.auth.getUser(
      authHeader.replace("Bearer ", "")
    )
    if (authError || !user) {
      return Response.json({ error: "Unauthorized" }, { status: 401 })
    }

    const supabase = createClient(supabaseUrl, supabaseService)

    const { public_token } = await req.json()
    if (!public_token) {
      return Response.json({ error: "Missing public_token" }, { status: 400 })
    }

    const clientId = Deno.env.get("PLAID_CLIENT_ID")
    const secret = Deno.env.get("PLAID_SECRET")
    if (!clientId || !secret) {
      return Response.json({ error: "Plaid not configured" }, { status: 500 })
    }

    // 1. Exchange public_token for access_token
    const exchangeRes = await fetch(`${PLAID_BASE}/item/public_token/exchange`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        client_id: clientId,
        secret,
        public_token,
      }),
    })
    const exchangeData = await exchangeRes.json()
    if (exchangeData.error) {
      return Response.json({ error: exchangeData.error_message ?? "Exchange failed" }, { status: 400 })
    }

    const { access_token, item_id } = exchangeData

    // 2. Get institution name (optional - sandbox may return generic)
    let institutionName = "Connected Bank"
    try {
      const itemRes = await fetch(`${PLAID_BASE}/item/get`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ client_id: clientId, secret, access_token }),
      })
      const itemData = await itemRes.json()
      if (!itemData.error && itemData.item?.institution_id) {
        institutionName = itemData.item.institution_id
      }
    } catch (_) {}

    // 3. Check for existing connection (prevent duplicate)
    const { data: existing } = await supabase
      .from("plaid_connections")
      .select("id")
      .eq("user_id", user.id)
      .eq("item_id", item_id)
      .single()

    if (existing) {
      return Response.json({ error: "This bank is already linked" }, { status: 409 })
    }

    // 4. Store connection (access_token stays on server only)
    const { data: conn, error: connErr } = await supabase
      .from("plaid_connections")
      .insert({
        user_id: user.id,
        item_id,
        access_token,
        institution_name: institutionName,
        last_sync: new Date().toISOString(),
      })
      .select("id")
      .single()

    if (connErr) {
      return Response.json({ error: connErr.message }, { status: 500 })
    }

    // 5. Fetch accounts
    const accountsRes = await fetch(`${PLAID_BASE}/accounts/get`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ client_id: clientId, secret, access_token }),
    })
    const accountsData = await accountsRes.json()
    if (accountsData.error) {
      return Response.json({ error: accountsData.error_message ?? "Accounts fetch failed" }, { status: 400 })
    }

    const plaidAccounts = accountsData.accounts || []

    // 6. Upsert accounts (Part 1-3: classification, category_group, normalized balance)
    // Fetch existing to preserve include_in_net_worth, custom_name, is_hidden
    const plaidIds = plaidAccounts.map((pa) => pa.account_id)
    const { data: existingAccounts } = await supabase
      .from("accounts")
      .select("id, plaid_account_id, include_in_net_worth, custom_name, is_hidden")
      .eq("user_id", user.id)
      .in("plaid_account_id", plaidIds)

    const existingByPlaid = new Map((existingAccounts ?? []).map((a) => [a.plaid_account_id, a]))

    const accountIdMap: Record<string, string> = {}
    for (const pa of plaidAccounts) {
      const plaidType = (pa.type || "depository").toLowerCase()
      const subtype = (pa.subtype || "").toLowerCase()
      const classification = ["credit", "loan"].includes(plaidType) ? "liability" : "asset"
      const categoryGroup = getCategoryGroup(plaidType, subtype)
      const rawBalance = pa.balances?.current ?? 0
      const balance = normalizeBalance(rawBalance, classification)

      const existing = existingByPlaid.get(pa.account_id)

      const row = {
        user_id: user.id,
        plaid_account_id: pa.account_id,
        name: pa.name,
        type: plaidType,
        subtype: subtype || null,
        classification,
        category_group: categoryGroup,
        balance,
        institution: institutionName,
        include_in_net_worth: existing?.include_in_net_worth ?? true,
        custom_name: existing?.custom_name ?? null,
        is_hidden: existing?.is_hidden ?? false,
      }

      const { data: upserted } = await supabase
        .from("accounts")
        .upsert(row, { onConflict: "user_id,plaid_account_id", ignoreDuplicates: false })
        .select("id")
        .single()

      if (upserted?.id) accountIdMap[pa.account_id] = upserted.id
    }

    // 7. Fetch transactions (sync, cursor-based)
    let cursor: string | null = null
    let hasMore = true
    const allAdded: Array<{
      transaction_id: string
      account_id: string
      name: string
      amount: number
      date: string
      category: string[]
      merchant_name?: string
    }> = []

    while (hasMore) {
      const syncRes = await fetch(`${PLAID_BASE}/transactions/sync`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          client_id: clientId,
          secret,
          access_token,
          cursor: cursor,
          count: 500,
        }),
      })
      const syncData = await syncRes.json()
      if (syncData.error) break

      for (const t of syncData.added || []) {
        // Plaid: positive = money out, negative = money in. Store as negative for expenses, positive for income.
        const plaidAmount = t.amount ?? 0
        const amount = plaidAmount > 0 ? -plaidAmount : Math.abs(plaidAmount)
        allAdded.push({
          transaction_id: t.transaction_id,
          account_id: t.account_id,
          name: t.name || t.merchant_name || "Unknown",
          amount,
          date: t.date,
          category: t.personal_finance_category?.primary || t.category?.[0] || "Uncategorized",
          merchant_name: t.merchant_name,
        })
      }

      hasMore = syncData.has_more === true
      cursor = syncData.next_cursor || null

      if (syncData.added?.length === 0 && !hasMore) break
    }

    // 8. Update cursor in plaid_connections
    if (cursor) {
      await supabase
        .from("plaid_connections")
        .update({ transactions_cursor: cursor, last_sync: new Date().toISOString() })
        .eq("id", conn.id)
    }

    // 9. Insert transactions (Part 9: mapped category, transaction_type)
    for (const t of allAdded) {
      const supabaseAccountId = accountIdMap[t.account_id]
      if (!supabaseAccountId) continue

      const plaidPrimary =
        typeof t.category === "string"
          ? t.category
          : Array.isArray(t.category)
          ? t.category[0]
          : "Uncategorized"
      const transactionType = getTransactionType(plaidPrimary)
      const appCategory = mapPlaidCategoryToApp(plaidPrimary)

      await supabase.from("transactions").insert({
        user_id: user.id,
        account_id: supabaseAccountId,
        name: t.name,
        amount: t.amount,
        category: appCategory || "Other",
        transaction_type: transactionType,
        plaid_category_primary: plaidPrimary,
        date: t.date,
        is_recurring: false,
        is_reviewed: false,
      })
    }

    return Response.json({
      success: true,
      accounts_count: plaidAccounts.length,
      transactions_count: allAdded.length,
    })
  } catch (e) {
    return Response.json({ error: String(e) }, { status: 500 })
  }
})
