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
