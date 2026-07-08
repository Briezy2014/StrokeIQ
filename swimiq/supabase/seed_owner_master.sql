-- Run in Supabase SQL Editor AFTER creating the owner auth user.
-- Dashboard -> Authentication -> Users -> Add user:
--   Email: owner@swimiqapp.com
--   Password: SwimIQ-Owner-2026
--   Auto-confirm: Yes
--   Metadata: {"display_name":"SwimIQ Owner"}

INSERT INTO user_subscriptions (
  user_id,
  tier,
  billing_cycle,
  status,
  is_demo_master
)
SELECT
  id,
  'elite',
  'monthly',
  'active',
  true
FROM auth.users
WHERE email = 'owner@swimiqapp.com'
ON CONFLICT (user_id) DO UPDATE SET
  tier = EXCLUDED.tier,
  billing_cycle = EXCLUDED.billing_cycle,
  status = EXCLUDED.status,
  is_demo_master = EXCLUDED.is_demo_master,
  updated_at = now();
