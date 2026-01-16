-- ================================================
-- MIGRATION: Fix player_color column type
-- Run this in Supabase SQL Editor
-- ================================================

-- Change player_color from INTEGER to BIGINT 
-- to support Flutter color values (up to 0xFFFFFFFF = 4,294,967,295)

ALTER TABLE room_players 
ALTER COLUMN player_color TYPE BIGINT;

-- Verify the change
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'room_players' AND column_name = 'player_color';

-- Expected output: player_color | bigint
