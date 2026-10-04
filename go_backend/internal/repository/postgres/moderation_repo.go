package postgres

import (
	"context"
	"database/sql"
	"errors"
	"fmt"

	"cosmic-mirror/internal/domain"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

// ModerationRepository backs content reports, user blocks, hiding
// reported content and banning accounts (migration 015).
type ModerationRepository struct {
	db *sqlx.DB
}

func NewModerationRepository(db *sqlx.DB) *ModerationRepository {
	return &ModerationRepository{db: db}
}

// ===== Report targets =====

// ReportTarget is what a report points at, resolved for validation,
// self-report checks, and the moderation e-mail.
type ReportTarget struct {
	OwnerID *uuid.UUID // author / space creator / the user themself; nil for an ownerless space
	Snippet string     // the reported text (post/comment body, space name + description, user name)
	PostID  *uuid.UUID // comments: the post they belong to
}

// GetReportTarget loads the target of a report. Returns nil, nil when it
// doesn't exist (or, for users, was deleted).
func (r *ModerationRepository) GetReportTarget(ctx context.Context, targetType string, id uuid.UUID) (*ReportTarget, error) {
	var row struct {
		OwnerID *uuid.UUID `db:"owner_id"`
		Snippet string     `db:"snippet"`
		PostID  *uuid.UUID `db:"post_id"`
	}
	var q string
	switch targetType {
	case domain.ReportTargetPost:
		q = `SELECT author_id AS owner_id, content AS snippet, NULL::uuid AS post_id FROM posts WHERE id = $1`
	case domain.ReportTargetComment:
		q = `SELECT author_id AS owner_id, content AS snippet, post_id FROM comments WHERE id = $1`
	case domain.ReportTargetSpace:
		q = `SELECT created_by AS owner_id,
		            name || COALESCE(E'\n' || description, '') AS snippet,
		            NULL::uuid AS post_id
		     FROM spaces WHERE id = $1`
	case domain.ReportTargetUser:
		q = `SELECT id AS owner_id, name AS snippet, NULL::uuid AS post_id
		     FROM users WHERE id = $1 AND deleted_at IS NULL`
	default:
		return nil, fmt.Errorf("%w: unknown target type", domain.ErrValidation)
	}
	err := r.db.GetContext(ctx, &row, q, id)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &ReportTarget{OwnerID: row.OwnerID, Snippet: row.Snippet, PostID: row.PostID}, nil
}

// ===== Reports =====

// CreateReport inserts a report. Idempotent per (reporter, target): when
// the reporter already reported this target the existing row is loaded
// into rep and created=false.
func (r *ModerationRepository) CreateReport(ctx context.Context, rep *domain.ContentReport) (created bool, err error) {
	rep.ID = uuid.New()
	rep.Status = domain.ReportStatusOpen
	err = r.db.GetContext(ctx, &rep.CreatedAt,
		`INSERT INTO content_reports (id, reporter_id, target_type, target_id, reason, details)
		 VALUES ($1, $2, $3, $4, $5, $6)
		 ON CONFLICT (reporter_id, target_type, target_id) DO NOTHING
		 RETURNING created_at`,
		rep.ID, rep.ReporterID, rep.TargetType, rep.TargetID, rep.Reason, rep.Details,
	)
	if err == nil {
		return true, nil
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return false, err
	}
	// Conflict: return the reporter's existing report.
	err = r.db.GetContext(ctx, rep,
		`SELECT * FROM content_reports
		 WHERE reporter_id = $1 AND target_type = $2 AND target_id = $3`,
		rep.ReporterID, rep.TargetType, rep.TargetID,
	)
	return false, err
}

// CountOpenReports counts the open reports on a target. The UNIQUE
// (reporter_id, target_type, target_id) constraint makes this the number
// of distinct reporters.
func (r *ModerationRepository) CountOpenReports(ctx context.Context, targetType string, targetID uuid.UUID) (int, error) {
	var n int
	err := r.db.GetContext(ctx, &n,
		`SELECT COUNT(*) FROM content_reports
		 WHERE target_type = $1 AND target_id = $2 AND status = 'open'`,
		targetType, targetID,
	)
	return n, err
}

func (r *ModerationRepository) GetReport(ctx context.Context, id uuid.UUID) (*domain.ContentReport, error) {
	var rep domain.ContentReport
	err := r.db.GetContext(ctx, &rep, `SELECT * FROM content_reports WHERE id = $1`, id)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &rep, err
}

// ListReports is the admin moderation queue, oldest first, with a
// snippet of each target and its open-report count.
func (r *ModerationRepository) ListReports(ctx context.Context, status string, limit, offset int) ([]domain.AdminReport, error) {
	out := []domain.AdminReport{}
	err := r.db.SelectContext(ctx, &out,
		`SELECT cr.*,
		        COALESCE(ru.email::text, '') AS reporter_email,
		        CASE cr.target_type
		          WHEN 'post'    THEN (SELECT LEFT(p.content, 500) FROM posts p WHERE p.id = cr.target_id)
		          WHEN 'comment' THEN (SELECT LEFT(c.content, 500) FROM comments c WHERE c.id = cr.target_id)
		          WHEN 'space'   THEN (SELECT s.name || COALESCE(E'\n' || LEFT(s.description, 400), '') FROM spaces s WHERE s.id = cr.target_id)
		          WHEN 'user'    THEN (SELECT u.name FROM users u WHERE u.id = cr.target_id)
		        END AS target_snippet,
		        CASE cr.target_type
		          WHEN 'post'    THEN (SELECT p.author_id::text FROM posts p WHERE p.id = cr.target_id)
		          WHEN 'comment' THEN (SELECT c.author_id::text FROM comments c WHERE c.id = cr.target_id)
		          WHEN 'space'   THEN (SELECT s.created_by::text FROM spaces s WHERE s.id = cr.target_id)
		          WHEN 'user'    THEN cr.target_id::text
		        END AS target_owner_id,
		        COALESCE(CASE cr.target_type
		          WHEN 'post'    THEN (SELECT p.hidden_at IS NOT NULL FROM posts p WHERE p.id = cr.target_id)
		          WHEN 'comment' THEN (SELECT c.hidden_at IS NOT NULL FROM comments c WHERE c.id = cr.target_id)
		        END, FALSE) AS target_hidden,
		        (SELECT COUNT(*) FROM content_reports o
		         WHERE o.target_type = cr.target_type AND o.target_id = cr.target_id
		           AND o.status = 'open')::int AS open_report_count
		 FROM content_reports cr
		 LEFT JOIN users ru ON ru.id = cr.reporter_id
		 WHERE cr.status = $1
		 ORDER BY cr.created_at ASC
		 LIMIT $2 OFFSET $3`,
		status, limit, offset,
	)
	return out, err
}

// ResolveReports closes report [reportID] and every other open report on
// the same target with [status] — one moderator decision covers all
// reporters of the same content.
func (r *ModerationRepository) ResolveReports(ctx context.Context, q Querier, rep *domain.ContentReport, status string, note *string) error {
	_, err := q.ExecContext(ctx,
		`UPDATE content_reports
		 SET status = $1, reviewed_at = NOW(), reviewed_note = $2
		 WHERE id = $3
		    OR (target_type = $4 AND target_id = $5 AND status = 'open')`,
		status, note, rep.ID, rep.TargetType, rep.TargetID,
	)
	return err
}

// SetHidden hides (hidden=true) or un-hides a post or comment. Hiding
// keeps the original timestamp when already hidden.
func (r *ModerationRepository) SetHidden(ctx context.Context, q Querier, targetType string, id uuid.UUID, hidden bool) error {
	var table string
	switch targetType {
	case domain.ReportTargetPost:
		table = "posts"
	case domain.ReportTargetComment:
		table = "comments"
	default:
		return fmt.Errorf("%w: only posts and comments can be hidden", domain.ErrValidation)
	}
	expr := "NULL"
	if hidden {
		expr = "COALESCE(hidden_at, NOW())"
	}
	_, err := q.ExecContext(ctx, `UPDATE `+table+` SET hidden_at = `+expr+` WHERE id = $1`, id)
	return err
}

// BanUser stamps users.banned_at (idempotent).
func (r *ModerationRepository) BanUser(ctx context.Context, q Querier, userID uuid.UUID) error {
	_, err := q.ExecContext(ctx,
		`UPDATE users SET banned_at = COALESCE(banned_at, NOW()), updated_at = NOW() WHERE id = $1`,
		userID,
	)
	return err
}

// ===== Blocks =====

// Block records that blocker blocked blocked. Idempotent.
func (r *ModerationRepository) Block(ctx context.Context, blockerID, blockedID uuid.UUID) error {
	_, err := r.db.ExecContext(ctx,
		`INSERT INTO user_blocks (blocker_id, blocked_id) VALUES ($1, $2)
		 ON CONFLICT (blocker_id, blocked_id) DO NOTHING`,
		blockerID, blockedID,
	)
	return err
}

// Unblock removes a block. Idempotent.
func (r *ModerationRepository) Unblock(ctx context.Context, blockerID, blockedID uuid.UUID) error {
	_, err := r.db.ExecContext(ctx,
		`DELETE FROM user_blocks WHERE blocker_id = $1 AND blocked_id = $2`,
		blockerID, blockedID,
	)
	return err
}

// ListBlocks returns the users [blockerID] has blocked, newest first.
func (r *ModerationRepository) ListBlocks(ctx context.Context, blockerID uuid.UUID) ([]domain.BlockedUser, error) {
	out := []domain.BlockedUser{}
	err := r.db.SelectContext(ctx, &out,
		`SELECT ub.blocked_id AS user_id, u.name, u.avatar_url, ub.created_at AS blocked_at
		 FROM user_blocks ub
		 JOIN users u ON u.id = ub.blocked_id
		 WHERE ub.blocker_id = $1 AND u.deleted_at IS NULL
		 ORDER BY ub.created_at DESC
		 LIMIT 500`,
		blockerID,
	)
	return out, err
}
