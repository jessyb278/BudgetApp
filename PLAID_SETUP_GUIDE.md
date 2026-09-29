# Plaid Integration — Part 2: Deployment Guide

## What We Built

1. **plaid-create-link-token** — Creates a `link_token` for Plaid Link (called before opening Link)
2. **plaid-exchange** — Exchanges `public_token` for `access_token`, fetches accounts/transactions, stores in Supabase
3. **Database migration** — Creates `plaid_connections` table, adds `plaid_account_id` to accounts

---

## Step 2A: Run the Database Migration

1. Go to [Supabase Dashboard](https://supabase.com/dashboard) → your **BudgetApp** project
2. Click **SQL Editor** in the left sidebar
3. Click **New query**
4. Open the file `supabase/migrations/20240318000000_plaid_integration.sql` in your project
5. Copy its entire contents and paste into the SQL Editor
6. Click **Run** (or Cmd+Enter)
7. You should see "Success. No rows returned"

---

## Step 2B: Install Supabase CLI (for deploying Edge Functions)

You have two options: **A) Use Supabase CLI** (recommended) or **B) Deploy via Dashboard**.

### Option A: Install Supabase CLI

```bash
# macOS (Homebrew)
brew install supabase/tap/supabase
```

Or download from: https://github.com/supabase/cli/releases

### Link your project

```bash
cd /Users/jessyb/Documents/iOS_Apps/BudgetApp
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

Find your **Project ref** in Supabase Dashboard → Settings → General (it's in the URL or under "Reference ID").

---

## Step 2C: Deploy the Edge Functions

```bash
cd /Users/jessyb/Documents/iOS_Apps/BudgetApp
supabase functions deploy plaid-create-link-token
supabase functions deploy plaid-exchange
supabase functions deploy plaid-oauth-redirect
```

### Add the required secrets (if not already done)

In Supabase Dashboard → **Project Settings** → **Edge Functions** → **Secrets**, ensure you have:

- `PLAID_CLIENT_ID`
- `PLAID_SECRET`

Supabase automatically provides `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` to Edge Functions.

### OAuth redirect URI (fixes "redirect_uri is missing" warning)

1. **Deploy** the `plaid-oauth-redirect` function (see deploy command above).
2. **Add the redirect URI to Plaid Dashboard:**
   - Go to [Plaid Dashboard](https://dashboard.plaid.com) → **Team Settings** → **API**
   - Under **Allowed redirect URIs**, click **Configure** → **Add New URI**
   - Add: `https://YOUR_PROJECT_REF.supabase.co/functions/v1/plaid-oauth-redirect`  
     (Replace `YOUR_PROJECT_REF` with your Supabase project ref, e.g. `jadbjioibmavqyezxdyg`)
3. The link token is now created with this `redirect_uri` by default. To use a custom domain (for Universal Links), set the `PLAID_REDIRECT_URI` secret in Supabase.

---

## Step 2D: Verify Deployment

1. In Supabase Dashboard → **Edge Functions**, you should see:
   - `plaid-create-link-token`
   - `plaid-exchange`

2. Your function URLs will be:
   - `https://YOUR_PROJECT_REF.supabase.co/functions/v1/plaid-create-link-token`
   - `https://YOUR_PROJECT_REF.supabase.co/functions/v1/plaid-exchange`
   - `https://YOUR_PROJECT_REF.supabase.co/functions/v1/plaid-disconnect`

3. Deploy `plaid-disconnect` for the "Disconnect All Institutions" button (Supabase Dashboard → Edge Functions → Create → name: `plaid-disconnect`).
4. Deploy `plaid-sync` for the refresh flow.

### If you see duplicate accounts

Run `supabase/CLEANUP_DUPLICATES.sql` in the SQL Editor to remove duplicates and add the unique constraint.

---

## Part 4: iOS App (DONE)

The following has been implemented:
- **PlaidService** — Fetches link_token, exchanges public_token
- **ConnectBankView** — "Connect Bank" button, Plaid Link UI, loading/success/error states
- **ConnectedAccountsScreen** — Shows real linked accounts or "Connect Bank" when empty
- **LinkKit** package — Added via Swift Package Manager

### How to test

1. Run the app on a simulator or device
2. Sign in (or create an account)
3. Go to **More** → **Connect Bank** (or **Manage Accounts** → **Connect Bank** when empty)
4. Tap **Connect Bank**
5. In Plaid Link sandbox, use:
   - Username: `user_good`
   - Password: `pass_good`
6. For verification code screens, use: `1234`
7. After linking, accounts and transactions will sync to Supabase and appear in the app

**OAuth warning:** If you see "redirect_uri is missing", deploy `plaid-oauth-redirect` and add the redirect URI to Plaid Dashboard (see Step 2C above). For quick testing without OAuth, try **Tattersall Federal Credit Union** instead of First Platypus Bank—some institutions may complete without the full OAuth redirect.
