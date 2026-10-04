// Package migrate applies the embedded SQL migrations in filename order,
// recording each in schema_migrations so every file runs exactly once.
package migrate

import (
	"context"
	"fmt"
	"io/fs"
	"log/slog"
	"sort"
	"strings"

	"github.com/jmoiron/sqlx"
)

// lockKey is an arbitrary constant for pg_advisory_lock, so two instances
// starting at once can't apply the same migration concurrently.
const lockKey = 7240531

// legacyProbes lists every migration that existed before this runner was
// introduced (001–011), each with a query that is true when that
// migration's schema change is already present. A hand-migrated database
// may be at any of these versions, so baselining checks each one rather
// than assuming "users exists ⇒ everything is applied" (which would mark
// e.g. 011 applied on a DB that never ran it, and the code would then hit
// a missing column at runtime). Files added after the runner existed are
// never baselined — they always run.
var legacyProbes = []struct{ version, probe string }{
	{"001_initial_schema.sql", `SELECT to_regclass('public.users') IS NOT NULL`},
	{"002_add_indexes.sql", `SELECT to_regclass('public.idx_users_firebase_uid') IS NOT NULL`},
	{"003_community_schema.sql", `SELECT to_regclass('public.spaces') IS NOT NULL`},
	{"004_community_indexes.sql", `SELECT to_regclass('public.idx_spaces_member_count') IS NOT NULL`},
	{"005_community_seed.sql", `SELECT EXISTS (SELECT 1 FROM space_categories)`},
	{"006_user_avatar.sql", columnProbe("users", "avatar_url")},
	{"007_stripe_subscription.sql", columnProbe("subscriptions", "stripe_customer_id")},
	{"008_space_join_approval.sql", columnProbe("space_members", "status")},
	{"009_notification_prefs.sql", columnProbe("user_preferences", "notif_daily_reading")},
	{"010_smtp_otp_auth.sql", `SELECT to_regclass('public.email_otps') IS NOT NULL`},
	{"011_daily_reading_lang.sql", columnProbe("daily_readings", "lang")},
}

func columnProbe(table, column string) string {
	return fmt.Sprintf(`SELECT EXISTS (SELECT 1 FROM information_schema.columns
		WHERE table_schema = 'public' AND table_name = '%s' AND column_name = '%s')`, table, column)
}

// Up applies every migration in [files] that hasn't been applied yet.
//
// Databases created before this runner existed (migrations applied by hand
// with psql) have tables but no schema_migrations: those are baselined —
// the leading run of pre-runner migrations whose schema changes are
// detectably present (see legacyProbes) is recorded as applied, and
// everything after the first missing one runs normally.
func Up(ctx context.Context, db *sqlx.DB, files fs.FS) error {
	conn, err := db.Connx(ctx)
	if err != nil {
		return err
	}
	defer conn.Close()

	if _, err := conn.ExecContext(ctx, `SELECT pg_advisory_lock($1)`, lockKey); err != nil {
		return fmt.Errorf("migrate: lock: %w", err)
	}
	defer conn.ExecContext(context.Background(), `SELECT pg_advisory_unlock($1)`, lockKey) //nolint:errcheck

	var tracked bool
	if err := conn.QueryRowxContext(ctx,
		`SELECT to_regclass('public.schema_migrations') IS NOT NULL`).Scan(&tracked); err != nil {
		return err
	}
	var legacy bool
	if err := conn.QueryRowxContext(ctx,
		`SELECT to_regclass('public.users') IS NOT NULL`).Scan(&legacy); err != nil {
		return err
	}
	if _, err := conn.ExecContext(ctx, `CREATE TABLE IF NOT EXISTS schema_migrations (
		version    TEXT PRIMARY KEY,
		applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
	)`); err != nil {
		return fmt.Errorf("migrate: create table: %w", err)
	}

	names, err := fs.Glob(files, "*.sql")
	if err != nil {
		return err
	}
	sort.Strings(names)

	if !tracked && legacy {
		baselined := 0
		for _, lp := range legacyProbes {
			var present bool
			if err := conn.QueryRowxContext(ctx, lp.probe).Scan(&present); err != nil {
				return fmt.Errorf("migrate: baseline probe %s: %w", lp.version, err)
			}
			if !present {
				break
			}
			if _, err := conn.ExecContext(ctx,
				`INSERT INTO schema_migrations (version) VALUES ($1) ON CONFLICT DO NOTHING`, lp.version); err != nil {
				return err
			}
			baselined++
		}
		slog.Warn("migrate: existing schema without schema_migrations — baselined pre-runner migrations already present; applying the rest",
			"baselined", baselined, "total", len(names))
		// Fall through: anything not baselined runs below.
	}

	applied := map[string]bool{}
	rows, err := conn.QueryxContext(ctx, `SELECT version FROM schema_migrations`)
	if err != nil {
		return err
	}
	for rows.Next() {
		var v string
		if err := rows.Scan(&v); err != nil {
			rows.Close()
			return err
		}
		applied[v] = true
	}
	rows.Close()

	for _, n := range names {
		if applied[n] {
			continue
		}
		body, err := fs.ReadFile(files, n)
		if err != nil {
			return err
		}
		if strings.TrimSpace(string(body)) == "" {
			continue
		}
		tx, err := conn.BeginTxx(ctx, nil)
		if err != nil {
			return err
		}
		if _, err := tx.ExecContext(ctx, string(body)); err != nil {
			_ = tx.Rollback()
			return fmt.Errorf("migrate: %s: %w", n, err)
		}
		if _, err := tx.ExecContext(ctx,
			`INSERT INTO schema_migrations (version) VALUES ($1)`, n); err != nil {
			_ = tx.Rollback()
			return err
		}
		if err := tx.Commit(); err != nil {
			return err
		}
		slog.Info("migrate: applied", "version", n)
	}
	return nil
}
