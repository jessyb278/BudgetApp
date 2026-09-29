-- access_token stays on the server and is never returned to the app.
CREATE TABLE IF NOT EXISTS plaid_connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  item_id TEXT NOT NULL,
  access_token TEXT NOT NULL,
  institution_name TEXT,
  transactions_cursor TEXT,
  last_sync TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, item_id)
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'accounts' AND column_name = 'plaid_account_id'
  ) THEN
    ALTER TABLE accounts ADD COLUMN plaid_account_id TEXT;
  END IF;
END $$;

ALTER TABLE plaid_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "plaid_connections_select_own" ON plaid_connections;
CREATE POLICY "plaid_connections_select_own" ON plaid_connections
  FOR SELECT USING (auth.uid() = user_id);
