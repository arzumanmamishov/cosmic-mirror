package service

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"math"
	"strings"
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

	// Account-deletion collaborators (see WithAccountDeletion).
	refreshTokens repository.RefreshTokenRepository
	subCanceller  SubscriptionCanceller
}

// SubscriptionCanceller immediately terminates a user's paid subscription.
// Implemented by *StripeService; injected as an interface because the
// Stripe service itself depends on UserService.
type SubscriptionCanceller interface {
	CancelImmediately(ctx context.Context, userID uuid.UUID) error
}

// WithAccountDeletion wires what DeleteUser needs beyond the user row:
// the refresh-token store (to end every session) and the subscription
// canceller (so a deleted account is never billed again). Either may be
// nil, in which case that step is skipped.
func (s *UserService) WithAccountDeletion(refreshTokens repository.RefreshTokenRepository, subs SubscriptionCanceller) *UserService {
	s.refreshTokens = refreshTokens
	s.subCanceller = subs
	return s
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

// DeleteUser deletes the caller's account: cancels any Stripe subscription
// immediately, revokes every refresh token, then soft-deletes the user (the
// cleanup worker hard-deletes the row and avatar files after 30 days).
//
// Order matters. Every step is idempotent and the caller's access token
// keeps working until the soft delete, so any failure is returned and the
// client can simply retry the DELETE. The Stripe cancel runs first and a
// failure aborts the deletion: soft-deleting first would lock the user out
// (auth rejects deleted users) while Stripe kept billing them, with no way
// to retry from the app.
func (s *UserService) DeleteUser(ctx context.Context, id uuid.UUID) error {
	if s.subCanceller != nil {
		if err := s.subCanceller.CancelImmediately(ctx, id); err != nil {
			slog.Error("account deletion: cancel subscription failed", "user_id", id, "error", err)
			return fmt.Errorf("cancel subscription: %w", err)
		}
	}
	if s.refreshTokens != nil {
		if err := s.refreshTokens.RevokeAllForUser(ctx, id); err != nil {
			return fmt.Errorf("revoke sessions: %w", err)
		}
	}
	if err := s.userRepo.SoftDelete(ctx, id); err != nil {
		return fmt.Errorf("soft delete user: %w", err)
	}
	return nil
}

// validateBirthData checks the user-supplied birth fields shared by birth
// profiles and saved people, returning the parsed birth date. Failures
// wrap domain.ErrValidation (handlers map that to 400).
func validateBirthData(birthDate string, lat, lon float64, timezone string) (time.Time, error) {
	d, err := time.Parse("2006-01-02", strings.TrimSpace(birthDate))
	if err != nil {
		return time.Time{}, fmt.Errorf("%w: birth_date must be YYYY-MM-DD", domain.ErrValidation)
	}
	// Allow "today" in any timezone: compare against tomorrow UTC.
	if d.After(time.Now().UTC().AddDate(0, 0, 1)) {
		return time.Time{}, fmt.Errorf("%w: birth_date cannot be in the future", domain.ErrValidation)
	}
	if d.Year() < 1800 {
		return time.Time{}, fmt.Errorf("%w: birth_date is too far in the past", domain.ErrValidation)
	}
	if math.IsNaN(lat) || lat < -90 || lat > 90 {
		return time.Time{}, fmt.Errorf("%w: latitude must be between -90 and 90", domain.ErrValidation)
	}
	if math.IsNaN(lon) || lon < -180 || lon > 180 {
		return time.Time{}, fmt.Errorf("%w: longitude must be between -180 and 180", domain.ErrValidation)
	}
	tz := strings.TrimSpace(timezone)
	if tz == "" {
		return time.Time{}, fmt.Errorf("%w: timezone is required", domain.ErrValidation)
	}
	if _, err := time.LoadLocation(tz); err != nil {
		return time.Time{}, fmt.Errorf("%w: unknown timezone %q", domain.ErrValidation, tz)
	}
	return d, nil
}

func (s *UserService) CreateBirthProfile(ctx context.Context, userID uuid.UUID, input domain.CreateBirthProfileInput) (*domain.BirthProfile, error) {
	birthDate, err := validateBirthData(input.BirthDate, input.Latitude, input.Longitude, input.Timezone)
	if err != nil {
		return nil, err
	}

	profile := &domain.BirthProfile{
		UserID:         userID,
		BirthDate:      birthDate,
		BirthTime:      input.BirthTime,
		BirthTimeKnown: input.BirthTimeKnown,
		BirthPlace:     input.BirthPlace,
		Latitude:       input.Latitude,
		Longitude:      input.Longitude,
		Timezone:       strings.TrimSpace(input.Timezone),
	}

	if err := s.profileRepo.Create(ctx, profile); err != nil {
		return nil, fmt.Errorf("create birth profile: %w", err)
	}
	// Create upserts, so this may have overwritten existing birth data.
	s.invalidateBirthScopedCaches(ctx, userID)
	return profile, nil
}

// UpdateBirthProfile replaces the user's birth data. It upserts: a user
// without a profile row yet (e.g. onboarding was skipped or interrupted)
// gets one created instead of the update silently matching zero rows.
func (s *UserService) UpdateBirthProfile(ctx context.Context, userID uuid.UUID, input domain.CreateBirthProfileInput) error {
	// CreateBirthProfile validates, upserts on user_id, and invalidates
	// every cached chart for this user — Western, Vedic (each ayanamsa,
	// each varga, dasha), Human Design, timeline/yearly forecasts.
	_, err := s.CreateBirthProfile(ctx, userID, input)
	return err
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
		// Forecasts are computed from natal positions:
		// timeline:{uid}:{type}:{date}:{lang} and yearly:{uid}:{year}:{lang}.
		fmt.Sprintf("timeline:%s:*", userID),
		fmt.Sprintf("yearly:%s:*", userID),
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
