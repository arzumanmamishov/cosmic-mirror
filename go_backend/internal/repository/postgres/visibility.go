package postgres

import (
	"context"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

// SQL fragments that keep moderated content out of every community list
// (App Store 1.2 / Google Play UGC). Used by the post, comment, member,
// notification and hashtag queries — keep them here so the rules live in
// one place:
//
//   - blocks are symmetric in effect: if A blocked B, neither sees the
//     other's posts, comments, membership rows or notifications;
//   - hidden content (hidden_at set by auto-hide or a moderator) is only
//     visible to its author;
//   - banned authors' content is visible to nobody.
//
// Both directions of the block check are primary-key point lookups on
// user_blocks(blocker_id, blocked_id), so the NOT EXISTS is cheap even
// when it runs once per row.

// notBlockedSQL is true when neither [viewer] nor [other] has blocked the
// other. Arguments are SQL expressions (a placeholder like "$1" or a
// column like "p.author_id").
func notBlockedSQL(viewer, other string) string {
	return `NOT EXISTS (SELECT 1 FROM user_blocks ub
	        WHERE (ub.blocker_id = ` + viewer + ` AND ub.blocked_id = ` + other + `)
	           OR (ub.blocker_id = ` + other + ` AND ub.blocked_id = ` + viewer + `))`
}

// visibleContentSQL filters a post or comment row aliased [alias] whose
// author row (users) is aliased [authorAlias], as seen by [viewer].
func visibleContentSQL(alias, authorAlias, viewer string) string {
	return `(` + alias + `.hidden_at IS NULL OR ` + alias + `.author_id = ` + viewer + `)
	   AND ` + authorAlias + `.banned_at IS NULL
	   AND ` + notBlockedSQL(viewer, alias+`.author_id`)
}

// IsBlockedEither reports whether a blocked b or b blocked a. Services use
// it to refuse interactions (comment, like, reply) across a block.
func IsBlockedEither(ctx context.Context, q sqlx.QueryerContext, a, b uuid.UUID) (bool, error) {
	if a == b {
		return false, nil
	}
	var blocked bool
	err := sqlx.GetContext(ctx, q, &blocked,
		`SELECT EXISTS (SELECT 1 FROM user_blocks
		 WHERE (blocker_id = $1 AND blocked_id = $2)
		    OR (blocker_id = $2 AND blocked_id = $1))`, a, b)
	return blocked, err
}

// HasBlocked reports whether blocker has blocked blocked (one direction
// only — used to tell "I blocked them" from "they blocked me").
func HasBlocked(ctx context.Context, q sqlx.QueryerContext, blockerID, blockedID uuid.UUID) (bool, error) {
	var ok bool
	err := sqlx.GetContext(ctx, q, &ok,
		`SELECT EXISTS (SELECT 1 FROM user_blocks WHERE blocker_id = $1 AND blocked_id = $2)`,
		blockerID, blockedID,
	)
	return ok, err
}
