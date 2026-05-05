-- 006_user_avatar.sql
-- Adds an avatar_url column on users for the profile-photo upload feature.
-- The column stores the public URL the backend serves the saved image at,
-- e.g. /uploads/avatars/{userId}_{timestamp}.jpg. Always nullable — most
-- users won't set a custom avatar initially.

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS avatar_url TEXT;
