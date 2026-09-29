DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'accounts' AND column_name = 'category_group') THEN
    ALTER TABLE accounts ADD COLUMN category_group TEXT;
  END IF;
END $$;

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

DELETE FROM accounts a
USING accounts b
WHERE a.user_id = b.user_id
  AND COALESCE(a.plaid_account_id, '') = COALESCE(b.plaid_account_id, '')
  AND a.id > b.id;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'accounts_user_plaid_unique'
  ) THEN
    ALTER TABLE accounts ADD CONSTRAINT accounts_user_plaid_unique UNIQUE (user_id, plaid_account_id);
  END IF;
END $$;
