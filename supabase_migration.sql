-- Add gems column to players table
ALTER TABLE public.players 
ADD COLUMN IF NOT EXISTS gems INTEGER DEFAULT 0;

-- Optional: If you also want to track gems in room_players (for multiplayer)
ALTER TABLE public.room_players 
ADD COLUMN IF NOT EXISTS gems INTEGER DEFAULT 0;
