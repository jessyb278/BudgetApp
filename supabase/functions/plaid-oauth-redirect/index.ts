// Supabase Edge Function: Plaid OAuth redirect endpoint
// When a bank redirects here after OAuth, this page loads.
// For full OAuth: configure Universal Links so this URL opens your app instead.
// Add this exact URL to Plaid Dashboard → Team Settings → API → Allowed redirect URIs

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const HTML = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Redirecting to BudgetApp</title>
</head>
<body>
  <p>Redirecting back to BudgetApp…</p>
  <script>setTimeout(function(){ window.close(); }, 500);</script>
</body>
</html>`

serve(async (req) => {
  return new Response(HTML, {
    headers: { "Content-Type": "text/html; charset=utf-8" },
  })
})
