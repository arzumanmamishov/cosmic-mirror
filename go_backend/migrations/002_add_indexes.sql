-- Performance indexes for Cosmic Mirror

-- Users
CREATE INDEX idx_users_firebase_uid ON users(firebase_uid) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_email ON users(email) WHERE deleted_at IS NULL;

-- Birth Profiles
CREATE INDEX idx_birth_profiles_user_id ON birth_profiles(user_id);

-- Daily Readings
CREATE INDEX idx_daily_readings_user_date ON daily_readings(user_id, reading_date DESC);
CREATE INDEX idx_daily_readings_date ON daily_readings(reading_date);

-- Chat
CREATE INDEX idx_chat_threads_user_id ON chat_threads(user_id, updated_at DESC);
CREATE INDEX idx_chat_messages_thread_id ON chat_messages(thread_id, created_at ASC);
CREATE INDEX idx_chat_messages_created ON chat_messages(created_at) WHERE role = 'user';

-- Saved People
CREATE INDEX idx_saved_people_user_id ON saved_people(user_id);

-- Compatibility
CREATE INDEX idx_compatibility_user_person ON compatibility_reports(user_id, saved_person_id);

-- Timeline
CREATE INDEX idx_timeline_user_type ON timeline_forecasts(user_id, forecast_type);

-- Journal
CREATE INDEX idx_journal_user_date ON journal_entries(user_id, entry_date DESC);

-- Rituals
CREATE INDEX idx_ritual_completions_user ON ritual_completions(user_id, completed_date DESC);

-- Subscriptions
CREATE INDEX idx_subscriptions_status ON subscriptions(status) WHERE status IN ('active', 'trialing');
CREATE INDEX idx_subscriptions_revenuecat ON subscriptions(revenuecat_id);

-- Notification Logs
CREATE INDEX idx_notification_logs_user ON notification_logs(user_id, sent_at DESC);
