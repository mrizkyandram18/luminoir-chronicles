-- ================================================
-- CYBER RAID: Chat Schema
-- Run this in Supabase SQL Editor
-- ================================================

create table if not exists public.chat_messages (
  id uuid primary key default uuid_generate_v4(),
  channel text not null,
  sender_id text,
  target_id text,
  content text not null,
  created_at timestamptz default now()
);

create index if not exists idx_chat_channel_created_at
  on public.chat_messages(channel, created_at desc);

alter table public.chat_messages enable row level security;

do $$ begin
  create policy "Public Access Chat" on public.chat_messages
  for all
  using (true)
  with check (true);
exception
  when duplicate_object then null;
end $$;

alter publication supabase_realtime add table public.chat_messages;

-- ================================================
-- DONE! Chat messages table ready
-- ================================================

