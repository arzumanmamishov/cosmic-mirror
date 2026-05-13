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

// Add inserts a (space_id, user_id, role, status) row. Idempotent: ON
// CONFLICT DO NOTHING so re-joining is a no-op. The creator of a space
// passes status='approved'; regular Join requests pass 'pending'.
func (r *SpaceMemberRepository) Add(ctx context.Context, tx *sqlx.Tx, spaceID, userID uuid.UUID, role, status string) (added bool, err error) {
	res, err := tx.ExecContext(ctx,
		`INSERT INTO space_members (space_id, user_id, role, status)
		 VALUES ($1, $2, $3, $4)
		 ON CONFLICT (space_id, user_id) DO NOTHING`,
		spaceID, userID, role, status,
	)
	if err != nil {
		return false, err
	}
	rows, _ := res.RowsAffected()
	return rows > 0, nil
}

// Approve flips a pending request to approved. Returns ok=true iff a row
// was actually updated (so callers can tell "approved a real pending
// request" vs "no such request / already approved").
func (r *SpaceMemberRepository) Approve(ctx context.Context, tx *sqlx.Tx, spaceID, userID uuid.UUID) (ok bool, err error) {
	res, err := tx.ExecContext(ctx,
		`UPDATE space_members
		 SET status = 'approved'
		 WHERE space_id = $1 AND user_id = $2 AND status = 'pending'`,
		spaceID, userID,
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

// Decline drops a pending request. Returns ok=true iff a pending row
// was deleted; declining a non-existent or already-approved request is a
// no-op. We delete (instead of marking 'rejected') so the user can
// submit a new request later.
func (r *SpaceMemberRepository) Decline(ctx context.Context, tx *sqlx.Tx, spaceID, userID uuid.UUID) (ok bool, err error) {
	res, err := tx.ExecContext(ctx,
		`DELETE FROM space_members
		 WHERE space_id = $1 AND user_id = $2 AND status = 'pending'`,
		spaceID, userID,
	)
	if err != nil {
		return false, err
	}
	rows, _ := res.RowsAffected()
	return rows > 0, nil
}

// IsApprovedMember returns true only when the user is an approved member
// (or owner) of the space — used to gate post reads.
func (r *SpaceMemberRepository) IsApprovedMember(ctx context.Context, spaceID, userID uuid.UUID) (bool, error) {
	var ok bool
	err := r.db.GetContext(ctx, &ok,
		`SELECT EXISTS(
		   SELECT 1 FROM space_members
		   WHERE space_id = $1 AND user_id = $2 AND status = 'approved'
		 )`,
		spaceID, userID,
	)
	return ok, err
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

// ListBySpace returns only APPROVED members. Pending rows are not part
// of the public member list — they're surfaced via ListPending for the
// space owner only.
func (r *SpaceMemberRepository) ListBySpace(ctx context.Context, spaceID uuid.UUID, limit, offset int) ([]domain.SpaceMember, error) {
	var members []domain.SpaceMember
	err := r.db.SelectContext(ctx, &members,
		`SELECT m.space_id, m.user_id, m.role, m.status, m.joined_at,
		        u.name AS user_name,
		        u.avatar_url AS user_avatar_url
		 FROM space_members m
		 JOIN users u ON u.id = m.user_id
		 WHERE m.space_id = $1 AND m.status = 'approved'
		 ORDER BY
		   CASE m.role WHEN 'owner' THEN 0 WHEN 'mod' THEN 1 ELSE 2 END,
		   m.joined_at ASC
		 LIMIT $2 OFFSET $3`,
		spaceID, limit, offset,
	)
	return members, err
}

// ListPending returns pending join requests for a space. Used by the
// owner's "manage requests" screen.
func (r *SpaceMemberRepository) ListPending(ctx context.Context, spaceID uuid.UUID, limit, offset int) ([]domain.SpaceMember, error) {
	var members []domain.SpaceMember
	err := r.db.SelectContext(ctx, &members,
		`SELECT m.space_id, m.user_id, m.role, m.status, m.joined_at,
		        u.name AS user_name,
		        u.avatar_url AS user_avatar_url
		 FROM space_members m
		 JOIN users u ON u.id = m.user_id
		 WHERE m.space_id = $1 AND m.status = 'pending'
		 ORDER BY m.joined_at ASC
		 LIMIT $2 OFFSET $3`,
		spaceID, limit, offset,
	)
	return members, err
}

// CountPending returns the number of pending join requests for a space.
// Used by the owner's UI to render a badge on the "Manage requests"
// entry point.
func (r *SpaceMemberRepository) CountPending(ctx context.Context, spaceID uuid.UUID) (int, error) {
	var n int
	err := r.db.GetContext(ctx, &n,
		`SELECT COUNT(*) FROM space_members
		 WHERE space_id = $1 AND status = 'pending'`,
		spaceID,
	)
	return n, err
}

// ListMemberSpaceIDs returns just the space ids the user has been
// APPROVED into — used for the "post in a space I follow" notification
// fan-out and other read-side checks.
func (r *SpaceMemberRepository) ListMemberSpaceIDs(ctx context.Context, userID uuid.UUID) ([]uuid.UUID, error) {
	var ids []uuid.UUID
	err := r.db.SelectContext(ctx, &ids,
		`SELECT space_id FROM space_members
		 WHERE user_id = $1 AND status = 'approved'`, userID,
	)
	return ids, err
}

// ListSpaceMemberUserIDs returns user ids of every APPROVED member of a
// space — used to fan out "new post in space" notifications.
func (r *SpaceMemberRepository) ListSpaceMemberUserIDs(ctx context.Context, spaceID uuid.UUID) ([]uuid.UUID, error) {
	var ids []uuid.UUID
	err := r.db.SelectContext(ctx, &ids,
		`SELECT user_id FROM space_members
		 WHERE space_id = $1 AND status = 'approved'`, spaceID,
	)
	return ids, err
}
