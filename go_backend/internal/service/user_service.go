package service

import (
	"context"
	"fmt"
	"io"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/repository"
	"cosmic-mirror/internal/storage"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

type UserService struct {
	userRepo    repository.UserRepository
	profileRepo repository.BirthProfileRepository
	statsRepo   repository.StatsRepository
	avatars     *storage.AvatarStore
	rdb         *redis.Client
}

func NewUserService(
	userRepo repository.UserRepository,
	profileRepo repository.BirthProfileRepository,
	statsRepo repository.StatsRepository,
	avatars *storage.AvatarStore,
	rdb *redis.Client,
) *UserService {
	return &UserService{
		userRepo:    userRepo,
		profileRepo: profileRepo,
		statsRepo:   statsRepo,
		avatars:     avatars,
		rdb:         rdb,
	}
}

func (s *UserService) CreateOrGetUser(ctx context.Context, firebaseUID, email, name string) (*domain.User, error) {
	existing, err := s.userRepo.GetByFirebaseUID(ctx, firebaseUID)
	if err != nil {
		return nil, fmt.Errorf("get user: %w", err)
	}
	if existing != nil {
		return existing, nil
	}

	user := &domain.User{
		FirebaseUID: firebaseUID,
		Email:       email,
		Name:        name,
	}
	if err := s.userRepo.Create(ctx, user); err != nil {
		return nil, fmt.Errorf("create user: %w", err)
	}
	return user, nil
}

func (s *UserService) GetUser(ctx context.Context, id uuid.UUID) (*domain.User, error) {
	return s.userRepo.GetByID(ctx, id)
}

func (s *UserService) UpdateUser(ctx context.Context, id uuid.UUID, input domain.UpdateUserInput) error {
	return s.userRepo.Update(ctx, id, input)
}

func (s *UserService) DeleteUser(ctx context.Context, id uuid.UUID) error {
	return s.userRepo.SoftDelete(ctx, id)
}

func (s *UserService) CreateBirthProfile(ctx context.Context, userID uuid.UUID, input domain.CreateBirthProfileInput) (*domain.BirthProfile, error) {
	birthDate, err := time.Parse("2006-01-02", input.BirthDate)
	if err != nil {
		return nil, fmt.Errorf("invalid birth_date format: %w", err)
	}

	profile := &domain.BirthProfile{
		UserID:         userID,
		BirthDate:      birthDate,
		BirthTime:      input.BirthTime,
		BirthTimeKnown: input.BirthTimeKnown,
		BirthPlace:     input.BirthPlace,
		Latitude:       input.Latitude,
		Longitude:      input.Longitude,
		Timezone:       input.Timezone,
	}

	if err := s.profileRepo.Create(ctx, profile); err != nil {
		return nil, fmt.Errorf("create birth profile: %w", err)
	}
	return profile, nil
}

func (s *UserService) UpdateBirthProfile(ctx context.Context, userID uuid.UUID, input domain.CreateBirthProfileInput) error {
	if err := s.profileRepo.Update(ctx, userID, input); err != nil {
		return err
	}
	// Birth-data change invalidates every chart we've cached for this
	// user — Western, Vedic (each ayanamsa, each varga, dasha), Human
	// Design. Without this they keep showing yesterday's chart for up
	// to 30 days.
	s.invalidateBirthScopedCaches(ctx, userID)
	return nil
}

// invalidateBirthScopedCaches deletes every Redis key scoped to a single
// user that depends on birth data. Best-effort: any miss is silently
// ignored so a Redis hiccup doesn't break the user's save.
func (s *UserService) invalidateBirthScopedCaches(ctx context.Context, userID uuid.UUID) {
	if s.rdb == nil {
		return
	}
	patterns := []string{
		fmt.Sprintf("chart:%s", userID),
		fmt.Sprintf("hd:%s", userID),
		fmt.Sprintf("vedic:chart:%s:*", userID),
		fmt.Sprintf("vedic:varga:%s:*", userID),
		fmt.Sprintf("vedic:dasha:%s:*", userID),
	}
	for _, pat := range patterns {
		// Plain DEL for fully-qualified keys.
		if !containsGlob(pat) {
			s.rdb.Del(ctx, pat)
			continue
		}
		// SCAN-and-DEL for the wildcard patterns. Iter() handles the
		// cursor for us; we batch deletes in chunks to avoid one big
		// pipeline per user.
		iter := s.rdb.Scan(ctx, 0, pat, 100).Iterator()
		var batch []string
		for iter.Next(ctx) {
			batch = append(batch, iter.Val())
			if len(batch) >= 100 {
				s.rdb.Del(ctx, batch...)
				batch = batch[:0]
			}
		}
		if len(batch) > 0 {
			s.rdb.Del(ctx, batch...)
		}
	}
}

func containsGlob(s string) bool {
	for i := 0; i < len(s); i++ {
		if s[i] == '*' || s[i] == '?' || s[i] == '[' {
			return true
		}
	}
	return false
}

func (s *UserService) GetBirthProfile(ctx context.Context, userID uuid.UUID) (*domain.BirthProfile, error) {
	return s.profileRepo.GetByUserID(ctx, userID)
}

func (s *UserService) HasCompletedOnboarding(ctx context.Context, userID uuid.UUID) bool {
	profile, err := s.profileRepo.GetByUserID(ctx, userID)
	return err == nil && profile != nil
}

// SetAvatar saves the uploaded image to the avatar store and persists the
// resulting public URL on the user row. Returns the new URL.
func (s *UserService) SetAvatar(
	ctx context.Context,
	userID uuid.UUID,
	originalName string,
	src io.Reader,
) (string, error) {
	url, err := s.avatars.SaveAvatar(userID, originalName, src)
	if err != nil {
		return "", fmt.Errorf("save avatar: %w", err)
	}
	if err := s.userRepo.SetAvatarURL(ctx, userID, &url); err != nil {
		return "", fmt.Errorf("update avatar url: %w", err)
	}
	return url, nil
}

// GetStats returns the engagement snapshot rendered on the profile
// stats row (streak / journal entries / AI chats).
func (s *UserService) GetStats(ctx context.Context, userID uuid.UUID) (*domain.UserStats, error) {
	return s.statsRepo.GetStats(ctx, userID)
}

// ClearAvatar deletes the on-disk file and nulls out the user's avatar URL.
func (s *UserService) ClearAvatar(ctx context.Context, userID uuid.UUID) error {
	if err := s.avatars.DeleteAvatar(userID); err != nil {
		return fmt.Errorf("delete avatar: %w", err)
	}
	return s.userRepo.SetAvatarURL(ctx, userID, nil)
}
