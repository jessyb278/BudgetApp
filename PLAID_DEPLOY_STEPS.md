# Step-by-Step: Deploy Plaid Functions (No CLI Required)

You can deploy everything from the **Supabase Dashboard**—no terminal commands needed.

---

## Part 1: Deploy the new `plaid-oauth-redirect` function

### Step 1.1: Open Supabase Dashboard
1. Go to [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Sign in and open your **BudgetApp** project

### Step 1.2: Create the function
1. Click **Edge Functions** in the left sidebar
2. Click **Deploy a new function** (or **Create function**)
3. Choose **Via Editor** (or **Create from scratch**)
4. Name it: `plaid-oauth-redirect`

### Step 1.3: Paste the code
Replace any default code with this exactly:

```typescript
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
```

### Step 1.4: Deploy
1. Click **Deploy function** (or **Deploy**)
2. Wait for the success message (usually 10–30 seconds)

---

## Part 2: Update the `plaid-create-link-token` function

### Step 2.1: Open the existing function
1. In **Edge Functions**, click **plaid-create-link-token**

### Step 2.2: Open the Code tab
1. Click the **Code** tab (or **Edit**)

### Step 2.3: Replace the link token creation block
Find this section (around lines 39–52):

```typescript
    const res = await fetch(`${PLAID_BASE}/link/token/create`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        client_id: clientId,
        secret,
        user: { client_user_id: user.id },
        client_name: "BudgetApp",
        products: ["transactions"],
        country_codes: ["US"],
        language: "en",
      }),
    })
```

Replace it with this (adds `redirect_uri`):

```typescript
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
```

### Step 2.4: Save and deploy
1. Click **Deploy** (or **Save and deploy**)

---

## Part 3: Add redirect URI to Plaid Dashboard

### Step 3.1: Open Plaid Dashboard
1. Go to [https://dashboard.plaid.com](https://dashboard.plaid.com)
2. Sign in

### Step 3.2: Add the redirect URI
1. Click **Team Settings** (gear icon or your team name in the top right)
2. Open the **API** tab
3. Find **Allowed redirect URIs**
4. Click **Configure** or **Add New URI**
5. Paste this exactly (use your real project ref if different):
   ```
   https://jadbjioibmavqyezxdyg.supabase.co/functions/v1/plaid-oauth-redirect
   ```
6. Save

---

## Part 4: Deploy `plaid-disconnect` (for Disconnect Institutions button)

### Step 4.1: Create the function
1. In **Edge Functions**, click **Deploy a new function**
2. Name it: `plaid-disconnect`

### Step 4.2: Paste the code
Replace any default code with the contents of `supabase/functions/plaid-disconnect/index.ts` (or copy from the project file)

### Step 4.3: Deploy
1. Click **Deploy function**

---

## Part 5: Test in the app

1. Run your app in the simulator
2. Sign in
3. Go to **More** → **Connect Bank**
4. Tap **Connect Bank**
5. Choose **First Platypus Bank**
6. Username: `user_good` | Password: `pass_good` | Code: `1234`

The "redirect_uri is missing" warning should be gone.
