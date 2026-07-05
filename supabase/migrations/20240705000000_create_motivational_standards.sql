-- USA Swimming Age Group Motivational Standards (2024-2028 quad)
-- Official reference data — populate via scripts/import_motivational_standards.py

create table if not exists public.motivational_standards (
  id uuid primary key default gen_random_uuid(),
  age_group text not null,
  gender text not null,
  course text not null check (course in ('SCY', 'SCM', 'LCM')),
  event text not null,
  b_time numeric not null,
  bb_time numeric not null,
  a_time numeric not null,
  aa_time numeric not null,
  aaa_time numeric not null,
  aaaa_time numeric not null,
  version text not null default '2024-2028 USA Swimming Motivational Standards',
  created_at timestamptz not null default now(),
  unique (version, age_group, gender, course, event)
);

create index if not exists idx_motivational_standards_lookup
  on public.motivational_standards (version, age_group, gender, course);

create index if not exists idx_motivational_standards_event
  on public.motivational_standards (version, event);

comment on table public.motivational_standards is
  'USA Swimming Age Group Motivational Standards — official reference dataset.';

alter table public.motivational_standards enable row level security;

create policy "Motivational standards are readable by authenticated users"
  on public.motivational_standards
  for select
  to authenticated
  using (true);

create policy "Motivational standards are readable by anon for public reference"
  on public.motivational_standards
  for select
  to anon
  using (true);
