package postgres

import (
	"context"

	"cosmic-mirror/internal/domain"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type SpaceMemberRepository struct {
	db *sqlx.DB
}

func NewSpaceMemberRepository(db *sqlx.DB) *SpaceMemberRepository {
	return &SpaceMemberRepository{db: db}
}

// Add inserts a (space_id, user_id, role) row. Idempotent: ON CONFLICT DO
// NOTHING so re-joining is a no-op.
func (r *SpaceMemberRepository) Add(ctx context.Context, tx *sqlx.Tx, spaceID, userID uuid.UUID, role string) (added bool, err error) {
	res, err := tx.ExecContext(ctx,
		`INSERT INTO space_members (space_id, user_id, role)
		 VALUES ($1, $2, $3)
		 ON CONFLICT (space_id, user_id) DO NOTHING`,
		spaceID, userID, role,
	)
	if err != nil {
		return false, err
	}
	rows, _ := res.RowsAffected()
	return rows > 0, nil
}

func (r *SpaceMemberRepository) Remove(ctx context.Context, tx *sqlx.Tx, spaceID, userID uuid.UUID) (removed bool, err error) {
	res, err := tx.ExecContext(ctx,
		`DELETE FROM space_members WHERE space_id = $1 AND user_id = $2`,
		spaceID, userID,
	)
	if err != nil {
		return false, err
	}
	rows, _ := res.RowsAffected()
	return rows > 0, nil
}

func (r *SpaceMemberRepository) Exists(ctx context.Context, spaceID, userID uuid.UUID) (bool, error) {
	var exists bool
	err := r.db.GetContext(ctx, &exists,
		`SELECT EXISTS(SELECT 1 FROM space_members WHERE space_id = $1 AND user_id = $2)`,
		spaceID, userID,
	)
	return exists, err
}

func (r *SpaceMemberRepository) GetRole(ctx context.Context, spaceID, userID uuid.UUID) (string, error) {
	var role string
	err := r.db.GetContext(ctx, &role,
		`SELECT role FROM space_members WHERE space_id = $1 AND user_id = $2`,
		spaceID, userID,
	)
	return role, err
}

func (r *SpaceMemberRepository) ListBySpace(ctx context.Context, spaceID uuid.UUID, limit, offset int) ([]domain.SpaceMember, error) {
	var members []domain.SpaceMember
	err := r.db.SelectContext(ctx, &members,
		`SELECT m.space_id, m.user_id, m.role, m.joined_at,
		        u.name AS user_name,
		        NULL::text AS user_avatar_url
		 FROM space_members m
		 JOIN users u ON u.id = m.user_id
		 WHERE m.space_id = $1
		 ORDER BY
		   CASE m.role WHEN 'owner' THEN 0 WHEN 'mod' THEN 1 ELSE 2 END,
		   m.joined_at ASC
		 LIMIT $2 OFFSET $3`,
		spaceID, limit, offset,
	)
	return members, err
}

// ListMemberSpaceIDs returns just the space ids the user has joined — used
// for the "post in a space I follow" notification fan-out.
func (r *SpaceMemberRepository) ListMemberSpaceIDs(ctx context.Context, userID uuid.UUID) ([]uuid.UUID, error) {
	var ids []uuid.UUID
	err := r.db.SelectContext(ctx, &ids,
		`SELECT space_id FROM space_members WHERE user_id = $1`, userID,
	)
	return ids, err
}

// ListSpaceMemberUserIDs returns user ids of every member of a space — used
// to fan out "new post in space" notifications.
func (r *SpaceMemberRepository) ListSpaceMemberUserIDs(ctx context.Context, spaceID uuid.UUID) ([]uuid.UUID, error) {
	var ids []uuid.UUID
	err := r.db.SelectContext(ctx, &ids,
		`SELECT user_id FROM space_members WHERE space_id = $1`, spaceID,
	)
	return ids, err
}
