package service

import (
	"context"
	"errors"
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
		return nil, errors.New("content is required")
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

	c := &domain.Comment{
		PostID:          postID,
		ParentCommentID: input.ParentCommentID,
		AuthorID:        userID,
		Content:         input.Content,
	}

	// Pre-fetch parent author for the "comment_replied" notification path
	// (before transaction so we can compute it in a single round-trip).
	var parentAuthorID *uuid.UUID
	if input.ParentCommentID != nil {
		parent, err := s.commentRepo.GetBareByID(ctx, *input.ParentCommentID)
		if err == nil && parent != nil {
			parentAuthorID = &parent.AuthorID
		}
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
	return s.commentRepo.ListByPost(ctx, postID, userID)
}

func (s *CommentService) Update(ctx context.Context, id, userID uuid.UUID, input domain.UpdateCommentInput) error {
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

func (s *CommentService) Delete(ctx context.Context, id, userID uuid.UUID) error {
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
	return postgres.WithTx(ctx, s.db, func(tx *sqlx.Tx) error {
		if err := s.commentRepo.Delete(ctx, id); err != nil {
			return err
		}
		return s.postRepo.IncrementCommentCount(ctx, tx, c.PostID, -1)
	})
}
