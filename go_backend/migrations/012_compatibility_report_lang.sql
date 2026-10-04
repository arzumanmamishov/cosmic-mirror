-- Per-language compatibility reports. GenerateReport reuses a report
-- generated within the last hour instead of paying for another LLM call;
-- without a language column a Turkish request could be served the English
-- report generated a few minutes earlier (and vice versa). Existing rows
-- default to 'en' because that's what nearly all of them were generated in.
ALTER TABLE compatibility_reports
    ADD COLUMN IF NOT EXISTS lang VARCHAR(8) NOT NULL DEFAULT 'en';

-- Hot path: "latest report for (user, person)" and the free-tier daily
-- generation count both filter on user_id and order/filter by created_at.
CREATE INDEX IF NOT EXISTS idx_compatibility_user_person_created
    ON compatibility_reports (user_id, saved_person_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_compatibility_user_created
    ON compatibility_reports (user_id, created_at DESC);
