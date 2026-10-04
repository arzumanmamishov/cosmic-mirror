package otp

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

// ErrNotFound is returned by FindActive when there is no unconsumed OTP
// row for (email, purpose). The service maps it to the same generic
// "invalid or expired code" error the verify path returns for a hash
// mismatch, so we don't leak which case fired.
var ErrNotFound = errors.New("otp: no active code")

// Row is the shape returned by FindActive for the verify path.
type Row struct {
	ID          uuid.UUID `db:"id"`
	CodeHash    string    `db:"code_hash"`
	Attempts    int       `db:"attempts"`
	MaxAttempts int       `db:"max_attempts"`
	ExpiresAt   time.Time `db:"expires_at"`
}

// Repository is the DB surface for email_otps.
type Repository struct {
	db *sqlx.DB
}

func NewRepository(db *sqlx.DB) *Repository { return &Repository{db: db} }

// InsertParams is the argument set for a new OTP row.
type InsertParams struct {
	Email       string
	Purpose     Purpose
	CodeHash    string
	MaxAttempts int
	ExpiresAt   time.Time
	RequestedIP string
}

// Insert stores a freshly issued code. We never store the plaintext;
// CodeHash is sha256(code).
func (r *Repository) Insert(ctx context.Context, p InsertParams) (uuid.UUID, error) {
	const q = `
INSERT INTO email_otps
    (email, purpose, code_hash, max_attempts, expires_at, requested_ip)
VALUES
    ($1, $2, $3, $4, $5, NULLIF($6, ''))
RETURNING id`
	var id uuid.UUID
	err := r.db.QueryRowxContext(ctx, q,
		p.Email, string(p.Purpose), p.CodeHash, p.MaxAttempts, p.ExpiresAt, p.RequestedIP,
	).Scan(&id)
	return id, err
}

// FindActive returns the most recent unconsumed code for (email, purpose).
// The partial index on (email, purpose, created_at DESC) WHERE
// consumed_at IS NULL covers this lookup.
func (r *Repository) FindActive(ctx context.Context, email string, purpose Purpose) (*Row, error) {
	const q = `
SELECT id, code_hash, attempts, max_attempts, expires_at
FROM email_otps
WHERE email = $1 AND purpose = $2 AND consumed_at IS NULL
ORDER BY created_at DESC
LIMIT 1`
	var out Row
	err := r.db.GetContext(ctx, &out, q, email, string(purpose))
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrNotFound
	}
	if err != nil {
		return nil, err
	}
	return &out, nil
}

// ReserveAttempt atomically spends one guess on row [id] and returns its
// code hash. The check-and-increment happens in a single UPDATE so a burst
// of concurrent guesses can't all read attempts=0 and bypass the cap.
// Returns ErrNotFound when the row is consumed, expired, or out of guesses.
func (r *Repository) ReserveAttempt(ctx context.Context, id uuid.UUID) (string, error) {
	const q = `
UPDATE email_otps SET attempts = attempts + 1
WHERE id = $1 AND consumed_at IS NULL AND expires_at > now() AND attempts < max_attempts
RETURNING code_hash`
	var hash string
	err := r.db.QueryRowxContext(ctx, q, id).Scan(&hash)
	if errors.Is(err, sql.ErrNoRows) {
		return "", ErrNotFound
	}
	return hash, err
}

// Consume marks a row as used (single-use semantics — even a correct code
// can't be replayed within its TTL). Only one concurrent caller can win;
// the others get ErrNotFound.
func (r *Repository) Consume(ctx context.Context, id uuid.UUID, verifiedIP string) error {
	res, err := r.db.ExecContext(ctx,
		`UPDATE email_otps SET consumed_at = now(), verified_ip = NULLIF($2, '') WHERE id = $1 AND consumed_at IS NULL`,
		id, verifiedIP)
	if err != nil {
		return err
	}
	if n, _ := res.RowsAffected(); n != 1 {
		return ErrNotFound
	}
	return nil
}

// RecentCountForEmail returns how many rows we've issued for [email] in
// the trailing [window]. Used for per-email rate limiting when Redis
// isn't available.
func (r *Repository) RecentCountForEmail(ctx context.Context, email string, window time.Duration) (int, error) {
	const q = `SELECT count(*) FROM email_otps WHERE email = $1 AND created_at > now() - make_interval(secs => $2)`
	var n int
	err := r.db.QueryRowxContext(ctx, q, email, window.Seconds()).Scan(&n)
	return n, err
}

// FailedVerifyCount returns how many wrong guesses were made against codes
// issued to [email] (any purpose) in the trailing [window]. Every verify
// attempt bumps `attempts`, including the one that succeeds and consumes
// the row, so failures = sum(attempts) - consumed rows. Kept in Postgres
// (not Redis) so the lock can't be lost to a Redis eviction or restart.
func (r *Repository) FailedVerifyCount(ctx context.Context, email string, window time.Duration) (int, error) {
	const q = `
SELECT COALESCE(SUM(attempts), 0) - COUNT(consumed_at)
FROM email_otps
WHERE email = $1 AND created_at > now() - make_interval(secs => $2)`
	var n int
	err := r.db.QueryRowxContext(ctx, q, email, window.Seconds()).Scan(&n)
	return n, err
}
