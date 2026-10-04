-- spaces.created_by was `NOT NULL REFERENCES users(id) ON DELETE CASCADE`
-- (migration 003). The cleanup worker hard-deletes users 30 days after
-- account deletion, and that cascade wiped every space the user had
-- created — including all posts/comments/memberships of everyone else in
-- those communities. Spaces now survive their creator: created_by becomes
-- NULL (an ownerless space; owner-only actions are simply unavailable).
ALTER TABLE spaces ALTER COLUMN created_by DROP NOT NULL;

-- Drop whatever FK currently covers spaces.created_by (Postgres' default
-- name is spaces_created_by_fkey, but don't depend on it) and re-add it
-- with ON DELETE SET NULL.
DO $$
DECLARE
    con TEXT;
BEGIN
    FOR con IN
        SELECT c.conname
        FROM pg_constraint c
        JOIN pg_attribute a
          ON a.attrelid = c.conrelid AND a.attnum = ANY (c.conkey)
        WHERE c.conrelid = 'spaces'::regclass
          AND c.contype = 'f'
          AND a.attname = 'created_by'
    LOOP
        EXECUTE format('ALTER TABLE spaces DROP CONSTRAINT %I', con);
    END LOOP;
END$$;

ALTER TABLE spaces
    ADD CONSTRAINT spaces_created_by_fkey
    FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL;
