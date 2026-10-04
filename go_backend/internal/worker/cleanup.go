package worker

import (
	"context"
	"errors"
	"fmt"
	"log/slog"

	"cosmic-mirror/internal/storage"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/lib/pq"
	"github.com/redis/go-redis/v9"
)

// purgeBatchSize bounds how many soft-deleted users one run hard-deletes,
// so a backlog can't turn a run into one giant cascading transaction.
const purgeBatchSize = 500

type CleanupWorker struct {
	db      *sqlx.DB
	rdb     *redis.Client
	avatars *storage.AvatarStore
}

// NewCleanupWorker builds the worker. avatars may be nil (avatar files of
// purged users are then left on disk).
func NewCleanupWorker(db *sqlx.DB, rdb *redis.Client, avatars *storage.AvatarStore) *CleanupWorker {
	return &CleanupWorker{db: db, rdb: rdb, avatars: avatars}
}

// Run cleans up stale data. Scheduled daily. Each step is independent: a
// failing step is logged and the rest still run; the combined error is
// returned so the scheduler logs the run as failed.
func (w *CleanupWorker) Run(ctx context.Context) error {
	slog.Info("starting cleanup")

	var errs []error
	step := func(name, query string) {
		res, err := w.db.ExecContext(ctx, query)
		if err != nil {
			slog.Error("cleanup step failed", "step", name, "error", err)
			errs = append(errs, fmt.Errorf("%s: %w", name, err))
			return
		}
		if rows, _ := res.RowsAffected(); rows > 0 {
			slog.Info("cleanup step done", "step", name, "deleted", rows)
		}
	}

	// Push-delivery audit log (> 90 days).
	step("notification_logs",
		`DELETE FROM notification_logs WHERE sent_at < NOW() - INTERVAL '90 days'`)

	// In-app community activity feed (> 90 days).
	step("community_notifications",
		`DELETE FROM community_notifications WHERE created_at < NOW() - INTERVAL '90 days'`)

	// Expired subscription records (expired > 1 year).
	step("subscriptions",
		`DELETE FROM subscriptions
		 WHERE status = 'expired' AND updated_at < NOW() - INTERVAL '1 year'`)

	// OTP codes: dead once expired or consumed. Kept a day past that —
	// far longer than the 10-minute per-email rate-limit window that
	// counts recent rows.
	step("email_otps",
		`DELETE FROM email_otps
		 WHERE expires_at < NOW() - INTERVAL '1 day'
		    OR consumed_at < NOW() - INTERVAL '1 day'`)

	// Refresh tokens: expired ones are useless after a day. Revoked ones
	// are kept 30 days (≈ the refresh TTL) because rotated tokens power
	// stolen-token replay detection. rotated_to_id references another
	// token without ON DELETE, so a token is only deleted when no
	// surviving token still points at it (the rest go on a later run).
	step("refresh_tokens",
		`DELETE FROM refresh_tokens rt
		 WHERE (rt.expires_at < NOW() - INTERVAL '1 day'
		        OR rt.revoked_at < NOW() - INTERVAL '30 days')
		   AND NOT EXISTS (
		       SELECT 1 FROM refresh_tokens p
		       WHERE p.rotated_to_id = rt.id
		         AND p.expires_at >= NOW() - INTERVAL '1 day'
		         AND (p.revoked_at IS NULL OR p.revoked_at >= NOW() - INTERVAL '30 days')
		   )`)

	if err := w.purgeDeletedUsers(ctx); err != nil {
		slog.Error("cleanup step failed", "step", "purge_deleted_users", "error", err)
		errs = append(errs, fmt.Errorf("purge deleted users: %w", err))
	}

	slog.Info("cleanup complete", "failed_steps", len(errs))
	return errors.Join(errs...)
}

// purgeDeletedUsers hard-deletes users soft-deleted more than 30 days ago,
// removing their avatar files first (files before rows: if the row delete
// fails the user is retried next run; the reverse would orphan the files
// with no id left to find them by). Spaces they created survive —
// spaces.created_by is ON DELETE SET NULL since migration 013.
func (w *CleanupWorker) purgeDeletedUsers(ctx context.Context) error {
	var ids []uuid.UUID
	if err := w.db.SelectContext(ctx, &ids,
		`SELECT id FROM users
		 WHERE deleted_at IS NOT NULL AND deleted_at < NOW() - INTERVAL '30 days'
		 ORDER BY deleted_at
		 LIMIT $1`, purgeBatchSize); err != nil {
		return fmt.Errorf("list users to purge: %w", err)
	}
	if len(ids) == 0 {
		return nil
	}

	if w.avatars != nil {
		for _, id := range ids {
			if err := w.avatars.DeleteAvatar(id); err != nil {
				slog.Error("failed to delete avatar of purged user", "user_id", id, "error", err)
			}
		}
	}

	idStrings := make([]string, len(ids))
	for i, id := range ids {
		idStrings[i] = id.String()
	}
	// Re-check deleted_at so a user restored in the meantime isn't purged.
	res, err := w.db.ExecContext(ctx,
		`DELETE FROM users
		 WHERE id = ANY($1::uuid[])
		   AND deleted_at IS NOT NULL AND deleted_at < NOW() - INTERVAL '30 days'`,
		pq.Array(idStrings))
	if err != nil {
		return fmt.Errorf("delete users: %w", err)
	}
	if rows, _ := res.RowsAffected(); rows > 0 {
		slog.Info("purged deleted users", "deleted", rows)
	}
	return nil
}
