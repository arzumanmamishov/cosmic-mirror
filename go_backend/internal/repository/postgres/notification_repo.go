package postgres

import (
	"context"
	"time"

	"cosmic-mirror/internal/domain"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type CommunityNotificationRepository struct {
	db *sqlx.DB
}

func NewCommunityNotificationRepository(db *sqlx.DB) *CommunityNotificationRepository {
	return &CommunityNotificationRepository{db: db}
}

// Create accepts an optional transaction (or nil to use the bare DB). Used by
// services that emit a notification as part of a larger transaction (e.g.
// liking a post: insert like + bump counter + emit notification all in one tx).
func (r *CommunityNotificationRepository) Create(ctx context.Context, tx *sqlx.Tx, n *domain.CommunityNotification) error {
	n.ID = uuid.New()
	n.CreatedAt = time.Now()
	q := `INSERT INTO community_notifications (id, recipient_id, actor_id, type, target_type, target_id, snippet, created_at)
	      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`
	args := []any{n.ID, n.RecipientID, n.ActorID, n.Type, n.TargetType, n.TargetID, n.Snippet, n.CreatedAt}
	var err error
	if tx != nil {
		_, err = tx.ExecContext(ctx, q, args...)
	} else {
		_, err = r.db.ExecContext(ctx, q, args...)
	}
	return err
}

func (r *CommunityNotificationRepository) ListByUser(ctx context.Context, recipientID uuid.UUID, unreadOnly bool, limit, offset int) ([]domain.NotificationWithMeta, error) {
	where := "WHERE n.recipient_id = $1"
	args := []any{recipientID}
	if unreadOnly {
		where += " AND n.read_at IS NULL"
	}
	args = append(args, limit, offset)

	var out []domain.NotificationWithMeta
	q := `SELECT n.*,
	             u.name AS actor_name,
	             NULL::text AS actor_avatar_url
	      FROM community_notifications n
	      LEFT JOIN users u ON u.id = n.actor_id
	      ` + where + `
	      ORDER BY n.created_at DESC
	      LIMIT $` + itoa(len(args)-1) + ` OFFSET $` + itoa(len(args))
	err := r.db.SelectContext(ctx, &out, q, args...)
	return out, err
}

func (r *CommunityNotificationRepository) MarkRead(ctx context.Context, id, recipientID uuid.UUID) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE community_notifications SET read_at = NOW()
		 WHERE id = $1 AND recipient_id = $2 AND read_at IS NULL`,
		id, recipientID,
	)
	return err
}

func (r *CommunityNotificationRepository) MarkAllRead(ctx context.Context, recipientID uuid.UUID) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE community_notifications SET read_at = NOW()
		 WHERE recipient_id = $1 AND read_at IS NULL`, recipientID,
	)
	return err
}

func (r *CommunityNotificationRepository) UnreadCount(ctx context.Context, recipientID uuid.UUID) (int, error) {
	var count int
	err := r.db.GetContext(ctx, &count,
		`SELECT COUNT(*) FROM community_notifications WHERE recipient_id = $1 AND read_at IS NULL`,
		recipientID,
	)
	return count, err
}
