-- SMTP-OTP authentication.
--
-- Adds first-party email/password + OTP auth alongside the existing Firebase
-- integration so we can migrate off Firebase Auth. New users are created via
-- the OTP verify flow; existing Firebase-linked users keep their firebase_uid
-- and can either continue using Firebase or set a password later.
--
-- Changes:
--   1. users: add password_hash, email_verified_at, last_login_at, and
--      relax the firebase_uid NOT NULL constraint (new users won't have one).
--      Case-insensitive email lookup via citext.
--   2. email_otps: 6-digit OTP codes for register/login/password_reset.
--      code is stored sha256'd so the DB row can't be replayed.
--   3. refresh_tokens: opaque server-issued refresh tokens, sha256'd on disk.

CREATE EXTENSION IF NOT EXISTS citext;

-- ---------------------------------------------------------------------------
-- users: relax firebase_uid, add local-auth columns
-- ---------------------------------------------------------------------------
ALTER TABLE users
    ALTER COLUMN firebase_uid DROP NOT NULL,
    ALTER COLUMN email TYPE CITEXT,
    ADD COLUMN IF NOT EXISTS password_hash TEXT,
    ADD COLUMN IF NOT EXISTS email_verified_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS last_login_at TIMESTAMPTZ;

-- Email must be unique for the local-auth flow to find the account.
-- Existing rows may share emails in edge cases; a partial unique index scoped
-- to non-deleted rows keeps historical data intact.
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_email_unique
    ON users (email) WHERE deleted_at IS NULL;

-- ---------------------------------------------------------------------------
-- OTP codes
-- ---------------------------------------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'otp_purpose') THEN
        CREATE TYPE otp_purpose AS ENUM (
            'register',
            'login',
            'password_reset'
        );
    END IF;
END$$;

CREATE TABLE IF NOT EXISTS email_otps (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email         CITEXT NOT NULL,
    purpose       otp_purpose NOT NULL,
    code_hash     TEXT NOT NULL,
    attempts      INT NOT NULL DEFAULT 0,
    max_attempts  INT NOT NULL DEFAULT 5,
    expires_at    TIMESTAMPTZ NOT NULL,
    consumed_at   TIMESTAMPTZ,
    requested_ip  TEXT,
    verified_ip   TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Hot lookup: the "find the newest unconsumed OTP for this (email, purpose)"
-- query the verify endpoint runs on every request.
CREATE INDEX IF NOT EXISTS idx_email_otps_active
    ON email_otps (email, purpose, created_at DESC)
    WHERE consumed_at IS NULL;

-- Purge worker index: sweep expired rows regardless of purpose.
CREATE INDEX IF NOT EXISTS idx_email_otps_expires_at
    ON email_otps (expires_at);

-- Recent-count index for the per-email rate limit.
CREATE INDEX IF NOT EXISTS idx_email_otps_email_created
    ON email_otps (email, created_at DESC);

-- ---------------------------------------------------------------------------
-- Refresh tokens
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash     TEXT NOT NULL,
    expires_at     TIMESTAMPTZ NOT NULL,
    revoked_at     TIMESTAMPTZ,
    -- rotated_to_id: when a token is exchanged for a new one, this points at
    -- the successor. A refresh call that presents an already-rotated token
    -- is a replay attempt and triggers a family-wide revocation.
    rotated_to_id  UUID REFERENCES refresh_tokens(id),
    ip             TEXT,
    user_agent     TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token_hash
    ON refresh_tokens (token_hash);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user
    ON refresh_tokens (user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires_at
    ON refresh_tokens (expires_at);
