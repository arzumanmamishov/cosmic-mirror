package postgres

import (
	"context"
	"fmt"

	"github.com/jmoiron/sqlx"
)

// WithTx runs `fn` inside a database transaction. If fn returns an error, the
// transaction is rolled back; otherwise it is committed. Used by services
// that need to update multiple tables atomically (e.g. inserting a like AND
// incrementing a denormalized counter, or creating a post AND its hashtags).
func WithTx(ctx context.Context, db *sqlx.DB, fn func(tx *sqlx.Tx) error) error {
	tx, err := db.BeginTxx(ctx, nil)
	if err != nil {
		return fmt.Errorf("begin tx: %w", err)
	}
	defer func() {
		if p := recover(); p != nil {
			_ = tx.Rollback()
			panic(p)
		}
	}()

	if err := fn(tx); err != nil {
		_ = tx.Rollback()
		return err
	}
	return tx.Commit()
}
