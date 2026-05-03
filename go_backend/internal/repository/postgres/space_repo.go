package postgres

import (
	"context"
	"database/sql"
	"errors"
	"strings"
	"time"

	"cosmic-mirror/internal/domain"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

// SpaceFilter selects which subset of spaces to return.
type SpaceFilter string

const (
	SpaceFilterAll    SpaceFilter = "all"
	SpaceFilterJoined SpaceFilter = "joined"
)

type SpaceRepository struct {
	db *sqlx.DB
}

func NewSpaceRepository(db *sqlx.DB) *SpaceRepository {
	return &SpaceRepository{db: db}
}

func (r *SpaceRepository) Create(ctx context.Context, s *domain.Space) error {
	s.ID = uuid.New()
	now := time.Now()
	s.CreatedAt = now
	s.UpdatedAt = now
	_, err := r.db.ExecContext(ctx,
		`INSERT INTO spaces (id, handle, name, description, avatar_url, category_id,
		 created_by, member_count, is_verified, is_spicy, created_at, updated_at)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
		s.ID, s.Handle, s.Name, s.Description, s.AvatarURL, s.CategoryID,
		s.CreatedBy, s.MemberCount, s.IsVerified, s.IsSpicy, s.CreatedAt, s.UpdatedAt,
	)
	return err
}

func (r *SpaceRepository) GetByID(ctx context.Context, id, currentUserID uuid.UUID) (*domain.SpaceWithMeta, error) {
	var s domain.SpaceWithMeta
	err := r.db.GetContext(ctx, &s,
		`SELECT s.*,
		        c.name AS category_name,
		        EXISTS(SELECT 1 FROM space_members m WHERE m.space_id = s.id AND m.user_id = $2) AS is_joined
		 FROM spaces s
		 LEFT JOIN space_categories c ON c.id = s.category_id
		 WHERE s.id = $1`,
		id, currentUserID,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &s, err
}

func (r *SpaceRepository) GetByHandle(ctx context.Context, handle string) (*domain.Space, error) {
	var s domain.Space
	err := r.db.GetContext(ctx, &s,
		`SELECT * FROM spaces WHERE LOWER(handle) = LOWER($1)`, handle,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &s, err
}

func (r *SpaceRepository) List(
	ctx context.Context,
	filter SpaceFilter,
	categoryID *uuid.UUID,
	query string,
	currentUserID uuid.UUID,
	limit, offset int,
) ([]domain.SpaceWithMeta, error) {
	var (
		args      []any
		condition []string
	)
	args = append(args, currentUserID) // $1 for the join
	idx := 2

	if filter == SpaceFilterJoined {
		condition = append(condition, "EXISTS (SELECT 1 FROM space_members m WHERE m.space_id = s.id AND m.user_id = $1)")
	}
	if categoryID != nil {
		condition = append(condition, "s.category_id = $"+itoa(idx))
		args = append(args, *categoryID)
		idx++
	}
	if q := strings.TrimSpace(query); q != "" {
		condition = append(condition, "(s.name ILIKE $"+itoa(idx)+" OR s.handle ILIKE $"+itoa(idx)+" OR COALESCE(s.description, '') ILIKE $"+itoa(idx)+")")
		args = append(args, "%"+q+"%")
		idx++
	}

	where := ""
	if len(condition) > 0 {
		where = "WHERE " + strings.Join(condition, " AND ")
	}
	args = append(args, limit, offset)

	sql := `SELECT s.*,
	               c.name AS category_name,
	               EXISTS(SELECT 1 FROM space_members m WHERE m.space_id = s.id AND m.user_id = $1) AS is_joined
	        FROM spaces s
	        LEFT JOIN space_categories c ON c.id = s.category_id
	        ` + where + `
	        ORDER BY s.member_count DESC, s.created_at DESC
	        LIMIT $` + itoa(idx) + ` OFFSET $` + itoa(idx+1)

	var spaces []domain.SpaceWithMeta
	err := r.db.SelectContext(ctx, &spaces, sql, args...)
	return spaces, err
}

func (r *SpaceRepository) Update(ctx context.Context, id uuid.UUID, input domain.UpdateSpaceInput) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE spaces SET
		   name        = COALESCE($1, name),
		   description = COALESCE($2, description),
		   avatar_url  = COALESCE($3, avatar_url),
		   category_id = COALESCE($4, category_id),
		   is_spicy    = COALESCE($5, is_spicy),
		   updated_at  = $6
		 WHERE id = $7`,
		input.Name, input.Description, input.AvatarURL, input.CategoryID, input.IsSpicy, time.Now(), id,
	)
	return err
}

func (r *SpaceRepository) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM spaces WHERE id = $1`, id)
	return err
}

func (r *SpaceRepository) IncrementMemberCount(ctx context.Context, tx *sqlx.Tx, id uuid.UUID, delta int) error {
	_, err := tx.ExecContext(ctx,
		`UPDATE spaces SET member_count = member_count + $1 WHERE id = $2`, delta, id,
	)
	return err
}

// itoa is a minimal int→string helper that avoids importing strconv just to
// build dynamic SQL. Inlined for clarity.
func itoa(i int) string {
	if i == 0 {
		return "0"
	}
	neg := i < 0
	if neg {
		i = -i
	}
	var buf [20]byte
	pos := len(buf)
	for i > 0 {
		pos--
		buf[pos] = byte('0' + i%10)
		i /= 10
	}
	if neg {
		pos--
		buf[pos] = '-'
	}
	return string(buf[pos:])
}
