package worker

import (
	"context"
	"log/slog"

	"github.com/jmoiron/sqlx"
	"github.com/redis/go-redis/v9"
)

type CleanupWorker struct {
	db  *sqlx.DB
	rdb *redis.Client
}

func NewCleanupWorker(db *sqlx.DB, rdb *redis.Client) *CleanupWorker {
	return &CleanupWorker{db: db, rdb: rdb}
}

// Run cleans up stale data. Schedule: daily at 3 AM.
func (w *CleanupWorker) Run(ctx context.Context) error {
	slog.Info("starting cleanup")

	// Remove old notification logs (> 90 days)
	result, err := w.db.ExecContext(ctx,
		`DELETE FROM notification_logs WHERE sent_at < NOW() - INTERVAL '90 days'`)
	if err == nil {
		if rows, _ := result.RowsAffected(); rows > 0 {
			slog.Info("cleaned notification logs", "deleted", rows)
		}
	}

	// Remove expired subscription records (expired > 1 year)
	result, err = w.db.ExecContext(ctx,
		`DELETE FROM subscriptions
		 WHERE status = 'expired' AND updated_at < NOW() - INTERVAL '1 year'`)
	if err == nil {
		if rows, _ := result.RowsAffected(); rows > 0 {
			slog.Info("cleaned expired subscriptions", "deleted", rows)
		}
	}

	// Purge soft-deleted users older than 30 days
	result, err = w.db.ExecContext(ctx,
		`DELETE FROM users WHERE deleted_at IS NOT NULL AND deleted_at < NOW() - INTERVAL '30 days'`)
	if err == nil {
		if rows, _ := result.RowsAffected(); rows > 0 {
			slog.Info("purged deleted users", "deleted", rows)
		}
	}

	slog.Info("cleanup complete")
	return nil
}
