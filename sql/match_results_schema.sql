-- ================================================
-- CYBER TYCOON: Match Results Schema
-- Prevents save/load exploits by tracking final match results
-- ================================================

CREATE TABLE IF NOT EXISTS public.match_results (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  match_id TEXT NOT NULL,
  player_id TEXT NOT NULL REFERENCES public.players(id),
  won BOOLEAN NOT NULL,
  is_ranked BOOLEAN NOT NULL DEFAULT false,
  completed_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  final_score INTEGER NOT NULL,
  final_credits INTEGER NOT NULL,
  
  UNIQUE(match_id, player_id)
);

CREATE INDEX IF NOT EXISTS idx_match_results_player_id ON public.match_results(player_id);
CREATE INDEX IF NOT EXISTS idx_match_results_match_id ON public.match_results(match_id);
CREATE INDEX IF NOT EXISTS idx_match_results_completed_at ON public.match_results(completed_at DESC);

-- ================================================
-- DONE! Match results tracking prevents exploits
-- ================================================
