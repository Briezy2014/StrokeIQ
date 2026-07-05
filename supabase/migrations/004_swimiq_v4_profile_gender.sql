-- SwimIQ V4: gender on swimmer profile for motivational standards matching
alter table public.swimmers
  add column if not exists gender text;
