import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const PLAID_BASE = "https://sandbox.plaid.com"

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: { "Access-Control-Allow-Origin": "*" } })
  }

  try {
    const authHeader = req.headers.get("Authorization")
    if (!authHeader) {
      return Response.json({ error: "Missing Authorization header" }, { status: 401 })
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error: authError } = await supabase.auth.getUser(
      authHeader.replace("Bearer ", "")
    )
    if (authError || !user) {
      return Response.json({ error: "Unauthorized" }, { status: 401 })
    }

    const clientId = Deno.env.get("PLAID_CLIENT_ID")
    const secret = Deno.env.get("PLAID_SECRET")
    if (!clientId || !secret) {
      return Response.json({ error: "Plaid not configured" }, { status: 500 })
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? ""
    const redirectUri = Deno.env.get("PLAID_REDIRECT_URI") ?? `${supabaseUrl}/functions/v1/plaid-oauth-redirect`

    const linkTokenBody: Record<string, unknown> = {
      client_id: clientId,
      secret,
      user: { client_user_id: user.id },
      client_name: "BudgetApp",
      products: ["transactions"],
      country_codes: ["US"],
      language: "en",
      redirect_uri: redirectUri,
    }

    const res = await fetch(`${PLAID_BASE}/link/token/create`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(linkTokenBody),
    })

    const data = await res.json()
    if (data.error) {
      return Response.json({ error: data.error_message ?? "Plaid error" }, { status: 400 })
    }

    return Response.json({ link_token: data.link_token })
  } catch (e) {
    return Response.json({ error: String(e) }, { status: 500 })
  }
})
