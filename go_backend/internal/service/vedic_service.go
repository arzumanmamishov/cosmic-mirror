package service

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

// VedicProvider abstracts the underlying Jyotish calculation engine. The only
// implementation today is the Swiss Ephemeris client (`swisseph.Client`), but
// keeping the interface allows alternate engines (e.g. test stubs) without
// touching the service layer.
type VedicProvider interface {
	GetVedicChart(
		ctx context.Context,
		birthDate time.Time,
		birthHour, birthMin int,
		lat, lon, tzone float64,
		ayanamsa int,
	) (*domain.VedicChart, error)

	GetDivisionalChart(
		ctx context.Context,
		birthDate time.Time,
		birthHour, birthMin int,
		lat, lon, tzone float64,
		ayanamsa, divisor int,
	) (*domain.VedicChart, error)

	ComputeDasha(
		ctx context.Context,
		birthDate time.Time,
		birthHour, birthMin int,
		lat, lon, tzone float64,
		ayanamsa, levels int,
	) (*domain.DashaTree, error)

	ComputeYogas(chart *domain.VedicChart) []domain.VedicYoga
	ComputeShadbala(chart *domain.VedicChart, jdUT float64) map[string]domain.ShadbalaBreakdown
	ComputeAshtakavarga(chart *domain.VedicChart) *domain.Ashtakavarga
}

type VedicService struct {
	profileRepo repository.BirthProfileRepository
	provider    VedicProvider
	rdb         *redis.Client
}

func NewVedicService(profileRepo repository.BirthProfileRepository, provider VedicProvider, rdb *redis.Client) *VedicService {
	return &VedicService{profileRepo: profileRepo, provider: provider, rdb: rdb}
}

// AyanamsaFromString accepts the same strings the API does and normalizes to a
// swephgo SE_SIDM_* constant. Defaults to Lahiri.
func AyanamsaFromString(s string) int {
	switch s {
	case "fagan", "fagan-bradley", "fagan_bradley":
		return 0
	case "raman":
		return 3
	case "krishnamurti", "kp":
		return 5
	case "", "lahiri":
		return 1
	default:
		return 1
	}
}

func (s *VedicService) loadBirthData(ctx context.Context, userID uuid.UUID) (time.Time, int, int, float64, float64, float64, error) {
	profile, err := s.profileRepo.GetByUserID(ctx, userID)
	if err != nil || profile == nil {
		return time.Time{}, 0, 0, 0, 0, 0, fmt.Errorf("birth profile not found")
	}
	hour, min := 12, 0
	if profile.BirthTimeKnown && profile.BirthTime != nil {
		hour, min = parseBirthTime(*profile.BirthTime)
	}
	tzone := timezoneOffset(profile.Timezone)
	return profile.BirthDate, hour, min, profile.Latitude, profile.Longitude, tzone, nil
}

// GetVedicChart returns the Rasi (D1) chart for a user.
func (s *VedicService) GetVedicChart(ctx context.Context, userID uuid.UUID, ayanamsaStr string) (*domain.VedicChart, error) {
	ayanamsa := AyanamsaFromString(ayanamsaStr)
	cacheKey := fmt.Sprintf("vedic:chart:%s:%d", userID, ayanamsa)
	if cached, err := s.rdb.Get(ctx, cacheKey).Bytes(); err == nil {
		var chart domain.VedicChart
		if json.Unmarshal(cached, &chart) == nil {
			return &chart, nil
		}
	}

	birthDate, hour, min, lat, lon, tzone, err := s.loadBirthData(ctx, userID)
	if err != nil {
		return nil, err
	}

	chart, err := s.provider.GetVedicChart(ctx, birthDate, hour, min, lat, lon, tzone, ayanamsa)
	if err != nil {
		return nil, fmt.Errorf("failed to compute vedic chart: %w", err)
	}

	if data, err := json.Marshal(chart); err == nil {
		s.rdb.Set(ctx, cacheKey, data, 7*24*time.Hour)
	}
	return chart, nil
}

// GetDivisionalChart returns one of the Shodashvarga divisional charts (D2..D60).
func (s *VedicService) GetDivisionalChart(ctx context.Context, userID uuid.UUID, ayanamsaStr string, divisor int) (*domain.VedicChart, error) {
	ayanamsa := AyanamsaFromString(ayanamsaStr)
	cacheKey := fmt.Sprintf("vedic:varga:%s:%d:%d", userID, ayanamsa, divisor)
	if cached, err := s.rdb.Get(ctx, cacheKey).Bytes(); err == nil {
		var chart domain.VedicChart
		if json.Unmarshal(cached, &chart) == nil {
			return &chart, nil
		}
	}

	birthDate, hour, min, lat, lon, tzone, err := s.loadBirthData(ctx, userID)
	if err != nil {
		return nil, err
	}

	chart, err := s.provider.GetDivisionalChart(ctx, birthDate, hour, min, lat, lon, tzone, ayanamsa, divisor)
	if err != nil {
		return nil, fmt.Errorf("failed to compute divisional chart D%d: %w", divisor, err)
	}

	if data, err := json.Marshal(chart); err == nil {
		s.rdb.Set(ctx, cacheKey, data, 7*24*time.Hour)
	}
	return chart, nil
}

