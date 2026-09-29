-- Run this in Supabase SQL Editor to remove duplicate accounts
-- Dashboard > SQL Editor > New query > Paste and Run

-- 1. Remove duplicate accounts (keep one per plaid_account_id per user)
DELETE FROM accounts a
USING accounts b
WHERE a.user_id = b.user_id
  AND COALESCE(a.plaid_account_id, '') = COALESCE(b.plaid_account_id, '')
  AND a.id > b.id;

-- 2. Add unique constraint (prevents future duplicates from plaid-exchange/plaid-sync)
-- Uses partial index to allow legacy rows with NULL plaid_account_id
DROP INDEX IF EXISTS idx_accounts_user_plaid_unique;
CREATE UNIQUE INDEX idx_accounts_user_plaid_unique ON accounts (user_id, plaid_account_id)
WHERE plaid_account_id IS NOT NULL;
