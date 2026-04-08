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

type BirthProfileRepository struct {
	db *sqlx.DB
}

func NewBirthProfileRepository(db *sqlx.DB) *BirthProfileRepository {
	return &BirthProfileRepository{db: db}
}

func (r *BirthProfileRepository) Create(ctx context.Context, profile *domain.BirthProfile) error {
	profile.ID = uuid.New()
	profile.CreatedAt = time.Now()
	profile.UpdatedAt = time.Now()

	_, err := r.db.ExecContext(ctx,
		`INSERT INTO birth_profiles (id, user_id, birth_date, birth_time, birth_time_known,
		 birth_place, latitude, longitude, timezone, created_at, updated_at)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
		profile.ID, profile.UserID, profile.BirthDate, profile.BirthTime,
		profile.BirthTimeKnown, profile.BirthPlace, profile.Latitude,
		profile.Longitude, profile.Timezone, profile.CreatedAt, profile.UpdatedAt,
	)
	return err
}

func (r *BirthProfileRepository) GetByUserID(ctx context.Context, userID uuid.UUID) (*domain.BirthProfile, error) {
	var profile domain.BirthProfile
	err := r.db.GetContext(ctx, &profile,
		`SELECT id, user_id, birth_date, birth_time, birth_time_known,
		 birth_place, latitude, longitude, timezone, raw_chart_data,
		 created_at, updated_at
		 FROM birth_profiles WHERE user_id = $1`, userID,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &profile, err
}

func (r *BirthProfileRepository) Update(ctx context.Context, userID uuid.UUID, input domain.CreateBirthProfileInput) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE birth_profiles SET
		 birth_date = $1, birth_time = $2, birth_time_known = $3,
		 birth_place = $4, latitude = $5, longitude = $6, timezone = $7,
		 updated_at = $8
		 WHERE user_id = $9`,
		input.BirthDate, input.BirthTime, input.BirthTimeKnown,
		input.BirthPlace, input.Latitude, input.Longitude, input.Timezone,
		time.Now(), userID,
	)
	return err
}
