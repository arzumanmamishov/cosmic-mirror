package worker

import (
	"context"
	"log/slog"

	"github.com/jmoiron/sqlx"
)

type NotificationsWorker struct {
	db *sqlx.DB
}

func NewNotificationsWorker(db *sqlx.DB) *NotificationsWorker {
	return &NotificationsWorker{db: db}
}

// Run sends push notifications at each user's preferred time.
// Schedule: run every 15 minutes, find users whose notification_time
// matches current time in their timezone.
func (w *NotificationsWorker) Run(ctx context.Context) error {
	slog.Info("starting notification dispatch")

	// Query users whose preferred notification time matches NOW in their timezone
	rows, err := w.db.QueryxContext(ctx,
		`SELECT u.id, bp.timezone, up.notification_time
		 FROM users u
		 JOIN birth_profiles bp ON bp.user_id = u.id
		 JOIN user_preferences up ON up.user_id = u.id
		 WHERE u.deleted_at IS NULL
		 AND up.notification_enabled = TRUE
		 AND TO_CHAR(NOW() AT TIME ZONE bp.timezone, 'HH24:MI') = up.notification_time`)
	if err != nil {
		return err
	}
	defer rows.Close()

	var sent int
	for rows.Next() {
		var userID, timezone, notifTime string
		if err := rows.Scan(&userID, &timezone, &notifTime); err != nil {
			continue
		}

		// In production: generate personalized notification text via AI,
		// then send via Firebase Cloud Messaging
		slog.Debug("would send notification", "user_id", userID, "timezone", timezone)
		sent++
	}

	slog.Info("notification dispatch complete", "sent", sent)
	return nil
}
