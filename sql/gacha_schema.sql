-- ================================================
-- CYBER RAID: Gacha Function
-- Run this in Supabase SQL Editor
-- ================================================

-- Simple server-side gacha generator used by:
-- - save_system.performGachaDraw('hero_core', count)
-- - SummonScreen (RPC: perform_gacha)
--
-- Returns a list of items with:
-- - id            : uuid
-- - item_code     : text
-- - rarity        : 'common' | 'rare' | 'legendary'
-- - attack_bonus  : integer
-- - speed_bonus   : double precision
-- - crit_bonus    : double precision

create or replace function public.perform_gacha(
  count integer,
  pool_code text
)
returns table (
  id uuid,
  item_code text,
  rarity text,
  attack_bonus integer,
  speed_bonus double precision,
  crit_bonus double precision
)
language plpgsql
as $$
declare
  i integer;
  roll numeric;
  rolled_rarity text;
  atk integer;
begin
  if count is null or count <= 0 then
    return;
  end if;

  for i in 1..count loop
    roll := random();

    if roll < 0.05 then
      rolled_rarity := 'legendary';
      atk := 50;
    elsif roll < 0.25 then
      rolled_rarity := 'rare';
      atk := 15;
    else
      rolled_rarity := 'common';
      atk := 5;
    end if;

    id := uuid_generate_v4();
    item_code := pool_code || '_' || rolled_rarity || '_' || i::text;
    rarity := rolled_rarity;
    attack_bonus := atk;
    speed_bonus := 0.0;
    crit_bonus := 0.0;

    return next;
  end loop;
end;
$$;

-- ================================================
-- DONE! Gacha RPC function ready (public.perform_gacha)
-- ================================================
