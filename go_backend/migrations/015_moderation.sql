-- Migration 015 — User-generated-content safety (App Store 1.2 / Google
-- Play UGC policy): content reports, user blocks, auto-hide of reported
-- posts/comments, and account bans.
--
-- (014 is reserved for the in-app-purchase work.)

-- 1. Reports. One row per (reporter, target): reporting the same thing
--    twice is idempotent. target_id is polymorphic (no FK) — the target
--    may be deleted later while the report is kept for the audit trail.
CREATE TABLE IF NOT EXISTS content_reports (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reporter_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type    TEXT NOT NULL
                   CHECK (target_type IN ('post', 'comment', 'space', 'user')),
    target_id      UUID NOT NULL,
    reason         TEXT NOT NULL
                   CHECK (reason IN ('spam', 'harassment', 'hate', 'sexual',
                                     'violence', 'self_harm', 'misinformation', 'other')),
    details        TEXT CHECK (details IS NULL OR char_length(details) <= 1000),
    status         TEXT NOT NULL DEFAULT 'open'
                   CHECK (status IN ('open', 'dismissed', 'actioned')),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at    TIMESTAMPTZ,
    reviewed_note  TEXT,
    UNIQUE (reporter_id, target_type, target_id)
);

-- Moderation queue (oldest open first).
CREATE INDEX IF NOT EXISTS idx_content_reports_status_created
    ON content_reports(status, created_at);

-- Auto-hide threshold count + "resolve every report on this target".
CREATE INDEX IF NOT EXISTS idx_content_reports_target
    ON content_reports(target_type, target_id, status);

-- 2. Blocks. Symmetric in effect (neither side sees the other's content)
--    but stored one-way so only the blocker can undo it.
CREATE TABLE IF NOT EXISTS user_blocks (
    blocker_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    blocked_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (blocker_id, blocked_id),
    CHECK (blocker_id <> blocked_id)
);

-- The PK serves "did A block B" point lookups in both directions; this
-- one serves the ON DELETE CASCADE from users(blocked_id).
CREATE INDEX IF NOT EXISTS idx_user_blocks_blocked
    ON user_blocks(blocked_id);

-- 3. Hidden content. Set automatically when a post/comment collects
--    MODERATION_AUTOHIDE_THRESHOLD open reports, or by a moderator.
--    Hidden content is invisible to everyone except its author.
ALTER TABLE posts    ADD COLUMN IF NOT EXISTS hidden_at TIMESTAMPTZ;
ALTER TABLE comments ADD COLUMN IF NOT EXISTS hidden_at TIMESTAMPTZ;

-- 4. Bans. A banned account gets 403 on every authenticated request and
--    its content is filtered out of every community list.
ALTER TABLE users ADD COLUMN IF NOT EXISTS banned_at TIMESTAMPTZ;
