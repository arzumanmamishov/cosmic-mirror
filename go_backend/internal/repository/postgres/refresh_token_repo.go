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

// RefreshTokenRepository stores the sha256 hashes of opaque refresh tokens
// so a leak of the DB doesn't hand the attacker replayable credentials.
type RefreshTokenRepository struct {
	db *sqlx.DB
}

func NewRefreshTokenRepository(db *sqlx.DB) *RefreshTokenRepository {
	return &RefreshTokenRepository{db: db}
}

func (r *RefreshTokenRepository) Insert(
	ctx context.Context,
	userID uuid.UUID,
	tokenHash string,
	expiresAt time.Time,
	ip, userAgent string,
) (uuid.UUID, error) {
	var id uuid.UUID
	err := r.db.QueryRowxContext(ctx,
		`INSERT INTO refresh_tokens
		    (user_id, token_hash, expires_at, ip, user_agent)
		 VALUES ($1, $2, $3, NULLIF($4, ''), NULLIF($5, ''))
		 RETURNING id`,
		userID, tokenHash, expiresAt, ip, userAgent,
	).Scan(&id)
	return id, err
}

// FindActiveByHash returns the row for tokenHash iff it isn't revoked and
// hasn't expired. Returns nil, nil when the token is unknown so callers can
// map to a single "invalid refresh" error.
func (r *RefreshTokenRepository) FindActiveByHash(ctx context.Context, tokenHash string) (*domain.RefreshToken, error) {
	var t domain.RefreshToken
	err := r.db.GetContext(ctx, &t,
		`SELECT id, user_id, token_hash, expires_at, revoked_at, rotated_to_id, ip, user_agent, created_at
		 FROM refresh_tokens
		 WHERE token_hash = $1 AND revoked_at IS NULL AND expires_at > now()`,
		tokenHash,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &t, nil
}

// Rotate atomically revokes oldID and inserts a successor pointing at it.
// The two writes go in a transaction so a crash mid-rotation can't leak
// two active tokens for the same session.
func (r *RefreshTokenRepository) Rotate(
	ctx context.Context,
	oldID uuid.UUID,
	newTokenHash string,
	expiresAt time.Time,
	ip, userAgent string,
) (uuid.UUID, error) {
	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return uuid.Nil, err
	}
	defer func() { _ = tx.Rollback() }()

	var oldUserID uuid.UUID
	err = tx.QueryRowxContext(ctx,
		`SELECT user_id FROM refresh_tokens WHERE id = $1`, oldID,
	).Scan(&oldUserID)
	if err != nil {
		return uuid.Nil, err
	}

	var newID uuid.UUID
	err = tx.QueryRowxContext(ctx,
		`INSERT INTO refresh_tokens
		    (user_id, token_hash, expires_at, ip, user_agent)
		 VALUES ($1, $2, $3, NULLIF($4, ''), NULLIF($5, ''))
		 RETURNING id`,
		oldUserID, newTokenHash, expiresAt, ip, userAgent,
	).Scan(&newID)
	if err != nil {
		return uuid.Nil, err
	}

	if _, err := tx.ExecContext(ctx,
		`UPDATE refresh_tokens SET revoked_at = now(), rotated_to_id = $1 WHERE id = $2`,
		newID, oldID,
	); err != nil {
		return uuid.Nil, err
	}

	if err := tx.Commit(); err != nil {
		return uuid.Nil, err
	}
	return newID, nil
}

func (r *RefreshTokenRepository) Revoke(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE refresh_tokens SET revoked_at = now() WHERE id = $1 AND revoked_at IS NULL`, id,
	)
	return err
}

func (r *RefreshTokenRepository) RevokeByHash(ctx context.Context, tokenHash string) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE refresh_tokens SET revoked_at = now() WHERE token_hash = $1 AND revoked_at IS NULL`, tokenHash,
	)
	return err
}

// RevokeAllForUser is used after a suspected token-replay (rotation of an
// already-rotated token) or on password reset — every active session for
// that user is killed and they have to sign in again.
func (r *RefreshTokenRepository) RevokeAllForUser(ctx context.Context, userID uuid.UUID) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE refresh_tokens SET revoked_at = now()
		 WHERE user_id = $1 AND revoked_at IS NULL`,
		userID,
	)
	return err
}
