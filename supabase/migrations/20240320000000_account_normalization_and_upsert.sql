-- Account Normalization & Duplicate Fix (Parts 1-2)
-- 1. Add category_group to accounts
-- 2. UNIQUE on (user_id, plaid_account_id) for upsert
-- 3. Remove duplicate accounts (keep one per plaid_account_id)

-- 1. Add category_group column
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'accounts' AND column_name = 'category_group') THEN
    ALTER TABLE accounts ADD COLUMN category_group TEXT;
  END IF;
END $$;

-- 2. Backfill category_group from type/subtype
UPDATE accounts
SET category_group = CASE
  WHEN LOWER(COALESCE(type, 'depository')) = 'depository' AND LOWER(COALESCE(subtype, '')) LIKE '%checking%' THEN 'Checking'
  WHEN LOWER(COALESCE(type, 'depository')) = 'depository' AND LOWER(COALESCE(subtype, '')) LIKE '%savings%' THEN 'Savings'
  WHEN LOWER(COALESCE(type, 'depository')) = 'credit' THEN 'Credit Cards'
  WHEN LOWER(COALESCE(type, 'depository')) = 'loan' THEN 'Loans'
  WHEN LOWER(COALESCE(type, 'depository')) IN ('investment', 'brokerage') OR LOWER(COALESCE(subtype, '')) ~ '401|ira|retirement|brokerage' THEN 'Investments'
  WHEN LOWER(COALESCE(type, 'depository')) = 'depository' THEN 'Checking'
  ELSE 'Checking'
END
WHERE category_group IS NULL;

-- 3. Remove duplicates: keep one row per (user_id, plaid_account_id)
-- For same plaid_account_id: keep row with smallest id
-- For both null plaid_account_id: keep row with smallest id
DELETE FROM accounts a
USING accounts b
WHERE a.user_id = b.user_id
  AND COALESCE(a.plaid_account_id, '') = COALESCE(b.plaid_account_id, '')
  AND a.id > b.id;

-- 4. Add UNIQUE constraint for upsert (user_id, plaid_account_id)
-- Enables ON CONFLICT for plaid-exchange and plaid-sync
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'accounts_user_plaid_unique'
  ) THEN
    ALTER TABLE accounts ADD CONSTRAINT accounts_user_plaid_unique UNIQUE (user_id, plaid_account_id);
  END IF;
END $$;
