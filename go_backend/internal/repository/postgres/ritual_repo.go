package postgres

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"cosmic-mirror/internal/domain"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type RitualRepository struct {
	db *sqlx.DB
}

func NewRitualRepository(db *sqlx.DB) *RitualRepository {
	return &RitualRepository{db: db}
}

// Complete records that the user finished a ritual today and computes the
// streak: if they completed the same ritual yesterday, the streak continues;
// otherwise it resets to 1. Re-completing the same ritual on the same day is
// idempotent (keeps the computed streak) thanks to the unique constraint.
func (r *RitualRepository) Complete(ctx context.Context, c *domain.RitualCompletion) error {
	var prev int
	err := r.db.QueryRowxContext(ctx,
		`SELECT streak_count FROM ritual_completions
		 WHERE user_id = $1 AND ritual_type = $2
		   AND completed_date = CURRENT_DATE - INTERVAL '1 day'`,
		c.UserID, c.RitualType,
	).Scan(&prev)
	switch {
	case err == nil:
		c.StreakCount = prev + 1
	case errors.Is(err, sql.ErrNoRows):
		c.StreakCount = 1
	default:
		return err
	}

	if c.ID == uuid.Nil {
		c.ID = uuid.New()
	}
	c.CompletedDate = time.Now()
	_, err = r.db.ExecContext(ctx,
		`INSERT INTO ritual_completions (id, user_id, ritual_type, completed_date, streak_count)
		 VALUES ($1, $2, $3, CURRENT_DATE, $4)
		 ON CONFLICT (user_id, ritual_type, completed_date)
		 DO UPDATE SET streak_count = EXCLUDED.streak_count`,
		c.ID, c.UserID, c.RitualType, c.StreakCount,
	)
	return err
}

func (r *RitualRepository) GetTodayCompletions(ctx context.Context, userID uuid.UUID) ([]domain.RitualCompletion, error) {
	var out []domain.RitualCompletion
	err := r.db.SelectContext(ctx, &out,
		`SELECT id, user_id, ritual_type, completed_date, streak_count
		 FROM ritual_completions
		 WHERE user_id = $1 AND completed_date = CURRENT_DATE
		 ORDER BY ritual_type`,
		userID,
	)
	return out, err
}

// GetStreak returns the user's best current ritual streak — the max streak
// among completions in the last two days (so a streak earned yesterday still
// shows until it actually lapses). Returns 0 once the streak is broken.
func (r *RitualRepository) GetStreak(ctx context.Context, userID uuid.UUID) (int, error) {
	var streak int
	err := r.db.QueryRowxContext(ctx,
		`SELECT COALESCE(MAX(streak_count), 0) FROM ritual_completions
		 WHERE user_id = $1 AND completed_date >= CURRENT_DATE - INTERVAL '1 day'`,
		userID,
	).Scan(&streak)
	return streak, err
}
