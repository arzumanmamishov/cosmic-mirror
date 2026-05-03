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

type CommentRepository struct {
	db *sqlx.DB
}

func NewCommentRepository(db *sqlx.DB) *CommentRepository {
	return &CommentRepository{db: db}
}

const commentWithMetaSelect = `
	SELECT c.*,
	       u.name     AS author_name,
	       NULL::text AS author_avatar_url,
	       EXISTS(SELECT 1 FROM likes l
	              WHERE l.target_type = 'comment'
	                AND l.target_id   = c.id
	                AND l.user_id     = $1) AS is_liked_by_me
	FROM comments c
	JOIN users    u ON u.id = c.author_id
`

func (r *CommentRepository) Create(ctx context.Context, tx Querier, c *domain.Comment) error {
	c.ID = uuid.New()
	now := time.Now()
	c.CreatedAt = now
	c.UpdatedAt = now
	_, err := tx.ExecContext(ctx,
		`INSERT INTO comments (id, post_id, parent_comment_id, author_id, content,
		 like_count, created_at, updated_at)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
		c.ID, c.PostID, c.ParentCommentID, c.AuthorID, c.Content,
		c.LikeCount, c.CreatedAt, c.UpdatedAt,
	)
	return err
}

func (r *CommentRepository) GetByID(ctx context.Context, id, currentUserID uuid.UUID) (*domain.CommentWithMeta, error) {
	var c domain.CommentWithMeta
	err := r.db.GetContext(ctx, &c, commentWithMetaSelect+` WHERE c.id = $2`, currentUserID, id)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &c, err
}

func (r *CommentRepository) GetBareByID(ctx context.Context, id uuid.UUID) (*domain.Comment, error) {
	var c domain.Comment
	err := r.db.GetContext(ctx, &c, `SELECT * FROM comments WHERE id = $1`, id)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &c, err
}

func (r *CommentRepository) ListByPost(ctx context.Context, postID, currentUserID uuid.UUID) ([]domain.CommentWithMeta, error) {
	var comments []domain.CommentWithMeta
	err := r.db.SelectContext(ctx, &comments,
		commentWithMetaSelect+` WHERE c.post_id = $2 ORDER BY c.created_at ASC`,
		currentUserID, postID,
	)
	return comments, err
}

func (r *CommentRepository) Update(ctx context.Context, id uuid.UUID, input domain.UpdateCommentInput) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE comments SET
		   content    = COALESCE($1, content),
		   updated_at = $2
		 WHERE id = $3`,
		input.Content, time.Now(), id,
	)
	return err
}

func (r *CommentRepository) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM comments WHERE id = $1`, id)
	return err
}

func (r *CommentRepository) IncrementLikeCount(ctx context.Context, tx *sqlx.Tx, id uuid.UUID, delta int) error {
	_, err := tx.ExecContext(ctx,
		`UPDATE comments SET like_count = GREATEST(like_count + $1, 0) WHERE id = $2`, delta, id,
	)
	return err
}
