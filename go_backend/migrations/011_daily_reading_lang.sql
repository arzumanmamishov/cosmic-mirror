-- Add per-language storage for daily readings so switching UI language
-- serves a translated reading instead of the previously-cached English
-- (or Turkish) one. Existing rows default to 'en' because that's what
-- they were generated against.
ALTER TABLE daily_readings
    ADD COLUMN lang VARCHAR(8) NOT NULL DEFAULT 'en';

ALTER TABLE daily_readings
    DROP CONSTRAINT daily_readings_user_id_reading_date_key;

ALTER TABLE daily_readings
    ADD CONSTRAINT daily_readings_user_date_lang_key
    UNIQUE (user_id, reading_date, lang);
