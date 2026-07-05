-- SwimIQ Version 3: Coach & Team
-- Run after 001_swimiq_v1.sql

-- User roles (coach or swimmer)
create table if not exists public.user_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'swimmer' check (role in ('swimmer', 'coach')),
  display_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id)
);

-- Teams owned by coaches
create table if not exists public.teams (
  id uuid primary key default gen_random_uuid(),
  coach_user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  club_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- Roster: invite swimmers by email; link on signup
create table if not exists public.team_members (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  swimmer_user_id uuid references auth.users(id) on delete set null,
  invite_email text not null,
  display_name text,
  status text not null default 'pending' check (status in ('pending', 'active')),
  joined_at timestamptz,
  created_at timestamptz not null default now(),
  unique (team_id, invite_email)
);

-- In-app notifications (PB alerts, goal deadlines)
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null check (type in ('personal_best', 'goal_deadline', 'team_invite')),
  title text not null,
  body text not null,
  read boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_user_profiles_user_id on public.user_profiles(user_id);
create index if not exists idx_teams_coach_user_id on public.teams(coach_user_id);
create index if not exists idx_team_members_team_id on public.team_members(team_id);
create index if not exists idx_team_members_swimmer_user_id on public.team_members(swimmer_user_id);
create index if not exists idx_team_members_invite_email on public.team_members(invite_email);
create index if not exists idx_notifications_user_id on public.notifications(user_id);

alter table public.user_profiles enable row level security;
alter table public.teams enable row level security;
alter table public.team_members enable row level security;
alter table public.notifications enable row level security;

-- Helper: coach owns team
create or replace function public.is_team_coach(team_uuid uuid)
returns boolean as $$
  select exists (
    select 1 from public.teams
    where id = team_uuid and coach_user_id = auth.uid()
  );
$$ language sql security definer stable;

-- Helper: user is active member of coach's team
create or replace function public.is_coach_of_swimmer(swimmer_uuid uuid)
returns boolean as $$
  select exists (
    select 1
    from public.team_members tm
    join public.teams t on t.id = tm.team_id
    where tm.swimmer_user_id = swimmer_uuid
      and tm.status = 'active'
      and t.coach_user_id = auth.uid()
  );
$$ language sql security definer stable;

-- user_profiles policies
create policy "user_profiles_select_own" on public.user_profiles
  for select using (auth.uid() = user_id);
create policy "user_profiles_insert_own" on public.user_profiles
  for insert with check (auth.uid() = user_id);
create policy "user_profiles_update_own" on public.user_profiles
  for update using (auth.uid() = user_id);

-- teams policies
create policy "teams_select_own" on public.teams
  for select using (auth.uid() = coach_user_id);
create policy "teams_insert_own" on public.teams
  for insert with check (auth.uid() = coach_user_id);
create policy "teams_update_own" on public.teams
  for update using (auth.uid() = coach_user_id);
create policy "teams_delete_own" on public.teams
  for delete using (auth.uid() = coach_user_id);

-- team_members policies
create policy "team_members_select_coach" on public.team_members
  for select using (public.is_team_coach(team_id));
create policy "team_members_select_self" on public.team_members
  for select using (
    lower(invite_email) = lower(coalesce(auth.jwt() ->> 'email', ''))
    or swimmer_user_id = auth.uid()
  );
create policy "team_members_insert_coach" on public.team_members
  for insert with check (public.is_team_coach(team_id));
create policy "team_members_update_coach" on public.team_members
  for update using (public.is_team_coach(team_id));
create policy "team_members_update_self" on public.team_members
  for update using (
    lower(invite_email) = lower(coalesce(auth.jwt() ->> 'email', ''))
    or swimmer_user_id = auth.uid()
  );
create policy "team_members_delete_coach" on public.team_members
  for delete using (public.is_team_coach(team_id));

-- notifications policies
create policy "notifications_select_own" on public.notifications
  for select using (auth.uid() = user_id);
create policy "notifications_insert_own" on public.notifications
  for insert with check (auth.uid() = user_id);
create policy "notifications_update_own" on public.notifications
  for update using (auth.uid() = user_id);
create policy "notifications_delete_own" on public.notifications
  for delete using (auth.uid() = user_id);

-- Coach read access to roster swimmer data
create policy "swimmers_select_coach" on public.swimmers
  for select using (public.is_coach_of_swimmer(user_id));

create policy "race_logs_select_coach" on public.race_logs
  for select using (public.is_coach_of_swimmer(user_id));

create policy "goals_select_coach" on public.goals
  for select using (public.is_coach_of_swimmer(user_id));

create policy "meet_results_select_coach" on public.meet_results
  for select using (public.is_coach_of_swimmer(user_id));

create policy "meet_results_insert_coach" on public.meet_results
  for insert with check (public.is_coach_of_swimmer(user_id));

-- updated_at triggers
drop trigger if exists user_profiles_updated_at on public.user_profiles;
create trigger user_profiles_updated_at
  before update on public.user_profiles
  for each row execute function public.set_updated_at();

drop trigger if exists teams_updated_at on public.teams;
create trigger teams_updated_at
  before update on public.teams
  for each row execute function public.set_updated_at();
