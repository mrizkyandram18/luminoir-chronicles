-- Add gems column to players table
ALTER TABLE public.players 
ADD COLUMN IF NOT EXISTS gems INTEGER DEFAULT 0;

-- Optional: If you also want to track gems in room_players (for multiplayer)
ALTER TABLE public.room_players 
ADD COLUMN IF NOT EXISTS gems INTEGER DEFAULT 0;

-- Add node_id column to players table (for Graph Board)
ALTER TABLE public.players 
ADD COLUMN IF NOT EXISTS node_id TEXT DEFAULT 'node_0';

-- Optional: Track node_id in room_players
ALTER TABLE public.room_players 
ADD COLUMN IF NOT EXISTS node_id TEXT DEFAULT 'node_0';
