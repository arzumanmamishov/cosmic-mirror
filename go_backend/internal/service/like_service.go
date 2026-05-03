package service

import (
	"context"
	"errors"

	"cosmic-mirror/internal/repository/postgres"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

// LikeService handles like/unlike for both posts and comments. The two share
// the same `likes` table (polymorphic on target_type) and the same logic:
// idempotent insert/delete, atomic counter update, optional notification.
type LikeService struct {
	db          *sqlx.DB
	likeRepo    *postgres.LikeRepository
	postRepo    *postgres.PostRepository
	commentRepo *postgres.CommentRepository
	notifSvc    *CommunityNotificationService
}

func NewLikeService(
	db *sqlx.DB,
	likeRepo *postgres.LikeRepository,
	postRepo *postgres.PostRepository,
	commentRepo *postgres.CommentRepository,
	notifSvc *CommunityNotificationService,
) *LikeService {
	return &LikeService{
		db: db, likeRepo: likeRepo, postRepo: postRepo,
		commentRepo: commentRepo, notifSvc: notifSvc,
	}
}

var ErrInvalidTargetType = errors.New("target type must be 'post' or 'comment'")

func (s *LikeService) Like(ctx context.Context, userID uuid.UUID, targetType string, targetID uuid.UUID) error {
	switch targetType {
	case "post", "comment":
	default:
		return ErrInvalidTargetType
	}

	return postgres.WithTx(ctx, s.db, func(tx *sqlx.Tx) error {
		added, err := s.likeRepo.Add(ctx, tx, userID, targetType, targetID)
		if err != nil {
			return err
		}
		if !added {
			return nil // already liked, no-op
		}

		// Bump the denormalized counter on the right table.
		switch targetType {
		case "post":
			if err := s.postRepo.IncrementLikeCount(ctx, tx, targetID, +1); err != nil {
				return err
			}
			// Emit "post_liked" to the author.
			if post, err := s.postRepo.GetBareByID(ctx, targetID); err == nil && post != nil {
				actor := userID
				_ = s.notifSvc.Emit(ctx, tx, EmitParams{
					RecipientID: post.AuthorID,
					ActorID:     &actor,
					Type:        "post_liked",
					TargetType:  "post",
					TargetID:    targetID,
				})
			}
		case "comment":
			if err := s.commentRepo.IncrementLikeCount(ctx, tx, targetID, +1); err != nil {
				return err
			}
			if c, err := s.commentRepo.GetBareByID(ctx, targetID); err == nil && c != nil {
				actor := userID
				_ = s.notifSvc.Emit(ctx, tx, EmitParams{
					RecipientID: c.AuthorID,
					ActorID:     &actor,
					Type:        "comment_liked",
					TargetType:  "comment",
					TargetID:    targetID,
				})
			}
		}
		return nil
	})
}

func (s *LikeService) Unlike(ctx context.Context, userID uuid.UUID, targetType string, targetID uuid.UUID) error {
	switch targetType {
	case "post", "comment":
	default:
		return ErrInvalidTargetType
	}

	return postgres.WithTx(ctx, s.db, func(tx *sqlx.Tx) error {
		removed, err := s.likeRepo.Remove(ctx, tx, userID, targetType, targetID)
		if err != nil {
			return err
		}
		if !removed {
			return nil
		}
		switch targetType {
		case "post":
			return s.postRepo.IncrementLikeCount(ctx, tx, targetID, -1)
		case "comment":
			return s.commentRepo.IncrementLikeCount(ctx, tx, targetID, -1)
		}
		return nil
	})
}
