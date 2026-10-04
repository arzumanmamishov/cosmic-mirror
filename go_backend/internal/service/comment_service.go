package service

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/repository/postgres"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type CommentService struct {
	db          *sqlx.DB
	commentRepo *postgres.CommentRepository
	postRepo    *postgres.PostRepository
	memberRepo  *postgres.SpaceMemberRepository
	notifSvc    *CommunityNotificationService
}

func NewCommentService(
	db *sqlx.DB,
	commentRepo *postgres.CommentRepository,
	postRepo *postgres.PostRepository,
	memberRepo *postgres.SpaceMemberRepository,
	notifSvc *CommunityNotificationService,
) *CommentService {
	return &CommentService{db: db, commentRepo: commentRepo, postRepo: postRepo, memberRepo: memberRepo, notifSvc: notifSvc}
}

// assertMember returns ErrForbidden unless the user is an approved member
// of the space. Used to keep gated-space content (posts, comments, likes)
// from leaking to non-members who happen to hold an id.
func (s *CommentService) assertMember(ctx context.Context, spaceID, userID uuid.UUID) error {
	approved, err := s.memberRepo.IsApprovedMember(ctx, spaceID, userID)
	if err != nil {
		return err
	}
	if !approved {
		return ErrForbidden
	}
	return nil
}

var ErrCommentNotFound = errors.New("comment not found")

