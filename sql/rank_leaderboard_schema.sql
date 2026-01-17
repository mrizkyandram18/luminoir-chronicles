-- ================================================
-- CYBER TYCOON: Rank & Leaderboard Schema
-- Run this in Supabase SQL Editor
-- ================================================

-- 1. Ensure players table has rank columns
ALTER TABLE public.players 
ADD COLUMN IF NOT EXISTS rank_points INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS wins INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS losses INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS rank_tier TEXT DEFAULT 'bronze';

-- 2. Create leaderboard view (top 100 players)
CREATE OR REPLACE VIEW public.leaderboard AS
SELECT 
  id,
  name,
  rank_points,
  wins,
  losses,
  rank_tier,
  ROW_NUMBER() OVER (ORDER BY rank_points DESC, wins DESC) as rank_position
FROM public.players
WHERE is_human = true
ORDER BY rank_points DESC, wins DESC
LIMIT 100;

-- 3. Create index for leaderboard queries
CREATE INDEX IF NOT EXISTS idx_players_rank_points ON public.players(rank_points DESC);
CREATE INDEX IF NOT EXISTS idx_players_rank_tier ON public.players(rank_tier);

-- 4. Function to update rank tier based on points
CREATE OR REPLACE FUNCTION update_rank_tier()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.rank_points >= 3000 THEN
    NEW.rank_tier := 'cyberElite';
  ELSIF NEW.rank_points >= 1500 THEN
    NEW.rank_tier := 'gold';
  ELSIF NEW.rank_points >= 500 THEN
    NEW.rank_tier := 'silver';
  ELSE
    NEW.rank_tier := 'bronze';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Trigger to auto-update rank tier
DROP TRIGGER IF EXISTS trigger_update_rank_tier ON public.players;
CREATE TRIGGER trigger_update_rank_tier
BEFORE INSERT OR UPDATE OF rank_points ON public.players
FOR EACH ROW
EXECUTE FUNCTION update_rank_tier();

-- 6. Enable Realtime for leaderboard view (via players table)
ALTER PUBLICATION supabase_realtime ADD TABLE public.players;

-- ================================================
-- DONE! Rank and leaderboard system ready
-- ================================================
