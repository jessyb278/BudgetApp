-- Plaid Integration: plaid_connections + schema updates
-- Run this in Supabase SQL Editor (Dashboard > SQL Editor) before deploying Edge Functions

-- 1. Create plaid_connections table (stores access_token - NEVER exposed to frontend)
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

-- 2. Add plaid_account_id to accounts (links to Plaid account_id for deduplication)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'accounts' AND column_name = 'plaid_account_id'
  ) THEN
    ALTER TABLE accounts ADD COLUMN plaid_account_id TEXT;
  END IF;
END $$;

-- 3. Row Level Security (RLS)
ALTER TABLE plaid_connections ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- plaid_connections: users can only see their own rows
DROP POLICY IF EXISTS "plaid_connections_select_own" ON plaid_connections;
CREATE POLICY "plaid_connections_select_own" ON plaid_connections
  FOR SELECT USING (auth.uid() = user_id);

-- Edge Function uses service_role key, so it bypasses RLS for inserts/updates
