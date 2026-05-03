package postgres

import (
	"context"
	"database/sql"
	"errors"

	"cosmic-mirror/internal/domain"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type SpaceCategoryRepository struct {
	db *sqlx.DB
}

func NewSpaceCategoryRepository(db *sqlx.DB) *SpaceCategoryRepository {
	return &SpaceCategoryRepository{db: db}
}

func (r *SpaceCategoryRepository) List(ctx context.Context) ([]domain.SpaceCategory, error) {
	var cats []domain.SpaceCategory
	err := r.db.SelectContext(ctx, &cats,
		`SELECT * FROM space_categories ORDER BY sort_order ASC, name ASC`,
	)
	return cats, err
}

func (r *SpaceCategoryRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.SpaceCategory, error) {
	var cat domain.SpaceCategory
	err := r.db.GetContext(ctx, &cat,
		`SELECT * FROM space_categories WHERE id = $1`, id,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &cat, err
}
