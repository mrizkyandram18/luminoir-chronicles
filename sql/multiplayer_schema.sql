-- ================================================
-- CYBER TYCOON: Multiplayer Database Schema
-- Run this in Supabase SQL Editor
-- ================================================

-- 1. Create game_rooms table
CREATE TABLE IF NOT EXISTS game_rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_code TEXT UNIQUE NOT NULL,
  host_child_id TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'waiting', -- 'waiting', 'playing', 'finished'
  max_players INTEGER NOT NULL DEFAULT 4,
  current_turn_child_id TEXT,
  board_state JSONB, -- Store entire board state as JSON
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  winner_child_id TEXT,
  
  CONSTRAINT valid_status CHECK (status IN ('waiting', 'playing', 'finished')),
  CONSTRAINT valid_max_players CHECK (max_players >= 2 AND max_players <= 4)
);

-- 2. Create room_players table
CREATE TABLE IF NOT EXISTS room_players (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID REFERENCES game_rooms(id) ON DELETE CASCADE,
  child_id TEXT NOT NULL,
  player_name TEXT NOT NULL,
  player_color INTEGER NOT NULL, -- ARGB color value (e.g., 0xFF2196F3)
  position INTEGER DEFAULT 0,
  score INTEGER DEFAULT 0,
  credits INTEGER DEFAULT 500,
  score_multiplier INTEGER DEFAULT 1,
  is_connected BOOLEAN DEFAULT true,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_action_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  UNIQUE(room_id, child_id) -- Prevent duplicate joins
);

-- 3. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_room_code ON game_rooms(room_code);
CREATE INDEX IF NOT EXISTS idx_room_status ON game_rooms(status);
CREATE INDEX IF NOT EXISTS idx_room_players_room_id ON room_players(room_id);
CREATE INDEX IF NOT EXISTS idx_room_players_child_id ON room_players(child_id);

-- 4. Enable Realtime for both tables
ALTER PUBLICATION supabase_realtime ADD TABLE game_rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE room_players;

-- 5. Disable RLS for development (enable & add policies for production)
ALTER TABLE game_rooms DISABLE ROW LEVEL SECURITY;
ALTER TABLE room_players DISABLE ROW LEVEL SECURITY;

-- 6. Function to generate 6-digit room code
CREATE OR REPLACE FUNCTION generate_room_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Exclude ambiguous: 0,O,1,I
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..6 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- 7. Function to auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = NOW();
   RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_game_rooms_updated_at
BEFORE UPDATE ON game_rooms
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 8. Verify tables created
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('game_rooms', 'room_players')
ORDER BY table_name, ordinal_position;

-- ================================================
-- DONE! You can now use these tables for multiplayer
-- ================================================