func (s *CommentService) Create(ctx context.Context, userID, postID uuid.UUID, input domain.CreateCommentInput) (*domain.Comment, error) {
	if strings.TrimSpace(input.Content) == "" {
		return nil, fmt.Errorf("%w: content is required", domain.ErrInvalidInput)
	}
	if err := input.Validate(); err != nil {
		return nil, err
	}
	post, err := s.postRepo.GetBareByID(ctx, postID)
	if err != nil {
		return nil, err
	}
	if post == nil {
		return nil, ErrPostNotFound
	}
	if err := s.assertMember(ctx, post.SpaceID, userID); err != nil {
		return nil, err
	}
	// Hidden posts are invisible to everyone but their author.
	if post.HiddenAt != nil && post.AuthorID != userID {
		return nil, ErrPostNotFound
	}
	// No commenting across a block (either direction).
	if blocked, err := postgres.IsBlockedEither(ctx, s.db, userID, post.AuthorID); err != nil {
		return nil, err
	} else if blocked {
		return nil, ErrForbidden
	}

	c := &domain.Comment{
		PostID:          postID,
		ParentCommentID: input.ParentCommentID,
		AuthorID:        userID,
		Content:         input.Content,
	}

	// Pre-fetch parent author for the "comment_replied" notification path
	// (before transaction so we can compute it in a single round-trip).
	// The parent must be a comment on THIS post — otherwise a member could
	// thread under (and notify the author of) a comment in a space they
	// can't see.
	var parentAuthorID *uuid.UUID
	if input.ParentCommentID != nil {
		parent, err := s.commentRepo.GetBareByID(ctx, *input.ParentCommentID)
		if err != nil {
			return nil, err
		}
		if parent == nil || parent.PostID != postID ||
			(parent.HiddenAt != nil && parent.AuthorID != userID) {
			return nil, ErrCommentNotFound
		}
		if blocked, err := postgres.IsBlockedEither(ctx, s.db, userID, parent.AuthorID); err != nil {
			return nil, err
		} else if blocked {
			return nil, ErrForbidden
		}
		parentAuthorID = &parent.AuthorID
	}

	err = postgres.WithTx(ctx, s.db, func(tx *sqlx.Tx) error {
		if err := s.commentRepo.Create(ctx, tx, c); err != nil {
			return err
		}
		if err := s.postRepo.IncrementCommentCount(ctx, tx, postID, +1); err != nil {
			return err
		}

		actor := userID
		snippet := truncateRunes(c.Content, 140, "…")

		// Notify the post author.
		if err := s.notifSvc.Emit(ctx, tx, EmitParams{
			RecipientID: post.AuthorID,
			ActorID:     &actor,
			Type:        "post_commented",
			TargetType:  "post",
			TargetID:    postID,
			Snippet:     &snippet,
		}); err != nil {
			// Logged inside Emit; continue.
			_ = err
		}

		// If this is a reply, also notify the parent comment's author.
		if parentAuthorID != nil && *parentAuthorID != post.AuthorID {
			_ = s.notifSvc.Emit(ctx, tx, EmitParams{
				RecipientID: *parentAuthorID,
				ActorID:     &actor,
				Type:        "comment_replied",
				TargetType:  "comment",
				TargetID:    *input.ParentCommentID,
				Snippet:     &snippet,
			})
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return c, nil
}

func (s *CommentService) ListByPost(ctx context.Context, postID, userID uuid.UUID) ([]domain.CommentWithMeta, error) {
	// Reading comments requires approved membership in the post's space.
	post, err := s.postRepo.GetBareByID(ctx, postID)
	if err != nil {
		return nil, err
	}
	if post == nil {
		return nil, ErrPostNotFound
	}
	if err := s.assertMember(ctx, post.SpaceID, userID); err != nil {
		return nil, err
	}
	// Same visibility as the post itself: hidden or across a block → 404.
	if post.AuthorID != userID {
		if post.HiddenAt != nil {
			return nil, ErrPostNotFound
		}
		if blocked, err := postgres.IsBlockedEither(ctx, s.db, userID, post.AuthorID); err != nil {
			return nil, err
		} else if blocked {
			return nil, ErrPostNotFound
		}
	}
	return s.commentRepo.ListByPost(ctx, postID, userID)
}

func (s *CommentService) Update(ctx context.Context, id, userID uuid.UUID, input domain.UpdateCommentInput) error {
	if err := input.Validate(); err != nil {
		return err
	}
	c, err := s.commentRepo.GetBareByID(ctx, id)
	if err != nil {
		return err
	}
	if c == nil {
		return ErrCommentNotFound
	}
	if c.AuthorID != userID {
		return ErrForbidden
	}
	return s.commentRepo.Update(ctx, id, input)
}

// Delete removes a comment (and, via ON DELETE CASCADE, its replies).
// Allowed for the comment's author and for the owner / moderators of the
// space the post lives in, so communities can clean up abuse themselves.
func (s *CommentService) Delete(ctx context.Context, id, userID uuid.UUID) error {
	c, err := s.commentRepo.GetBareByID(ctx, id)
	if err != nil {
		return err
	}
	if c == nil {
		return ErrCommentNotFound
	}
	if c.AuthorID != userID {
		ok, err := s.canModerateSpaceOfPost(ctx, c.PostID, userID)
		if err != nil {
			return err
		}
		if !ok {
			return ErrForbidden
		}
	}
	if err := s.commentRepo.Delete(ctx, id); err != nil {
		return err
	}
	// Recount rather than decrement: deleting a top-level comment also
	// cascades its replies (parent_comment_id ON DELETE CASCADE), so -1
	// would leave comment_count too high. The delete has committed, so
	// the recount sees it; a failed recount self-heals on the next delete.
	return s.postRepo.RecountComments(ctx, s.db, c.PostID)
}

// canModerateSpaceOfPost reports whether userID is an approved owner or
// mod of the space that postID belongs to.
func (s *CommentService) canModerateSpaceOfPost(ctx context.Context, postID, userID uuid.UUID) (bool, error) {
	post, err := s.postRepo.GetBareByID(ctx, postID)
	if err != nil {
		return false, err
	}
	if post == nil {
		return false, nil
	}
	role, status, err := s.memberRepo.GetMembership(ctx, post.SpaceID, userID)
	if err != nil {
		return false, err
	}
	return canModerateSpace(role, status), nil
}

// canModerateSpace: space owners and mods (approved) may remove other
// members' comments.
func canModerateSpace(role, status string) bool {
	return status == "approved" && (role == "owner" || role == "mod")
}
