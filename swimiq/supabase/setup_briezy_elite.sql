-- Run this ENTIRE script once in Supabase SQL Editor.
-- Creates user_subscriptions (if missing) and grants Briezy full Elite access.

CREATE TABLE IF NOT EXISTS user_subscriptions (
  user_id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  stripe_customer_id text,
  stripe_subscription_id text,
  tier text NOT NULL DEFAULT 'basic',
  billing_cycle text NOT NULL DEFAULT 'monthly',
  status text NOT NULL DEFAULT 'inactive',
  is_demo_master boolean NOT NULL DEFAULT false,
  current_period_end timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS user_subscriptions_stripe_customer_idx
  ON user_subscriptions (stripe_customer_id);

ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users read own subscription" ON user_subscriptions;

CREATE POLICY "Users read own subscription"
  ON user_subscriptions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

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
