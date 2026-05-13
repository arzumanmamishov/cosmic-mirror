package service

import (
	"context"
	"errors"
	"fmt"
	"regexp"
	"strings"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/repository"
	"cosmic-mirror/internal/repository/postgres"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

// CommunityService owns spaces + memberships + categories + the
// per-user community profile (which joins user data + joined spaces + recent
// posts). Post + comment services live alongside.
type CommunityService struct {
	db         *sqlx.DB
	spaceRepo  *postgres.SpaceRepository
	memberRepo *postgres.SpaceMemberRepository
	catRepo    *postgres.SpaceCategoryRepository
	postRepo   *postgres.PostRepository
	userRepo   repository.UserRepository
	notifSvc   *CommunityNotificationService
}

func NewCommunityService(
	db *sqlx.DB,
	spaceRepo *postgres.SpaceRepository,
	memberRepo *postgres.SpaceMemberRepository,
	catRepo *postgres.SpaceCategoryRepository,
	postRepo *postgres.PostRepository,
	userRepo repository.UserRepository,
	notifSvc *CommunityNotificationService,
) *CommunityService {
	return &CommunityService{
		db: db, spaceRepo: spaceRepo, memberRepo: memberRepo,
		catRepo: catRepo, postRepo: postRepo, userRepo: userRepo,
		notifSvc: notifSvc,
	}
}

var (
	ErrSpaceNotFound = errors.New("space not found")
	ErrForbidden     = errors.New("forbidden")
	ErrInvalidHandle = errors.New("handle must be 3-50 chars of [a-z0-9_]")
	ErrHandleTaken   = errors.New("handle already taken")
)

var handleRegex = regexp.MustCompile(`^[a-z0-9_]{3,50}$`)

// ListSpaces returns the spaces feed for the current user.
func (s *CommunityService) ListSpaces(
	ctx context.Context,
	userID uuid.UUID,
	filter postgres.SpaceFilter,
	categoryID *uuid.UUID,
	query string,
	limit, offset int,
) ([]domain.SpaceWithMeta, error) {
	return s.spaceRepo.List(ctx, filter, categoryID, query, userID, limit, offset)
}

func (s *CommunityService) GetSpace(ctx context.Context, id, userID uuid.UUID) (*domain.SpaceWithMeta, error) {
	space, err := s.spaceRepo.GetByID(ctx, id, userID)
	if err != nil {
		return nil, err
	}
	if space == nil {
		return nil, ErrSpaceNotFound
	}
	return space, nil
}

func (s *CommunityService) CreateSpace(ctx context.Context, userID uuid.UUID, input domain.CreateSpaceInput) (*domain.Space, error) {
	handle := strings.ToLower(strings.TrimSpace(input.Handle))
	if !handleRegex.MatchString(handle) {
		return nil, ErrInvalidHandle
	}
	if existing, err := s.spaceRepo.GetByHandle(ctx, handle); err != nil {
		return nil, err
	} else if existing != nil {
		return nil, ErrHandleTaken
	}

	space := &domain.Space{
		Handle:      handle,
		Name:        strings.TrimSpace(input.Name),
		Description: input.Description,
		AvatarURL:   input.AvatarURL,
		CategoryID:  input.CategoryID,
		CreatedBy:   userID,
		MemberCount: 1, // creator is auto-joined
		IsSpicy:     input.IsSpicy,
	}

	err := postgres.WithTx(ctx, s.db, func(tx *sqlx.Tx) error {
		// Insert via the bare repo (it doesn't need the tx handle for the
		// single-row insert; member insert needs tx for atomicity though).
		if err := s.spaceRepo.Create(ctx, space); err != nil {
			return fmt.Errorf("create space: %w", err)
		}
		// The creator is always approved instantly — they're the owner.
		if _, err := s.memberRepo.Add(ctx, tx, space.ID, userID, "owner", "approved"); err != nil {
			return fmt.Errorf("add owner membership: %w", err)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return space, nil
}

func (s *CommunityService) UpdateSpace(ctx context.Context, id, userID uuid.UUID, input domain.UpdateSpaceInput) error {
	if err := s.assertOwner(ctx, id, userID); err != nil {
		return err
	}
	return s.spaceRepo.Update(ctx, id, input)
}

func (s *CommunityService) DeleteSpace(ctx context.Context, id, userID uuid.UUID) error {
	if err := s.assertOwner(ctx, id, userID); err != nil {
		return err
	}
	return s.spaceRepo.Delete(ctx, id)
}

// JoinSpace files a join REQUEST. The user does not become an approved
// member until the space owner accepts. Idempotent — repeat calls while
// pending or already approved are no-ops. Emits a
// `space_join_requested` notification to the space owner.
func (s *CommunityService) JoinSpace(ctx context.Context, spaceID, userID uuid.UUID) error {
	space, err := s.spaceRepo.GetByID(ctx, spaceID, userID)
	if err != nil {
		return err
	}
	if space == nil {
		return ErrSpaceNotFound
	}

	return postgres.WithTx(ctx, s.db, func(tx *sqlx.Tx) error {
		added, err := s.memberRepo.Add(ctx, tx, spaceID, userID, "member", "pending")
		if err != nil {
			return err
		}
		if !added {
			return nil // already requested or already a member
		}
		// member_count is NOT incremented here — pending requests don't
		// count toward the visible member count. ApproveJoinRequest
		// increments it.
		actorID := userID
		_ = s.notifSvc.Emit(ctx, tx, EmitParams{
			RecipientID: space.CreatedBy,
			ActorID:     &actorID,
			Type:        "space_join_requested",
			TargetType:  "space",
			TargetID:    spaceID,
		})
		return nil
	})
}

// ApproveJoinRequest flips a pending request to approved. Only the
// space owner may call this. Increments member_count and notifies the
// requester.
func (s *CommunityService) ApproveJoinRequest(ctx context.Context, spaceID, ownerID, requesterID uuid.UUID) error {
	if err := s.assertOwner(ctx, spaceID, ownerID); err != nil {
		return err
	}
	return postgres.WithTx(ctx, s.db, func(tx *sqlx.Tx) error {
		ok, err := s.memberRepo.Approve(ctx, tx, spaceID, requesterID)
		if err != nil {
			return err
		}
		if !ok {
			// Either no pending request exists or it was already
			// approved. Treat as a no-op so the owner's UI can be
			// optimistic without worrying about double-clicks.
			return nil
		}
		if err := s.spaceRepo.IncrementMemberCount(ctx, tx, spaceID, +1); err != nil {
			return err
		}
		actor := ownerID
		_ = s.notifSvc.Emit(ctx, tx, EmitParams{
			RecipientID: requesterID,
			ActorID:     &actor,
			Type:        "space_join_approved",
			TargetType:  "space",
			TargetID:    spaceID,
		})
		return nil
	})
}

// DeclineJoinRequest drops a pending request. Only the space owner may
// call this. The requester can re-request later — declined rows are
// deleted (not marked rejected) so there's no permanent block.
func (s *CommunityService) DeclineJoinRequest(ctx context.Context, spaceID, ownerID, requesterID uuid.UUID) error {
	if err := s.assertOwner(ctx, spaceID, ownerID); err != nil {
		return err
	}
	return postgres.WithTx(ctx, s.db, func(tx *sqlx.Tx) error {
		ok, err := s.memberRepo.Decline(ctx, tx, spaceID, requesterID)
		if err != nil {
			return err
		}
		if !ok {
			return nil
		}
		actor := ownerID
		_ = s.notifSvc.Emit(ctx, tx, EmitParams{
			RecipientID: requesterID,
			ActorID:     &actor,
			Type:        "space_join_declined",
			TargetType:  "space",
			TargetID:    spaceID,
		})
		return nil
	})
}

// ListJoinRequests returns pending requests for the owner's manage-
// requests screen.
func (s *CommunityService) ListJoinRequests(ctx context.Context, spaceID, ownerID uuid.UUID, limit, offset int) ([]domain.SpaceMember, error) {
	if err := s.assertOwner(ctx, spaceID, ownerID); err != nil {
		return nil, err
	}
	return s.memberRepo.ListPending(ctx, spaceID, limit, offset)
}

// IsApprovedMember is a cheap check used by other services (PostService)
// to gate access to space content.
func (s *CommunityService) IsApprovedMember(ctx context.Context, spaceID, userID uuid.UUID) (bool, error) {
	return s.memberRepo.IsApprovedMember(ctx, spaceID, userID)
}

func (s *CommunityService) LeaveSpace(ctx context.Context, spaceID, userID uuid.UUID) error {
	return postgres.WithTx(ctx, s.db, func(tx *sqlx.Tx) error {
		// Remove deletes regardless of status, so leaving works whether
		// the user was approved or still pending. We only decrement
		// member_count if the removed row was an approved member —
		// otherwise we'd drift negative.
		approved, err := s.memberRepo.IsApprovedMember(ctx, spaceID, userID)
		if err != nil {
			return err
		}
		removed, err := s.memberRepo.Remove(ctx, tx, spaceID, userID)
		if err != nil {
			return err
		}
		if !removed || !approved {
			return nil
		}
		return s.spaceRepo.IncrementMemberCount(ctx, tx, spaceID, -1)
	})
}

func (s *CommunityService) ListMembers(ctx context.Context, spaceID uuid.UUID, limit, offset int) ([]domain.SpaceMember, error) {
	return s.memberRepo.ListBySpace(ctx, spaceID, limit, offset)
}

func (s *CommunityService) ListCategories(ctx context.Context) ([]domain.SpaceCategory, error) {
	return s.catRepo.List(ctx)
}

var ErrUserNotFound = errors.New("user not found")

// GetUserCommunityProfile returns the public community-profile of `targetID`
// (display name + joined spaces + recent posts), with all per-viewer flags
// computed for `currentUserID`.
func (s *CommunityService) GetUserCommunityProfile(ctx context.Context, currentUserID, targetID uuid.UUID) (*domain.UserCommunityProfile, error) {
	user, err := s.userRepo.GetByID(ctx, targetID)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, ErrUserNotFound
	}
	spaces, err := s.spaceRepo.ListByMember(ctx, targetID, currentUserID, 50, 0)
	if err != nil {
		return nil, fmt.Errorf("list joined spaces: %w", err)
	}
	posts, err := s.postRepo.ListByAuthor(ctx, targetID, currentUserID, 20, 0)
	if err != nil {
		return nil, fmt.Errorf("list recent posts: %w", err)
	}
	return &domain.UserCommunityProfile{
		UserID:       user.ID,
		Name:         user.Name,
		JoinedSpaces: spaces,
		RecentPosts:  posts,
	}, nil
}

// assertOwner returns ErrForbidden if user is not the space's creator.
func (s *CommunityService) assertOwner(ctx context.Context, spaceID, userID uuid.UUID) error {
	space, err := s.spaceRepo.GetByID(ctx, spaceID, userID)
	if err != nil {
		return err
	}
	if space == nil {
		return ErrSpaceNotFound
	}
	if space.CreatedBy != userID {
		return ErrForbidden
	}
	return nil
}