// GetDasha returns the Vimshottari dasha tree. levels in {1,2,3}.
func (s *VedicService) GetDasha(ctx context.Context, userID uuid.UUID, ayanamsaStr string, levels int) (*domain.DashaTree, error) {
	if levels < 1 || levels > 3 {
		levels = 3
	}
	ayanamsa := AyanamsaFromString(ayanamsaStr)
	cacheKey := fmt.Sprintf("vedic:dasha:%s:%d:%d", userID, ayanamsa, levels)
	if cached, err := s.rdb.Get(ctx, cacheKey).Bytes(); err == nil {
		var tree domain.DashaTree
		if json.Unmarshal(cached, &tree) == nil {
			// Recompute current path because "now" moved since cache.
			tree.Current = currentDashaPath(tree.Mahadashas, time.Now())
			return &tree, nil
		}
	}

	birthDate, hour, min, lat, lon, tzone, err := s.loadBirthData(ctx, userID)
	if err != nil {
		return nil, err
	}

	tree, err := s.provider.ComputeDasha(ctx, birthDate, hour, min, lat, lon, tzone, ayanamsa, levels)
	if err != nil {
		return nil, fmt.Errorf("failed to compute dasha: %w", err)
	}

	if data, err := json.Marshal(tree); err == nil {
		// Dasha is fully deterministic from birth — cache 30 days.
		s.rdb.Set(ctx, cacheKey, data, 30*24*time.Hour)
	}
	return tree, nil
}

// GetYogas returns the active classical yogas for the chart.
func (s *VedicService) GetYogas(ctx context.Context, userID uuid.UUID, ayanamsaStr string) ([]domain.VedicYoga, error) {
	chart, err := s.GetVedicChart(ctx, userID, ayanamsaStr)
	if err != nil {
		return nil, err
	}
	return s.provider.ComputeYogas(chart), nil
}

// GetShadbala returns six-fold strength per planet.
func (s *VedicService) GetShadbala(ctx context.Context, userID uuid.UUID, ayanamsaStr string) (map[string]domain.ShadbalaBreakdown, error) {
	chart, err := s.GetVedicChart(ctx, userID, ayanamsaStr)
	if err != nil {
		return nil, err
	}
	// Shadbala needs jdUT for several Bala components. Compute it.
	birthDate, hour, min, _, _, tzone, err := s.loadBirthData(ctx, userID)
	if err != nil {
		return nil, err
	}
	hourLocal := float64(hour) + float64(min)/60.0
	hourUT := hourLocal - tzone
	jdUT := julianDayUT(birthDate, hourUT)
	return s.provider.ComputeShadbala(chart, jdUT), nil
}

// GetAshtakavarga returns the bindu (benefic point) tables.
func (s *VedicService) GetAshtakavarga(ctx context.Context, userID uuid.UUID, ayanamsaStr string) (*domain.Ashtakavarga, error) {
	chart, err := s.GetVedicChart(ctx, userID, ayanamsaStr)
	if err != nil {
		return nil, err
	}
	return s.provider.ComputeAshtakavarga(chart), nil
}

// julianDayUT computes a Julian Day for a UT-adjusted hour without going
// through swephgo (which would require cgo). The formula is the standard
// Gregorian calendar conversion.
func julianDayUT(date time.Time, hourUT float64) float64 {
	y := date.Year()
	m := int(date.Month())
	d := date.Day()
	if m <= 2 {
		y--
		m += 12
	}
	a := y / 100
	b := 2 - a + a/4
	jd := float64(int(365.25*float64(y+4716))) + float64(int(30.6001*float64(m+1))) + float64(d) + float64(b) - 1524.5
	jd += hourUT / 24
	return jd
}

// currentDashaPath walks the tree to find which maha/antar/pratyantar contains
// the given moment.
func currentDashaPath(mahadashas []domain.DashaPeriod, at time.Time) domain.DashaPath {
	path := domain.DashaPath{At: at}
	for _, m := range mahadashas {
		if !at.Before(m.StartDate) && at.Before(m.EndDate) {
			path.Maha = m.Lord
			for _, a := range m.Sub {
				if !at.Before(a.StartDate) && at.Before(a.EndDate) {
					path.Antar = a.Lord
					for _, p := range a.Sub {
						if !at.Before(p.StartDate) && at.Before(p.EndDate) {
							path.Pratyantar = p.Lord
							return path
						}
					}
					return path
				}
			}
			return path
		}
	}
	return path
}
