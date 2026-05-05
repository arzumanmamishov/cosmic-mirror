package postgres

import (
	"context"
	"time"

	"cosmic-mirror/internal/domain"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

// StatsRepository computes the engagement snapshot shown on the profile
// stats row. Each metric is a single round-trip to Postgres.
type StatsRepository struct {
	db *sqlx.DB
}

func NewStatsRepository(db *sqlx.DB) *StatsRepository {
	return &StatsRepository{db: db}
}

// GetStats returns total journal entries, total AI chat threads, and
// the user's current "active days" streak (consecutive UTC days ending
// today during which they wrote a journal entry, completed a ritual, or
// chatted with the AI).
func (r *StatsRepository) GetStats(ctx context.Context, userID uuid.UUID) (*domain.UserStats, error) {
	stats := &domain.UserStats{}

	if err := r.db.GetContext(ctx, &stats.JournalEntries,
		`SELECT COUNT(*) FROM journal_entries WHERE user_id = $1`, userID,
	); err != nil {
		return nil, err
	}

	if err := r.db.GetContext(ctx, &stats.AIChats,
		`SELECT COUNT(*) FROM chat_threads WHERE user_id = $1`, userID,
	); err != nil {
		return nil, err
	}

	streak, err := r.streakDays(ctx, userID)
	if err != nil {
		return nil, err
	}
	stats.Streak = streak

	return stats, nil
}

// streakDays returns the number of consecutive UTC days ending today on
// which the user had ANY activity (journal, ritual, AI chat). Returns 0
// when there's no activity today, which is the correct user-facing
// behavior — "your streak resets if you skip a day".
func (r *StatsRepository) streakDays(ctx context.Context, userID uuid.UUID) (int, error) {
	rows, err := r.db.QueryContext(ctx,
		`SELECT DISTINCT day FROM (
		   SELECT DATE(created_at AT TIME ZONE 'UTC') AS day
		     FROM journal_entries WHERE user_id = $1
		   UNION
		   SELECT DATE(completed_at AT TIME ZONE 'UTC') AS day
		     FROM ritual_completions WHERE user_id = $1
		   UNION
		   SELECT DATE(created_at AT TIME ZONE 'UTC') AS day
		     FROM chat_messages
		     WHERE thread_id IN (
		       SELECT id FROM chat_threads WHERE user_id = $1
		     )
		 ) d
		 ORDER BY day DESC`,
		userID,
	)
	if err != nil {
		return 0, err
	}
	defer rows.Close()

	today := time.Now().UTC()
	cursor := time.Date(today.Year(), today.Month(), today.Day(), 0, 0, 0, 0, time.UTC)
	streak := 0
	first := true

	for rows.Next() {
		var day time.Time
		if err := rows.Scan(&day); err != nil {
			return 0, err
		}
		day = time.Date(day.Year(), day.Month(), day.Day(), 0, 0, 0, 0, time.UTC)

		if first {
			// Streak only counts when today (or yesterday) was active —
			// users feel a streak as "I showed up today". A single
			// missed day breaks it.
			if day.Equal(cursor) {
				streak = 1
				cursor = cursor.AddDate(0, 0, -1)
				first = false
				continue
			}
			// No activity today → streak is 0.
			return 0, nil
		}

		if day.Equal(cursor) {
			streak++
			cursor = cursor.AddDate(0, 0, -1)
		} else if day.Before(cursor) {
			// Gap — streak ended.
			break
		}
		// day > cursor (impossible after the first iteration since we
		// ordered DESC) — keep scanning.
	}
	return streak, rows.Err()
}
