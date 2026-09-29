import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const PLAID_BASE = "https://sandbox.plaid.com"

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
    const clientId = Deno.env.get("PLAID_CLIENT_ID")
    const secret = Deno.env.get("PLAID_SECRET")
    if (!clientId || !secret) {
      return Response.json({ error: "Plaid not configured" }, { status: 500 })
    }

    const { data: connections } = await supabase
      .from("plaid_connections")
      .select("id, access_token, institution_name, transactions_cursor")
      .eq("user_id", user.id)

    if (!connections || connections.length === 0) {
      return Response.json({ success: true, accounts_updated: 0, transactions_added: 0 })
    }

    let totalAccountsUpdated = 0
    let totalTransactionsAdded = 0

    for (const conn of connections) {
      const access_token = conn.access_token

      const accountsRes = await fetch(`${PLAID_BASE}/accounts/get`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ client_id: clientId, secret, access_token }),
      })
      const accountsData = await accountsRes.json()
      if (accountsData.error) continue

      const plaidAccounts = accountsData.accounts || []
      const institutionName = conn.institution_name ?? "Connected Bank"

      const plaidIds = plaidAccounts.map((pa: { account_id: string }) => pa.account_id)
      const { data: existingAccounts } = await supabase
        .from("accounts")
        .select("id, plaid_account_id, include_in_net_worth, custom_name, is_hidden")
        .eq("user_id", user.id)
        .in("plaid_account_id", plaidIds)

      const existingByPlaid = new Map((existingAccounts ?? []).map((a: { plaid_account_id: string }) => [a.plaid_account_id, a]))

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

        await supabase
          .from("accounts")
          .upsert(row, { onConflict: "user_id,plaid_account_id", ignoreDuplicates: false })
        totalAccountsUpdated++
      }

      let cursor: string | null = conn.transactions_cursor ?? null
      let hasMore = true
      const accountIdMap: Record<string, string> = {}
      const { data: ourAccounts } = await supabase
        .from("accounts")
        .select("id, plaid_account_id")
        .eq("user_id", user.id)
        .in("plaid_account_id", plaidAccounts.map((pa: { account_id: string }) => pa.account_id))
      for (const a of ourAccounts ?? []) {
        accountIdMap[a.plaid_account_id] = a.id
      }

      while (hasMore) {
        const syncRes = await fetch(`${PLAID_BASE}/transactions/sync`, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            client_id: clientId,
            secret,
            access_token,
            cursor,
            count: 500,
          }),
        })
        const syncData = await syncRes.json()
        if (syncData.error) break

        for (const t of syncData.added || []) {
          const supabaseAccountId = accountIdMap[t.account_id]
          if (!supabaseAccountId) continue

          const plaidPrimary = t.personal_finance_category?.primary || t.category?.[0] || "Uncategorized"
          const transactionType = getTransactionType(plaidPrimary)
          const appCategory = mapPlaidCategoryToApp(plaidPrimary)

          const plaidAmount = t.amount ?? 0
          const amount = plaidAmount > 0 ? -plaidAmount : Math.abs(plaidAmount)
          await supabase.from("transactions").insert({
            user_id: user.id,
            account_id: supabaseAccountId,
            name: t.name || t.merchant_name || "Unknown",
            amount,
            category: appCategory || "Other",
            transaction_type: transactionType,
            plaid_category_primary: plaidPrimary,
            date: t.date,
            is_recurring: false,
            is_reviewed: false,
          })
          totalTransactionsAdded++
        }

        hasMore = syncData.has_more === true
        cursor = syncData.next_cursor ?? null
        if (syncData.added?.length === 0 && !hasMore) break
      }

      if (cursor) {
        await supabase
          .from("plaid_connections")
          .update({ transactions_cursor: cursor, last_sync: new Date().toISOString() })
          .eq("id", conn.id)
      }
    }

    return Response.json({
      success: true,
      accounts_updated: totalAccountsUpdated,
      transactions_added: totalTransactionsAdded,
    })
  } catch (e) {
    return Response.json({ error: String(e) }, { status: 500 })
  }
})
