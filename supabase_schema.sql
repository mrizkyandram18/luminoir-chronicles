-- CYBER RAID SCHEMA

-- 1. RAID ROOMS TABLE
create table if not exists public.raid_rooms (
  id text not null primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Ensure columns exist (Idempotent)
alter table public.raid_rooms add column if not exists wave int not null default 1;
alter table public.raid_rooms add column if not exists boss_hp double precision not null default 1000;

-- 2. RAID PLAYERS TABLE
create table if not exists public.raid_players (
  player_id text not null,
  room_id text not null references public.raid_rooms(id),
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  primary key (player_id, room_id)
);

-- Ensure columns exist (Idempotent)
alter table public.raid_players add column if not exists stats jsonb default '{}'::jsonb;

-- 3. ENABLE REALTIME
-- Safe addition of tables to publication
do $$
begin
  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and tablename = 'raid_rooms'
  ) then
    alter publication supabase_realtime add table public.raid_rooms;
  end if;

  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and tablename = 'raid_players'
  ) then
    alter publication supabase_realtime add table public.raid_players;
  end if;
end $$;

-- 4. DISABLE RLS (For Prototype Speed)
-- CAUTION: Enable RLS in production!
alter table public.raid_rooms enable row level security;
do $$ begin
  create policy "Public Access Rooms" on public.raid_rooms for all using (true) with check (true);
exception
  when duplicate_object then null;
end $$;

alter table public.raid_players enable row level security;
do $$ begin
  create policy "Public Access Players" on public.raid_players for all using (true) with check (true);
exception
  when duplicate_object then null;
end $$;

-- 5. PLAYERS TABLE (For SaveSystem)
-- Create table if it doesn't exist
create table if not exists public.players (
  id text not null primary key,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Ensure columns exist (Idempotent)
alter table public.players add column if not exists gold int default 0;
alter table public.players add column if not exists max_campaign_stage int default 1;
alter table public.players add column if not exists last_login timestamp with time zone;
alter table public.players add column if not exists account_power_multiplier int default 1;

-- Enable Realtime for players
do $$
begin
  if not exists (
    select 1 from pg_publication_tables 
    where pubname = 'supabase_realtime' and tablename = 'players'
  ) then
    alter publication supabase_realtime add table public.players;
  end if;
end $$;

-- Enable RLS for players
alter table public.players enable row level security;
do $$ begin
  create policy "Public Access Global Players" on public.players for all using (true) with check (true);
exception
  when duplicate_object then null;
end $$;
