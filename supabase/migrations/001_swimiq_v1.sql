-- SwimIQ Version 1 schema
-- Run in Supabase SQL Editor or via supabase db push

-- Swimmer profiles (one per auth user in V1)
create table if not exists public.swimmers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  swimmer_name text not null,
  first_name text,
  last_name text,
  preferred_name text,
  birthday date,
  graduation_year integer,
  team text,
  coach_name text,
  primary_stroke text,
  secondary_stroke text,
  favorite_event text,
  usa_swimming_id text,
  school text,
  athlete_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id)
);

-- Training / race sessions
create table if not exists public.race_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  swimmer text not null,
  event text,
  stroke text not null,
  distance integer not null,
  course text not null default 'SCY',
  time_seconds numeric not null,
  notes text,
  date date not null default current_date,
  created_at timestamptz not null default now()
);

-- Goals
create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  swimmer_name text not null,
  event text not null,
  current_time numeric,
  goal_time numeric not null,
  course text not null default 'SCY',
  target_date date,
  created_at timestamptz not null default now()
);

-- Meet results
create table if not exists public.meet_results (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  swimmer_name text not null,
  meet_name text not null,
  meet_date date not null,
  event text not null,
  swim_time numeric not null,
  course text not null default 'SCY',
  created_at timestamptz not null default now()
);

-- Indexes
create index if not exists idx_race_logs_user_id on public.race_logs(user_id);
create index if not exists idx_race_logs_date on public.race_logs(date desc);
create index if not exists idx_goals_user_id on public.goals(user_id);
create index if not exists idx_meet_results_user_id on public.meet_results(user_id);
create index if not exists idx_swimmers_user_id on public.swimmers(user_id);

-- Row Level Security
alter table public.swimmers enable row level security;
alter table public.race_logs enable row level security;
alter table public.goals enable row level security;
alter table public.meet_results enable row level security;

create policy "swimmers_select_own" on public.swimmers
  for select using (auth.uid() = user_id);
create policy "swimmers_insert_own" on public.swimmers
  for insert with check (auth.uid() = user_id);
create policy "swimmers_update_own" on public.swimmers
  for update using (auth.uid() = user_id);
create policy "swimmers_delete_own" on public.swimmers
  for delete using (auth.uid() = user_id);

create policy "race_logs_select_own" on public.race_logs
  for select using (auth.uid() = user_id);
create policy "race_logs_insert_own" on public.race_logs
  for insert with check (auth.uid() = user_id);
create policy "race_logs_update_own" on public.race_logs
  for update using (auth.uid() = user_id);
create policy "race_logs_delete_own" on public.race_logs
  for delete using (auth.uid() = user_id);

create policy "goals_select_own" on public.goals
  for select using (auth.uid() = user_id);
create policy "goals_insert_own" on public.goals
  for insert with check (auth.uid() = user_id);
create policy "goals_update_own" on public.goals
  for update using (auth.uid() = user_id);
create policy "goals_delete_own" on public.goals
  for delete using (auth.uid() = user_id);

create policy "meet_results_select_own" on public.meet_results
  for select using (auth.uid() = user_id);
create policy "meet_results_insert_own" on public.meet_results
  for insert with check (auth.uid() = user_id);
create policy "meet_results_update_own" on public.meet_results
  for update using (auth.uid() = user_id);
create policy "meet_results_delete_own" on public.meet_results
  for delete using (auth.uid() = user_id);

-- Updated_at trigger for swimmers
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists swimmers_updated_at on public.swimmers;
create trigger swimmers_updated_at
  before update on public.swimmers
  for each row execute function public.set_updated_at();
