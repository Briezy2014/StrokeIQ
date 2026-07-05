-- SwimIQ Version 4: Meets & Standards
-- Run after 001 and 002 migrations

-- Planned meets / meet calendar
create table if not exists public.planned_meets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  meet_name text not null,
  meet_date date not null,
  location text,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Heat sheet notes per planned meet + event
create table if not exists public.meet_heat_notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  planned_meet_id uuid not null references public.planned_meets(id) on delete cascade,
  event text not null,
  heat_number integer,
  lane_number integer,
  notes text,
  created_at timestamptz not null default now()
);

-- Extend usa_time_standards with season if missing
alter table public.usa_time_standards
  add column if not exists season text default '2024-2028';

create index if not exists idx_planned_meets_user_id on public.planned_meets(user_id);
create index if not exists idx_planned_meets_date on public.planned_meets(meet_date);
create index if not exists idx_meet_heat_notes_meet_id on public.meet_heat_notes(planned_meet_id);

alter table public.planned_meets enable row level security;
alter table public.meet_heat_notes enable row level security;

create policy "planned_meets_select_own" on public.planned_meets
  for select using (auth.uid() = user_id);
create policy "planned_meets_insert_own" on public.planned_meets
  for insert with check (auth.uid() = user_id);
create policy "planned_meets_update_own" on public.planned_meets
  for update using (auth.uid() = user_id);
create policy "planned_meets_delete_own" on public.planned_meets
  for delete using (auth.uid() = user_id);

create policy "meet_heat_notes_select_own" on public.meet_heat_notes
  for select using (auth.uid() = user_id);
create policy "meet_heat_notes_insert_own" on public.meet_heat_notes
  for insert with check (auth.uid() = user_id);
create policy "meet_heat_notes_update_own" on public.meet_heat_notes
  for update using (auth.uid() = user_id);
create policy "meet_heat_notes_delete_own" on public.meet_heat_notes
  for delete using (auth.uid() = user_id);

drop trigger if exists planned_meets_updated_at on public.planned_meets;
create trigger planned_meets_updated_at
  before update on public.planned_meets
  for each row execute function public.set_updated_at();
