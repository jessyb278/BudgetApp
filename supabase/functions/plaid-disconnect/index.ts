// Supabase Edge Function: Disconnect all Plaid institutions for a user
// Deletes plaid_connections, accounts, and transactions

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

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

    // 1. Get all account IDs for this user
    const { data: accounts } = await supabase
      .from("accounts")
      .select("id")
      .eq("user_id", user.id)

    const accountIds = (accounts ?? []).map((a) => a.id)

    // 2. Delete transactions for those accounts
    if (accountIds.length > 0) {
      await supabase.from("transactions").delete().in("account_id", accountIds)
    }

    // 3. Delete accounts
    await supabase.from("accounts").delete().eq("user_id", user.id)

    // 4. Delete plaid_connections
    const { error: connErr } = await supabase
      .from("plaid_connections")
      .delete()
      .eq("user_id", user.id)

    if (connErr) {
      return Response.json({ error: connErr.message }, { status: 500 })
    }

    return Response.json({ success: true })
  } catch (e) {
    return Response.json({ error: String(e) }, { status: 500 })
  }
})
