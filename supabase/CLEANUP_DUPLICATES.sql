DELETE FROM accounts a
USING accounts b
WHERE a.user_id = b.user_id
  AND COALESCE(a.plaid_account_id, '') = COALESCE(b.plaid_account_id, '')
  AND a.id > b.id;

-- Partial index so rows without a Plaid id are not treated as duplicates of each other.
DROP INDEX IF EXISTS idx_accounts_user_plaid_unique;
CREATE UNIQUE INDEX idx_accounts_user_plaid_unique ON accounts (user_id, plaid_account_id)
WHERE plaid_account_id IS NOT NULL;
