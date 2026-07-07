-- Server-side subscription state (Stripe webhooks write here).
-- Users can read their own row; only service role inserts/updates.

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

CREATE POLICY "Users read own subscription"
  ON user_subscriptions
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

COMMENT ON TABLE user_subscriptions IS
  'Stripe-backed plan state. Demo master rows skip billing.';
