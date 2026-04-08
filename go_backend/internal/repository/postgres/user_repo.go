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

type UserRepository struct {
	db *sqlx.DB
}

func NewUserRepository(db *sqlx.DB) *UserRepository {
	return &UserRepository{db: db}
}

func (r *UserRepository) Create(ctx context.Context, user *domain.User) error {
	user.ID = uuid.New()
	user.CreatedAt = time.Now()
	user.UpdatedAt = time.Now()

	_, err := r.db.ExecContext(ctx,
		`INSERT INTO users (id, firebase_uid, email, name, created_at, updated_at)
		 VALUES ($1, $2, $3, $4, $5, $6)`,
		user.ID, user.FirebaseUID, user.Email, user.Name, user.CreatedAt, user.UpdatedAt,
	)
	return err
}

func (r *UserRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.User, error) {
	var user domain.User
	err := r.db.GetContext(ctx, &user,
		`SELECT id, firebase_uid, email, name, created_at, updated_at
		 FROM users WHERE id = $1 AND deleted_at IS NULL`, id,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &user, err
}

func (r *UserRepository) GetByFirebaseUID(ctx context.Context, uid string) (*domain.User, error) {
	var user domain.User
	err := r.db.GetContext(ctx, &user,
		`SELECT id, firebase_uid, email, name, created_at, updated_at
		 FROM users WHERE firebase_uid = $1 AND deleted_at IS NULL`, uid,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &user, err
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
