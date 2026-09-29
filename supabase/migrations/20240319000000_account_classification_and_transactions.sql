DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'accounts' AND column_name = 'subtype') THEN
    ALTER TABLE accounts ADD COLUMN subtype TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'accounts' AND column_name = 'classification') THEN
    ALTER TABLE accounts ADD COLUMN classification TEXT DEFAULT 'asset';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'transactions' AND column_name = 'transaction_type') THEN
    ALTER TABLE transactions ADD COLUMN transaction_type TEXT DEFAULT 'purchase';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'transactions' AND column_name = 'plaid_category_primary') THEN
    ALTER TABLE transactions ADD COLUMN plaid_category_primary TEXT;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'accounts' AND column_name = 'include_in_net_worth') THEN
    ALTER TABLE accounts ADD COLUMN include_in_net_worth BOOLEAN DEFAULT true;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'accounts' AND column_name = 'custom_name') THEN
    ALTER TABLE accounts ADD COLUMN custom_name TEXT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'accounts' AND column_name = 'is_hidden') THEN
    ALTER TABLE accounts ADD COLUMN is_hidden BOOLEAN DEFAULT false;
  END IF;
END $$;

UPDATE accounts
SET classification = CASE
  WHEN LOWER(COALESCE(type, 'depository')) IN ('credit', 'loan') THEN 'liability'
  ELSE 'asset'
END;
