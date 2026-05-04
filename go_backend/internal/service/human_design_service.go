package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

// HumanDesignProvider abstracts the underlying calculation engine. Today
// only `swisseph.Client` implements it.
type HumanDesignProvider interface {
	GetHumanDesign(
		ctx context.Context,
		birthDate time.Time,
		birthHour, birthMin int,
		lat, lon, tzone float64,
	) (*domain.HumanDesignChart, error)
}

type HumanDesignService struct {
	profileRepo repository.BirthProfileRepository
	provider    HumanDesignProvider
	rdb         *redis.Client
}

func NewHumanDesignService(profileRepo repository.BirthProfileRepository, provider HumanDesignProvider, rdb *redis.Client) *HumanDesignService {
	return &HumanDesignService{profileRepo: profileRepo, provider: provider, rdb: rdb}
}

var (
	ErrHDMissingProfile = errors.New("birth profile is required for a human design chart")
	ErrHDMissingTime    = errors.New("birth time is required for a human design chart (it changes minute by minute)")
)

// GetChart returns the cached chart if available; otherwise computes fresh
// and caches for 30 days (HD is fully deterministic from birth data).
func (s *HumanDesignService) GetChart(ctx context.Context, userID uuid.UUID) (*domain.HumanDesignChart, error) {
	profile, err := s.profileRepo.GetByUserID(ctx, userID)
	if err != nil || profile == nil {
		return nil, ErrHDMissingProfile
	}
	if !profile.BirthTimeKnown || profile.BirthTime == nil {
		return nil, ErrHDMissingTime
	}

	cacheKey := fmt.Sprintf("hd:%s", userID)
	if cached, err := s.rdb.Get(ctx, cacheKey).Bytes(); err == nil {
		var chart domain.HumanDesignChart
		if json.Unmarshal(cached, &chart) == nil {
			return &chart, nil
		}
	}

	hour, min := parseBirthTime(*profile.BirthTime)
	tzone := timezoneOffset(profile.Timezone)

	chart, err := s.provider.GetHumanDesign(
		ctx,
		profile.BirthDate, hour, min,
		profile.Latitude, profile.Longitude, tzone,
	)
	if err != nil {
		return nil, fmt.Errorf("hd compute: %w", err)
	}
	if data, err := json.Marshal(chart); err == nil {
		s.rdb.Set(ctx, cacheKey, data, 30*24*time.Hour)
	}
	return chart, nil
}
