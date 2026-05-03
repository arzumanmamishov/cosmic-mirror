-- Cosmic Mirror: Community / Spaces forum schema
-- Run: psql $DATABASE_URL -f migrations/003_community_schema.sql
--
-- Adds 8 tables: space_categories, spaces, space_members, posts, comments,
-- likes (polymorphic), hashtags + post_hashtags, community_notifications
-- (named to avoid collision with the existing notification_logs push-audit
-- table — they serve different purposes: this one is the user-visible
-- activity feed, that one is the FCM delivery log).

-- 1. Categories — seeded in 005_community_seed.sql
CREATE TABLE space_categories (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        VARCHAR(50)  UNIQUE NOT NULL,
    icon        VARCHAR(50),                  -- material icon name string
    sort_order  INTEGER NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Spaces — a discussion group / forum / community
CREATE TABLE spaces (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    handle        VARCHAR(50)  UNIQUE NOT NULL,    -- e.g. "umnofficial"; URL-safe
    name          VARCHAR(100) NOT NULL,
    description   TEXT,
    avatar_url    TEXT,
    category_id   UUID REFERENCES space_categories(id) ON DELETE SET NULL,
    created_by    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    member_count  INTEGER NOT NULL DEFAULT 0,
    is_verified   BOOLEAN NOT NULL DEFAULT FALSE,
    is_spicy      BOOLEAN NOT NULL DEFAULT FALSE,  -- "Spicy" badge
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. Membership (composite PK = unique constraint on (space_id, user_id))
CREATE TABLE space_members (
    space_id   UUID NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role       VARCHAR(20) NOT NULL DEFAULT 'member'
               CHECK (role IN ('member', 'mod', 'owner')),
    joined_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (space_id, user_id)
);

-- 4. Posts — top-level discussions inside a space
CREATE TABLE posts (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    space_id       UUID NOT NULL REFERENCES spaces(id) ON DELETE CASCADE,
    author_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content        TEXT NOT NULL,
    link_url       TEXT,
    like_count     INTEGER NOT NULL DEFAULT 0,
    comment_count  INTEGER NOT NULL DEFAULT 0,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. Comments — one level of nesting via parent_comment_id
CREATE TABLE comments (
    id                 UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id            UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    parent_comment_id  UUID REFERENCES comments(id) ON DELETE CASCADE,
    author_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content            TEXT NOT NULL,
    like_count         INTEGER NOT NULL DEFAULT 0,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. Likes — polymorphic on (target_type, target_id). Composite PK enforces
-- one-like-per-user-per-target.
CREATE TABLE likes (
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_type  VARCHAR(10) NOT NULL CHECK (target_type IN ('post', 'comment')),
    target_id    UUID NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, target_type, target_id)
);

-- 7. Hashtags — global table; use_count denormalized for popularity ranking
CREATE TABLE hashtags (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        VARCHAR(50) UNIQUE NOT NULL,    -- stored without leading #
    use_count   INTEGER NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE post_hashtags (
    post_id     UUID NOT NULL REFERENCES posts(id)   ON DELETE CASCADE,
    hashtag_id  UUID NOT NULL REFERENCES hashtags(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, hashtag_id)
);

-- 8. Community notifications — the user-visible activity feed.
-- (Distinct from notification_logs which is the FCM push-delivery audit.)
CREATE TABLE community_notifications (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipient_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    actor_id      UUID REFERENCES users(id) ON DELETE SET NULL,
    type          VARCHAR(30) NOT NULL CHECK (type IN (
                    'space_followed',
                    'space_member_joined',
                    'post_in_space',
                    'post_liked',
                    'post_commented',
                    'comment_replied',
                    'comment_liked',
                    'mentioned'
                  )),
    target_type   VARCHAR(20) NOT NULL CHECK (target_type IN ('space', 'post', 'comment')),
    target_id     UUID NOT NULL,
    snippet       TEXT,                          -- preview text (e.g. comment body)
    read_at       TIMESTAMPTZ,                   -- NULL = unread
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
