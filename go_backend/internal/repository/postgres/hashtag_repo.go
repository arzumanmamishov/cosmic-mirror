package postgres

import (
	"context"
	"strings"

	"cosmic-mirror/internal/domain"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type HashtagRepository struct {
	db *sqlx.DB
}

func NewHashtagRepository(db *sqlx.DB) *HashtagRepository {
	return &HashtagRepository{db: db}
}

// UpsertMany takes a slice of hashtag names (without leading #) and ensures
// each exists in the table. Returns the IDs in the same order as the input,
// deduped + lowercased.
func (r *HashtagRepository) UpsertMany(ctx context.Context, tx *sqlx.Tx, names []string) ([]uuid.UUID, error) {
	if len(names) == 0 {
		return nil, nil
	}
	// Dedupe + lowercase
	seen := make(map[string]struct{}, len(names))
	clean := make([]string, 0, len(names))
	for _, n := range names {
		l := strings.ToLower(strings.TrimSpace(n))
		if l == "" {
			continue
		}
		if _, ok := seen[l]; ok {
			continue
		}
		seen[l] = struct{}{}
		clean = append(clean, l)
	}
	if len(clean) == 0 {
		return nil, nil
	}

	ids := make([]uuid.UUID, 0, len(clean))
	for _, name := range clean {
		var id uuid.UUID
		// ON CONFLICT update use_count is bumped at link time, not here.
		err := tx.GetContext(ctx, &id,
			`INSERT INTO hashtags (id, name)
			 VALUES (uuid_generate_v4(), $1)
			 ON CONFLICT (name) DO UPDATE SET name = EXCLUDED.name
			 RETURNING id`,
			name,
		)
		if err != nil {
			return nil, err
		}
		ids = append(ids, id)
	}
	return ids, nil
}

func (r *HashtagRepository) LinkPost(ctx context.Context, tx *sqlx.Tx, postID uuid.UUID, hashtagIDs []uuid.UUID) error {
	for _, hid := range hashtagIDs {
		if _, err := tx.ExecContext(ctx,
			`INSERT INTO post_hashtags (post_id, hashtag_id)
			 VALUES ($1, $2) ON CONFLICT DO NOTHING`,
			postID, hid,
		); err != nil {
			return err
		}
		if _, err := tx.ExecContext(ctx,
			`UPDATE hashtags SET use_count = use_count + 1 WHERE id = $1`, hid,
		); err != nil {
			return err
		}
	}
	return nil
}

// UnlinkPost removes all post→hashtag rows for a post and decrements each
// hashtag's use_count. Used on post deletion.
func (r *HashtagRepository) UnlinkPost(ctx context.Context, tx *sqlx.Tx, postID uuid.UUID) error {
	var hashtagIDs []uuid.UUID
	if err := tx.SelectContext(ctx, &hashtagIDs,
		`SELECT hashtag_id FROM post_hashtags WHERE post_id = $1`, postID,
	); err != nil {
		return err
	}
	if _, err := tx.ExecContext(ctx,
		`DELETE FROM post_hashtags WHERE post_id = $1`, postID,
	); err != nil {
		return err
	}
	for _, hid := range hashtagIDs {
		if _, err := tx.ExecContext(ctx,
			`UPDATE hashtags SET use_count = GREATEST(use_count - 1, 0) WHERE id = $1`, hid,
		); err != nil {
			return err
		}
	}
	return nil
}

// ListPopular ranks hashtags by use in the spaces [viewerID] is an
// approved member of. Spaces are members-only, so a global ranking would
// leak what private spaces talk about.
func (r *HashtagRepository) ListPopular(ctx context.Context, viewerID uuid.UUID, limit int) ([]domain.Hashtag, error) {
	var tags []domain.Hashtag
	err := r.db.SelectContext(ctx, &tags,
		`SELECT h.id, h.name, COUNT(*)::int AS use_count, h.created_at
		 FROM hashtags h
		 JOIN post_hashtags ph ON ph.hashtag_id = h.id
		 JOIN posts p ON p.id = ph.post_id
		 JOIN users u ON u.id = p.author_id
		 JOIN space_members m ON m.space_id = p.space_id
		   AND m.user_id = $1 AND m.status = 'approved'
		 WHERE `+visibleContentSQL("p", "u", "$1")+`
		 GROUP BY h.id
		 ORDER BY use_count DESC, h.name ASC
		 LIMIT $2`, viewerID, limit,
	)
	return tags, err
}

// ListPostsForHashtag returns post ids tagged with the given name.
func (r *HashtagRepository) GetIDByName(ctx context.Context, name string) (*uuid.UUID, error) {
	var id uuid.UUID
	err := r.db.GetContext(ctx, &id,
		`SELECT id FROM hashtags WHERE LOWER(name) = LOWER($1)`, name,
	)
	if err != nil {
		return nil, err
	}
	return &id, nil
}
