-- ================================================
-- CYBER TYCOON: Game Identities Schema
-- Run this in Supabase SQL Editor to fix 'table not found' error
-- ================================================

CREATE TABLE IF NOT EXISTS public.game_identities (
  child_id TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Disable RLS for development (consistent with other tables)
ALTER TABLE public.game_identities DISABLE ROW LEVEL SECURITY;

-- Optional: Add realtime
ALTER PUBLICATION supabase_realtime ADD TABLE game_identities;
