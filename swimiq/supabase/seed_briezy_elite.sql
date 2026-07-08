-- Grant Briezy / founder full Elite access (run once in Supabase SQL Editor).
-- If you get "relation user_subscriptions does not exist", run setup_briezy_elite.sql instead.
-- Dashboard -> Authentication -> Users: confirm briezy682014@gmail.com exists.

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
WHERE email = 'briezy682014@gmail.com'
ON CONFLICT (user_id) DO UPDATE SET
  tier = 'elite',
  billing_cycle = 'monthly',
  status = 'active',
  is_demo_master = true,
  updated_at = now();
