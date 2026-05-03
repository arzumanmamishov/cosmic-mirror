package postgres

import (
	"context"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type LikeRepository struct {
	db *sqlx.DB
}

func NewLikeRepository(db *sqlx.DB) *LikeRepository {
	return &LikeRepository{db: db}
}

// Add inserts a like row. Idempotent via the (user_id, target_type, target_id)
// composite PK + ON CONFLICT DO NOTHING.
//
// Returns added=true when a row was actually inserted (so the service knows
// whether to bump the denormalized counter and emit a notification).
func (r *LikeRepository) Add(ctx context.Context, tx *sqlx.Tx, userID uuid.UUID, targetType string, targetID uuid.UUID) (added bool, err error) {
	res, err := tx.ExecContext(ctx,
		`INSERT INTO likes (user_id, target_type, target_id)
		 VALUES ($1, $2, $3)
		 ON CONFLICT (user_id, target_type, target_id) DO NOTHING`,
		userID, targetType, targetID,
	)
	if err != nil {
		return false, err
	}
	rows, _ := res.RowsAffected()
	return rows > 0, nil
}

// Remove deletes a like row. Returns removed=true when a row was actually
// deleted (so the service knows whether to bump the counter down).
func (r *LikeRepository) Remove(ctx context.Context, tx *sqlx.Tx, userID uuid.UUID, targetType string, targetID uuid.UUID) (removed bool, err error) {
	res, err := tx.ExecContext(ctx,
		`DELETE FROM likes WHERE user_id = $1 AND target_type = $2 AND target_id = $3`,
		userID, targetType, targetID,
	)
	if err != nil {
		return false, err
	}
	rows, _ := res.RowsAffected()
	return rows > 0, nil
}

func (r *LikeRepository) Exists(ctx context.Context, userID uuid.UUID, targetType string, targetID uuid.UUID) (bool, error) {
	var exists bool
	err := r.db.GetContext(ctx, &exists,
		`SELECT EXISTS(SELECT 1 FROM likes WHERE user_id = $1 AND target_type = $2 AND target_id = $3)`,
		userID, targetType, targetID,
	)
	return exists, err
}
