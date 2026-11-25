-- 016_admin_panel.sql — the web admin panel (/admin).
--
-- 1. app_settings: settings an admin can change at runtime without a
--    redeploy. One JSON document per key. Today only "stripe" (the web
--    checkout price IDs and the yearly free-trial length); an empty or
--    missing value falls back to the server's env default. Secrets (API
--    keys, webhook secrets) never live here — they stay in .env.
-- 2. admin_audit_log: who did what in the admin panel (bans, deletions,
--    settings changes, report decisions). admin_email is copied in so the
--    trail survives the admin's own account being deleted.
-- 3. Indexes for the dashboard statistics.

CREATE TABLE IF NOT EXISTS app_settings (
    key         TEXT PRIMARY KEY,
    value       JSONB NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by  UUID REFERENCES users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS admin_audit_log (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    admin_id     UUID REFERENCES users(id) ON DELETE SET NULL,
    admin_email  TEXT NOT NULL,
    action       TEXT NOT NULL,
    target_type  TEXT NOT NULL DEFAULT '',
    target_id    TEXT NOT NULL DEFAULT '',
    details      JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_audit_log_created
    ON admin_audit_log (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_target
    ON admin_audit_log (target_id, created_at DESC);

-- Sign-ups per day and the customer list (newest first).
CREATE INDEX IF NOT EXISTS idx_users_created_at
    ON users (created_at DESC);

-- Active users: every app open that refreshes the session inserts a
-- refresh_tokens row, so "users with a token created in the last N days"
-- is the active-user count.
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_created_at
    ON refresh_tokens (created_at);
