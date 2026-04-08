-- Cosmic Mirror: Initial Schema
-- Run: psql $DATABASE_URL -f migrations/001_initial_schema.sql

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users
CREATE TABLE users (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    firebase_uid VARCHAR(128) NOT NULL UNIQUE,
    email       VARCHAR(255) NOT NULL,
    name        VARCHAR(100) NOT NULL DEFAULT '',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ
);

-- Birth Profiles
CREATE TABLE birth_profiles (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    birth_date      DATE NOT NULL,
    birth_time      TIME,
    birth_time_known BOOLEAN NOT NULL DEFAULT TRUE,
    birth_place     VARCHAR(255) NOT NULL,
    latitude        DOUBLE PRECISION NOT NULL,
    longitude       DOUBLE PRECISION NOT NULL,
    timezone        VARCHAR(100) NOT NULL,
    raw_chart_data  JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- User Preferences
CREATE TABLE user_preferences (
    user_id             UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    focus_areas         TEXT[] DEFAULT '{}',
    notification_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    notification_time   VARCHAR(5) NOT NULL DEFAULT '09:00',
    theme               VARCHAR(20) NOT NULL DEFAULT 'dark'
);

-- Daily Readings
CREATE TABLE daily_readings (
    id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reading_date DATE NOT NULL,
    sun_sign     VARCHAR(20) NOT NULL DEFAULT '',
    moon_sign    VARCHAR(20) NOT NULL DEFAULT '',
    rising_sign  VARCHAR(20) NOT NULL DEFAULT '',
    energy_level INTEGER NOT NULL CHECK (energy_level BETWEEN 1 AND 10),
    emotional    TEXT NOT NULL,
    love         TEXT NOT NULL,
    career       TEXT NOT NULL,
    health       TEXT NOT NULL,
    caution      TEXT NOT NULL,
    action       TEXT NOT NULL,
    affirmation  TEXT NOT NULL,
    lucky_color  VARCHAR(50) NOT NULL,
    lucky_number INTEGER NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, reading_date)
);

-- Chat Threads
CREATE TABLE chat_threads (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title      VARCHAR(200),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Chat Messages
CREATE TABLE chat_messages (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    thread_id  UUID NOT NULL REFERENCES chat_threads(id) ON DELETE CASCADE,
    role       VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant')),
    content    TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Saved People (for compatibility)
CREATE TABLE saved_people (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,
    birth_date      DATE NOT NULL,
    birth_time      TIME,
    birth_time_known BOOLEAN NOT NULL DEFAULT TRUE,
    birth_place     VARCHAR(255) NOT NULL DEFAULT '',
    latitude        DOUBLE PRECISION NOT NULL DEFAULT 0,
    longitude       DOUBLE PRECISION NOT NULL DEFAULT 0,
    timezone        VARCHAR(100) NOT NULL DEFAULT 'UTC',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Compatibility Reports
CREATE TABLE compatibility_reports (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    saved_person_id     UUID NOT NULL REFERENCES saved_people(id) ON DELETE CASCADE,
    emotional_score     INTEGER NOT NULL CHECK (emotional_score BETWEEN 0 AND 100),
    communication_score INTEGER NOT NULL CHECK (communication_score BETWEEN 0 AND 100),
    chemistry_score     INTEGER NOT NULL CHECK (chemistry_score BETWEEN 0 AND 100),
    conflict_patterns   TEXT NOT NULL DEFAULT '',
    advice              TEXT NOT NULL DEFAULT '',
    full_report         TEXT NOT NULL DEFAULT '',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Timeline Forecasts
CREATE TABLE timeline_forecasts (
    id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    forecast_type VARCHAR(10) NOT NULL, -- '30d', '3m', '12m'
    start_date    DATE NOT NULL,
    end_date      DATE NOT NULL,
    content       JSONB NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Yearly Forecasts
CREATE TABLE yearly_forecasts (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    year       INTEGER NOT NULL,
    theme      VARCHAR(200) NOT NULL DEFAULT '',
    content    JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(user_id, year)
);

-- Journal Entries
CREATE TABLE journal_entries (
    id         UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    entry_date DATE NOT NULL,
    prompt     TEXT,
    content    TEXT NOT NULL,
    mood       VARCHAR(10),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ritual Completions
CREATE TABLE ritual_completions (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    ritual_type    VARCHAR(50) NOT NULL,
    completed_date DATE NOT NULL,
    streak_count   INTEGER NOT NULL DEFAULT 1,
    UNIQUE(user_id, ritual_type, completed_date)
);

-- Subscriptions
CREATE TABLE subscriptions (
    id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id        UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    revenuecat_id  VARCHAR(255) NOT NULL DEFAULT '',
    plan_type      VARCHAR(20) NOT NULL DEFAULT 'monthly',
    status         VARCHAR(20) NOT NULL DEFAULT 'expired',
    expires_at     TIMESTAMPTZ,
    trial_end_at   TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Notification Logs
CREATE TABLE notification_logs (
    id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type      VARCHAR(50) NOT NULL,
    title     VARCHAR(200) NOT NULL DEFAULT '',
    body      TEXT NOT NULL DEFAULT '',
    sent_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    opened_at TIMESTAMPTZ
);

-- Feature Flags
CREATE TABLE feature_flags (
    key         VARCHAR(100) PRIMARY KEY,
    value       JSONB NOT NULL DEFAULT 'true',
    description TEXT NOT NULL DEFAULT '',
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
