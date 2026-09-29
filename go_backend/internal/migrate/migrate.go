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

// Up applies every migration in [files] that hasn't been applied yet.
//
// Databases created before this runner existed (migrations applied by hand
// with psql) have tables but no schema_migrations: those are baselined —
// all current files are recorded as applied without re-running them.
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
		slog.Warn("migrate: existing schema without schema_migrations — baselining all current migrations as applied",
			"count", len(names))
		for _, n := range names {
			if _, err := conn.ExecContext(ctx,
				`INSERT INTO schema_migrations (version) VALUES ($1) ON CONFLICT DO NOTHING`, n); err != nil {
				return err
			}
		}
		return nil
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
