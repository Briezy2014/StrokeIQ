-- Run in Supabase SQL Editor AFTER creating the owner auth user.
--
-- OPTION A — Dashboard (easiest):
--   Authentication -> Users -> Add user -> Create new user
--   Email: owner@swimiqapp.com
--   Password: SwimIQ-Owner-2026
--   Auto Confirm User: ON
--   User Metadata: {"display_name":"SwimIQ Owner"}
--
-- OPTION B — Supabase CLI (if linked to your project):
--   supabase auth admin create-user --email owner@swimiqapp.com --password SwimIQ-Owner-2026 --email-confirm
--
-- VERIFY on Windows: double-click TEST-OWNER-LOGIN.bat (must say SUCCESS)
--
-- If login still fails: delete the user in Dashboard and recreate with exact password above.

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
