-- Per-category notification toggles. The existing user_preferences row
-- already carries the master switch (notification_enabled) and the
-- preferred delivery time (notification_time); these add the per-type
-- opt-ins surfaced by the notification-preferences endpoint.
ALTER TABLE user_preferences
    ADD COLUMN IF NOT EXISTS notif_daily_reading BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS notif_affirmation   BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS notif_weekly         BOOLEAN NOT NULL DEFAULT TRUE;
