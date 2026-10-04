-- 014_revenuecat_store_subscriptions.sql
-- App Store / Google Play subscriptions bought in the mobile app arrive via
-- RevenueCat. A user has exactly one subscriptions row (user_id is UNIQUE),
-- so the store entitlement is tracked in its own rc_* columns alongside the
-- Stripe (web) columns instead of sharing status/expires_at with them:
-- premium = Stripe subscription active OR store entitlement active, and a
-- RevenueCat EXPIRATION can never downgrade a live Stripe subscription (or
-- vice versa).
--
-- revenuecat_id (from 001) holds the RevenueCat app_user_id, which the app
-- sets to our user UUID via Purchases.logIn.

ALTER TABLE subscriptions
    -- '' = never had a store subscription; otherwise active | trialing | expired.
    ADD COLUMN IF NOT EXISTS rc_status        VARCHAR(20) NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS rc_product_id    TEXT        NOT NULL DEFAULT '',
    -- app_store | play_store | … (RevenueCat's store identifier).
    ADD COLUMN IF NOT EXISTS rc_store         TEXT        NOT NULL DEFAULT '',
    -- Entitlement expiry (grace period included). NULL with an active
    -- status means a non-expiring (lifetime) entitlement.
    ADD COLUMN IF NOT EXISTS rc_expires_at    TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS rc_is_trial      BOOLEAN     NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS rc_will_renew    BOOLEAN     NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS rc_billing_issue BOOLEAN     NOT NULL DEFAULT FALSE,
    -- Point in time the rc_* snapshot describes. Writes carrying an older
    -- snapshot are ignored, so out-of-order / retried webhooks are harmless.
    ADD COLUMN IF NOT EXISTS rc_as_of         TIMESTAMPTZ,
    -- True once the user has ever had a live subscription or trial from
    -- any source. Gates the web (Stripe) free trial: one per user.
    ADD COLUMN IF NOT EXISTS trial_consumed   BOOLEAN     NOT NULL DEFAULT FALSE;

-- Rows that already show a paid/trial history can't get another trial.
UPDATE subscriptions
   SET trial_consumed = TRUE
 WHERE status IN ('active', 'trialing', 'cancelled')
    OR trial_end_at IS NOT NULL;
