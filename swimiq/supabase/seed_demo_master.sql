-- Run in Supabase SQL Editor AFTER creating the demo auth user.
-- Dashboard → Authentication → Users → Add user:
--   Email: demo@swimiqapp.com
--   Password: SwimIQ  (change after first login)
--   User metadata: {"display_name":"SwimIQ Demo"}

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
WHERE email = 'demo@swimiqapp.com'
ON CONFLICT (user_id) DO UPDATE SET
  tier = EXCLUDED.tier,
  billing_cycle = EXCLUDED.billing_cycle,
  status = EXCLUDED.status,
  is_demo_master = EXCLUDED.is_demo_master,
  updated_at = now();
