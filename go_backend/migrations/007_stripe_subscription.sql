-- 007_stripe_subscription.sql
-- Adds Stripe identifiers + price metadata to the existing subscriptions table.
-- We keep the legacy revenuecat_id column so older rows keep working; new
-- subscriptions populate stripe_customer_id + stripe_subscription_id and
-- read those instead.
--
-- price_id is the Stripe Price ID the subscription was created against
-- (recorded so we can tell monthly from yearly without re-hitting Stripe).
-- current_period_end mirrors Stripe's source-of-truth expiry so the app
-- can render the renewal date without a network round-trip.

ALTER TABLE subscriptions
    ADD COLUMN IF NOT EXISTS stripe_customer_id     TEXT,
    ADD COLUMN IF NOT EXISTS stripe_subscription_id TEXT,
    ADD COLUMN IF NOT EXISTS price_id               TEXT,
    ADD COLUMN IF NOT EXISTS current_period_end     TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS cancel_at_period_end   BOOLEAN NOT NULL DEFAULT FALSE;

-- Stripe webhooks arrive keyed on the subscription id; we look up by it
-- to apply status/period updates. Unique because a Stripe sub maps to
-- exactly one of our subscription rows.
CREATE UNIQUE INDEX IF NOT EXISTS idx_subscriptions_stripe_subscription_id
    ON subscriptions (stripe_subscription_id)
    WHERE stripe_subscription_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_subscriptions_stripe_customer_id
    ON subscriptions (stripe_customer_id)
    WHERE stripe_customer_id IS NOT NULL;
