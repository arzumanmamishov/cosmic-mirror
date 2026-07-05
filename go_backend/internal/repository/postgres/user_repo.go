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

// userSelectCols is the column list every read path uses. Kept in one place
// so adding a column doesn't need touching every SELECT. firebase_uid is
// COALESCE'd to '' because the column is now nullable but the domain type
// still uses `string` (empty = no Firebase link).
const userSelectCols = `id, COALESCE(firebase_uid, '') AS firebase_uid, email, name,
    avatar_url, password_hash, email_verified_at, last_login_at,
    created_at, updated_at`

type UserRepository struct {
	db *sqlx.DB
}

func NewUserRepository(db *sqlx.DB) *UserRepository {
	return &UserRepository{db: db}
}

// Create inserts a user row. When FirebaseUID is empty we store NULL — the
// column is nullable so passwordless (email+password) accounts don't need a
// synthetic Firebase id.
func (r *UserRepository) Create(ctx context.Context, user *domain.User) error {
	user.ID = uuid.New()
	user.CreatedAt = time.Now()
	user.UpdatedAt = time.Now()

	var firebaseUID any
	if user.FirebaseUID != "" {
		firebaseUID = user.FirebaseUID
	}

	_, err := r.db.ExecContext(ctx,
		`INSERT INTO users
		    (id, firebase_uid, email, name, password_hash, email_verified_at, created_at, updated_at)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
		user.ID, firebaseUID, user.Email, user.Name,
		user.PasswordHash, user.EmailVerifiedAt,
		user.CreatedAt, user.UpdatedAt,
	)
	return err
}

func (r *UserRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.User, error) {
	var user domain.User
	err := r.db.GetContext(ctx, &user,
		`SELECT `+userSelectCols+` FROM users WHERE id = $1 AND deleted_at IS NULL`, id,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &user, err
}

func (r *UserRepository) GetByFirebaseUID(ctx context.Context, uid string) (*domain.User, error) {
	var user domain.User
	err := r.db.GetContext(ctx, &user,
		`SELECT `+userSelectCols+` FROM users WHERE firebase_uid = $1 AND deleted_at IS NULL`, uid,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &user, err
}

// GetByEmail is case-insensitive because the column is citext (migration
// 010). Used on every local-auth path (register lookup, login, reset).
func (r *UserRepository) GetByEmail(ctx context.Context, email string) (*domain.User, error) {
	var user domain.User
	err := r.db.GetContext(ctx, &user,
		`SELECT `+userSelectCols+` FROM users WHERE email = $1 AND deleted_at IS NULL`, email,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &user, err
}

// SetAvatarURL writes the new avatar URL (or NULL when url is nil) and
// bumps updated_at.
func (r *UserRepository) SetAvatarURL(ctx context.Context, id uuid.UUID, url *string) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE users SET avatar_url = $1, updated_at = $2 WHERE id = $3`,
		url, time.Now(), id,
	)
	return err
}

// UpdatePasswordHash sets the bcrypt hash (set by register-with-password and
// by password-reset). Also bumps updated_at so external caches invalidate.
func (r *UserRepository) UpdatePasswordHash(ctx context.Context, id uuid.UUID, hash string) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE users SET password_hash = $1, updated_at = $2 WHERE id = $3`,
		hash, time.Now(), id,
	)
	return err
}

// MarkEmailVerified stamps email_verified_at=now() if it wasn't already set.
// Called after a successful register/login OTP verify.
func (r *UserRepository) MarkEmailVerified(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE users SET email_verified_at = COALESCE(email_verified_at, now()),
		 updated_at = now() WHERE id = $1`, id,
	)
	return err
}

// TouchLastLogin updates last_login_at to now(). Used purely for telemetry
// so a dormant account can be flagged.
func (r *UserRepository) TouchLastLogin(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE users SET last_login_at = now() WHERE id = $1`, id,
	)
	return err
}

func (r *UserRepository) Update(ctx context.Context, id uuid.UUID, input domain.UpdateUserInput) error {
	if input.Name != nil {
		_, err := r.db.ExecContext(ctx,
			`UPDATE users SET name = $1, updated_at = $2 WHERE id = $3`,
			*input.Name, time.Now(), id,
		)
		return err
	}
	return nil
}

func (r *UserRepository) SoftDelete(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE users SET deleted_at = $1, updated_at = $1 WHERE id = $2`,
		time.Now(), id,
	)
	return err
}
