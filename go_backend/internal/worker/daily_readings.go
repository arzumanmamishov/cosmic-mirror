package worker

import (
	"context"
	"log/slog"
	"time"

	"cosmic-mirror/internal/service"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type DailyReadingsWorker struct {
	db         *sqlx.DB
	readingSvc *service.ReadingService
}

func NewDailyReadingsWorker(db *sqlx.DB, readingSvc *service.ReadingService) *DailyReadingsWorker {
	return &DailyReadingsWorker{db: db, readingSvc: readingSvc}
}

// Run generates daily readings for all active users.
// Schedule: run at 2 AM in each timezone batch.
func (w *DailyReadingsWorker) Run(ctx context.Context) error {
	slog.Info("starting daily readings generation")
	today := time.Now().Truncate(24 * time.Hour)

	// Get all active users with birth profiles who don't have today's reading
	rows, err := w.db.QueryxContext(ctx,
		`SELECT u.id FROM users u
		 JOIN birth_profiles bp ON bp.user_id = u.id
		 LEFT JOIN daily_readings dr ON dr.user_id = u.id AND dr.reading_date = $1
		 WHERE u.deleted_at IS NULL AND dr.id IS NULL
		 LIMIT 1000`, today.Format("2006-01-02"))
	if err != nil {
		return err
	}
	defer rows.Close()

	var generated, failed int
	for rows.Next() {
		var userID uuid.UUID
		if err := rows.Scan(&userID); err != nil {
			continue
		}

		if _, err := w.readingSvc.GetDailyReading(ctx, userID, today); err != nil {
			slog.Error("failed to generate reading", "user_id", userID, "error", err)
			failed++
		} else {
			generated++
		}

		// Rate limit: don't overwhelm the AI provider
		time.Sleep(200 * time.Millisecond)
	}

	slog.Info("daily readings generation complete", "generated", generated, "failed", failed)
	return nil
}
