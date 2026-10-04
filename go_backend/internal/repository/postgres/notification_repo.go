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
	// No recipient (e.g. an ownerless space whose creator was purged —
	// spaces.created_by is ON DELETE SET NULL and scans as uuid.Nil):
	// nothing to deliver. Inserting would violate the recipient FK and,
	// inside a caller's tx, abort the whole transaction.
	if n.RecipientID == uuid.Nil {
		return nil
	}
	n.ID = uuid.New()
	n.CreatedAt = time.Now()
	// INSERT … SELECT … WHERE so a notification across a block (either
	// direction) is silently dropped — a blocked user can't reach the
	// blocker through likes / comments / join requests. A NULL actor
	// matches no block row.
	q := `INSERT INTO community_notifications (id, recipient_id, actor_id, type, target_type, target_id, snippet, created_at)
	      SELECT $1::uuid, $2::uuid, $3::uuid, $4::text, $5::text, $6::uuid, $7::text, $8::timestamptz
	      WHERE ` + notBlockedSQL("$2::uuid", "$3::uuid")
	args := []any{n.ID, n.RecipientID, n.ActorID, n.Type, n.TargetType, n.TargetID, n.Snippet, n.CreatedAt}
	var err error
	if tx != nil {
		_, err = tx.ExecContext(ctx, q, args...)
	} else {
		_, err = r.db.ExecContext(ctx, q, args...)
	}
	return err
}

// CreateForSpaceMembers inserts one notification per approved member of
// the space (except the actor) in a single INSERT … SELECT, instead of one
// round-trip per member. Returns the number of notifications created.
func (r *CommunityNotificationRepository) CreateForSpaceMembers(
	ctx context.Context,
	spaceID, actorID uuid.UUID,
	notifType, targetType string,
	targetID uuid.UUID,
	snippet *string,
) (int64, error) {
	res, err := r.db.ExecContext(ctx,
		`INSERT INTO community_notifications
		   (id, recipient_id, actor_id, type, target_type, target_id, snippet, created_at)
		 SELECT uuid_generate_v4(), sm.user_id, $2::uuid, $3::text, $4::text, $5::uuid, $6::text, NOW()
		 FROM space_members sm
		 WHERE sm.space_id = $1 AND sm.status = 'approved' AND sm.user_id <> $2::uuid
		   AND `+notBlockedSQL("sm.user_id", "$2::uuid"),
		spaceID, actorID, notifType, targetType, targetID, snippet,
	)
	if err != nil {
		return 0, err
	}
	return res.RowsAffected()
}

// visibleNotificationSQL drops notifications whose actor is banned or in
// a block relationship with the recipient, and ones pointing at a post /
// comment that moderation hid (unless the recipient wrote it). Expects
// community_notifications aliased n, LEFT JOIN users u ON u.id = n.actor_id,
// and the recipient id in $1.
var visibleNotificationSQL = `(n.actor_id IS NULL OR (u.banned_at IS NULL AND ` + notBlockedSQL("$1", "n.actor_id") + `))
	AND NOT EXISTS (SELECT 1 FROM posts hp WHERE n.target_type = 'post' AND hp.id = n.target_id
	                AND hp.hidden_at IS NOT NULL AND hp.author_id <> n.recipient_id)
	AND NOT EXISTS (SELECT 1 FROM comments hc WHERE n.target_type = 'comment' AND hc.id = n.target_id
	                AND hc.hidden_at IS NOT NULL AND hc.author_id <> n.recipient_id)`

func (r *CommunityNotificationRepository) ListByUser(ctx context.Context, recipientID uuid.UUID, unreadOnly bool, limit, offset int) ([]domain.NotificationWithMeta, error) {
	where := "WHERE n.recipient_id = $1 AND " + visibleNotificationSQL
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
	// Same visibility rules as ListByUser so the badge never counts a
	// notification the feed won't show.
	err := r.db.GetContext(ctx, &count,
		`SELECT COUNT(*) FROM community_notifications n
		 LEFT JOIN users u ON u.id = n.actor_id
		 WHERE n.recipient_id = $1 AND n.read_at IS NULL AND `+visibleNotificationSQL,
		recipientID,
	)
	return count, err
}
