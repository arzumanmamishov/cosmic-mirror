package service

import (
	"context"
	"fmt"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
)

type UserService struct {
	userRepo    repository.UserRepository
	profileRepo repository.BirthProfileRepository
}

func NewUserService(userRepo repository.UserRepository, profileRepo repository.BirthProfileRepository) *UserService {
	return &UserService{userRepo: userRepo, profileRepo: profileRepo}
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
	profile := &domain.BirthProfile{
		UserID:         userID,
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

func (s *UserService) GetBirthProfile(ctx context.Context, userID uuid.UUID) (*domain.BirthProfile, error) {
	return s.profileRepo.GetByUserID(ctx, userID)
}

func (s *UserService) HasCompletedOnboarding(ctx context.Context, userID uuid.UUID) bool {
	profile, err := s.profileRepo.GetByUserID(ctx, userID)
	return err == nil && profile != nil
}
