# BudgetApp

An iOS personal finance app built with SwiftUI. It connects to bank, credit card, loan, and investment accounts through Plaid, stores data in Supabase, and shows net worth, spending, budgets, and goals in one dashboard.

## Features

- **Bank linking with Plaid.** Connect institutions through Plaid Link, refresh balances and transactions, and disconnect all institutions.
- **Account normalization.** Each account is classified as an asset or a liability and grouped as Checking, Savings, Credit Cards, Loans, or Investments. Liability balances are stored as negative numbers and asset balances as positive numbers, no matter which sign Plaid returns.
- **No duplicate accounts.** Accounts are upserted on `(user_id, plaid_account_id)`, so syncing the same institution again updates existing rows instead of adding new ones.
- **Net worth.** Net worth is total assets minus total liabilities, so loans and credit card balances reduce it.
- **Spending that ignores money movement.** Plaid categories are mapped to Food, Transport, Shopping, Housing, Utilities, and Income. Transfers, credit card payments, and loan payments are left out of spending totals.
- **Connected Accounts screen.** Accounts are split into Assets and Liabilities, with collapsible groups organized by institution.
- **Per-account settings.** Rename an account, hide it, or exclude it from net worth.

## Tech stack

| Layer | Technology |
| --- | --- |
| iOS app | Swift, SwiftUI |
| Backend | Supabase (PostgreSQL, Auth, Edge Functions) |
| Edge Functions | TypeScript on Deno |
| Bank data | Plaid API, Plaid Link iOS SDK |
| Swift packages | `supabase-swift`, `plaid-link-ios-spm`, `swift-algorithms` |

## Project structure

```
BudgetApp/
├── BudgetApp/
│   ├── Components/      Reusable UI pieces such as progress bars and charts
│   ├── DesignSystem/    Colors, spacing, typography, light and dark themes
│   ├── Models/          Account, Transaction, Budget, Goal, and Supabase records
│   ├── Services/        Supabase, Plaid, and authentication clients
│   └── Views/           Dashboard, Connected Accounts, Net Worth, and other screens
└── supabase/
    ├── functions/       Edge Functions for Plaid
    └── migrations/      SQL schema changes
```

### Edge Functions

| Function | Purpose |
| --- | --- |
| `plaid-create-link-token` | Creates the token used to open Plaid Link |
| `plaid-exchange` | Exchanges the public token, then saves the new accounts and transactions |
| `plaid-sync` | Refreshes accounts and pulls new transactions for linked institutions |
| `plaid-disconnect` | Removes the user's Plaid connections, accounts, and transactions |
| `plaid-oauth-redirect` | Landing page for Plaid's OAuth redirect |

## Getting started

### Requirements

- Xcode with the iOS 26.2 SDK
- A Supabase project
- A Plaid account with Sandbox API keys

### 1. Configure Supabase

The migrations in `supabase/migrations` extend an existing schema with `accounts`, `transactions`, `budgets`, and `goals` tables. Create those base tables first, then run each migration in order in the Supabase SQL Editor:

1. `20240318000000_plaid_integration.sql`
2. `20240319000000_account_classification_and_transactions.sql`
3. `20240320000000_account_normalization_and_upsert.sql`

### 2. Add secrets

In Supabase, go to **Project Settings → Edge Functions → Secrets** and add:

- `PLAID_CLIENT_ID`
- `PLAID_SECRET`
- `PLAID_REDIRECT_URI` (optional; defaults to the `plaid-oauth-redirect` function URL)

Supabase supplies `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` to Edge Functions automatically.

### 3. Deploy the Edge Functions

With the Supabase CLI:

```bash
supabase functions deploy plaid-create-link-token
supabase functions deploy plaid-exchange
supabase functions deploy plaid-sync
supabase functions deploy plaid-disconnect
supabase functions deploy plaid-oauth-redirect
```

You can also paste each function into the Supabase Dashboard. See [PLAID_DEPLOY_STEPS.md](PLAID_DEPLOY_STEPS.md).

### 4. Point the app at your project

Set your project URL and anon key in `BudgetApp/Services/SupabaseConfig.swift`, then open `BudgetApp.xcodeproj` in Xcode and run the app.

### 5. Link a test bank

In Plaid Sandbox, sign in with:

- Username: `user_good`
- Password: `pass_good`
- Verification code: `1234`

## Notes

- The Edge Functions call Plaid's Sandbox environment (`https://sandbox.plaid.com`). Change `PLAID_BASE` in each function to use Development or Production.
- Plaid access tokens are kept on the server in `plaid_connections` and are never sent to the app.
- The credit score and the AI assistant's replies are placeholders for now.
- If an older database already contains duplicate accounts, run `supabase/CLEANUP_DUPLICATES.sql`.
