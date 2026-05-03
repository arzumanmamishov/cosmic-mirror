package service

import (
	"context"
	"errors"
	"fmt"
	"regexp"
	"strings"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/repository/postgres"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

// CommunityService owns spaces + memberships + categories. Posts/comments
// live in their own services to keep this file focused.
type CommunityService struct {
	db        *sqlx.DB
	spaceRepo *postgres.SpaceRepository
	memberRepo *postgres.SpaceMemberRepository
	catRepo   *postgres.SpaceCategoryRepository
	notifSvc  *CommunityNotificationService
}

func NewCommunityService(
	db *sqlx.DB,
	spaceRepo *postgres.SpaceRepository,
	memberRepo *postgres.SpaceMemberRepository,
	catRepo *postgres.SpaceCategoryRepository,
	notifSvc *CommunityNotificationService,
) *CommunityService {
	return &CommunityService{
		db: db, spaceRepo: spaceRepo, memberRepo: memberRepo,
		catRepo: catRepo, notifSvc: notifSvc,
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
		if _, err := s.memberRepo.Add(ctx, tx, space.ID, userID, "owner"); err != nil {
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

// JoinSpace makes user a member. Idempotent — no-op if already joined.
// Emits a `space_member_joined` notification to the space owner.
func (s *CommunityService) JoinSpace(ctx context.Context, spaceID, userID uuid.UUID) error {
	space, err := s.spaceRepo.GetByID(ctx, spaceID, userID)
	if err != nil {
		return err
	}
	if space == nil {
		return ErrSpaceNotFound
	}

	return postgres.WithTx(ctx, s.db, func(tx *sqlx.Tx) error {
		added, err := s.memberRepo.Add(ctx, tx, spaceID, userID, "member")
		if err != nil {
			return err
		}
		if !added {
			return nil // already a member
		}
		if err := s.spaceRepo.IncrementMemberCount(ctx, tx, spaceID, +1); err != nil {
			return err
		}
		actorID := userID
		_ = s.notifSvc.Emit(ctx, tx, EmitParams{
			RecipientID: space.CreatedBy,
			ActorID:     &actorID,
			Type:        "space_member_joined",
			TargetType:  "space",
			TargetID:    spaceID,
		})
		return nil
	})
}

func (s *CommunityService) LeaveSpace(ctx context.Context, spaceID, userID uuid.UUID) error {
	return postgres.WithTx(ctx, s.db, func(tx *sqlx.Tx) error {
		removed, err := s.memberRepo.Remove(ctx, tx, spaceID, userID)
		if err != nil {
			return err
		}
		if !removed {
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
