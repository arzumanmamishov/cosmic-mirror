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

type PostRepository struct {
	db *sqlx.DB
}

func NewPostRepository(db *sqlx.DB) *PostRepository {
	return &PostRepository{db: db}
}

// withMetaSelect is the joined SELECT clause that hydrates a Post into a
// PostWithMeta. Reused by GetByID and ListBySpace.
const postWithMetaSelect = `
	SELECT p.*,
	       u.name        AS author_name,
	       NULL::text    AS author_avatar_url,
	       s.handle      AS space_handle,
	       s.name        AS space_name,
	       EXISTS(SELECT 1 FROM likes l
	              WHERE l.target_type = 'post'
	                AND l.target_id   = p.id
	                AND l.user_id     = $1) AS is_liked_by_me
	FROM posts p
	JOIN users  u ON u.id = p.author_id
	JOIN spaces s ON s.id = p.space_id
`

func (r *PostRepository) Create(ctx context.Context, tx Querier, p *domain.Post) error {
	p.ID = uuid.New()
	now := time.Now()
	p.CreatedAt = now
	p.UpdatedAt = now
	_, err := tx.ExecContext(ctx,
		`INSERT INTO posts (id, space_id, author_id, content, link_url,
		 like_count, comment_count, created_at, updated_at)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
		p.ID, p.SpaceID, p.AuthorID, p.Content, p.LinkURL,
		p.LikeCount, p.CommentCount, p.CreatedAt, p.UpdatedAt,
	)
	return err
}

func (r *PostRepository) GetByID(ctx context.Context, id, currentUserID uuid.UUID) (*domain.PostWithMeta, error) {
	var p domain.PostWithMeta
	err := r.db.GetContext(ctx, &p, postWithMetaSelect+` WHERE p.id = $2`, currentUserID, id)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &p, err
}

// GetBareByID fetches the un-joined post (used when only ownership/space lookup
// is needed). Returns nil, nil on not found.
func (r *PostRepository) GetBareByID(ctx context.Context, id uuid.UUID) (*domain.Post, error) {
	var p domain.Post
	err := r.db.GetContext(ctx, &p, `SELECT * FROM posts WHERE id = $1`, id)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &p, err
}

func (r *PostRepository) ListBySpace(ctx context.Context, spaceID, currentUserID uuid.UUID, limit, offset int) ([]domain.PostWithMeta, error) {
	var posts []domain.PostWithMeta
	err := r.db.SelectContext(ctx, &posts,
		postWithMetaSelect+` WHERE p.space_id = $2 ORDER BY p.created_at DESC LIMIT $3 OFFSET $4`,
		currentUserID, spaceID, limit, offset,
	)
	return posts, err
}

func (r *PostRepository) Update(ctx context.Context, id uuid.UUID, input domain.UpdatePostInput) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE posts SET
		   content    = COALESCE($1, content),
		   link_url   = COALESCE($2, link_url),
		   updated_at = $3
		 WHERE id = $4`,
		input.Content, input.LinkURL, time.Now(), id,
	)
	return err
}

func (r *PostRepository) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM posts WHERE id = $1`, id)
	return err
}

func (r *PostRepository) IncrementLikeCount(ctx context.Context, tx *sqlx.Tx, id uuid.UUID, delta int) error {
	_, err := tx.ExecContext(ctx,
		`UPDATE posts SET like_count = GREATEST(like_count + $1, 0) WHERE id = $2`, delta, id,
	)
	return err
}

func (r *PostRepository) IncrementCommentCount(ctx context.Context, tx *sqlx.Tx, id uuid.UUID, delta int) error {
	_, err := tx.ExecContext(ctx,
		`UPDATE posts SET comment_count = GREATEST(comment_count + $1, 0) WHERE id = $2`, delta, id,
	)
	return err
}

// Querier is implemented by both *sqlx.DB and *sqlx.Tx — lets repos accept
// either a transaction or the bare connection.
type Querier interface {
	ExecContext(ctx context.Context, query string, args ...any) (sql.Result, error)
}
