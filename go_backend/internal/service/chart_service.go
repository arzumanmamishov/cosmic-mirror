package service

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/provider/openai"
	"cosmic-mirror/internal/provider/swisseph"
	"cosmic-mirror/internal/repository"
	"cosmic-mirror/internal/tz"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

// ChartProvider is the abstraction over any astronomical calculation engine
// (Swiss Ephemeris, AstrologyAPI, etc). It returns a complete natal chart for
// the given birth data. Implementations are expected to be thread-safe.
type ChartProvider interface {
	GetNatalChart(
		ctx context.Context,
		birthDate time.Time,
		birthHour, birthMin int,
		lat, lon, tzone float64,
	) (*domain.NatalChart, error)
}

type ChartService struct {
	profileRepo repository.BirthProfileRepository
	provider    ChartProvider
	aiClient    *openai.Client
	rdb         *redis.Client
}

func NewChartService(
	profileRepo repository.BirthProfileRepository,
	provider ChartProvider,
	aiClient *openai.Client,
	rdb *redis.Client,
) *ChartService {
	return &ChartService{profileRepo: profileRepo, provider: provider, aiClient: aiClient, rdb: rdb}
}

func (s *ChartService) GetNatalChart(ctx context.Context, userID uuid.UUID) (*domain.NatalChart, error) {
	// Check cache
	cacheKey := fmt.Sprintf("chart:%s", userID)
	cached, err := s.rdb.Get(ctx, cacheKey).Bytes()
	if err == nil {
		var chart domain.NatalChart
		if json.Unmarshal(cached, &chart) == nil {
			return &chart, nil
		}
	}

	profile, err := s.profileRepo.GetByUserID(ctx, userID)
	if err != nil || profile == nil {
		return nil, fmt.Errorf("birth profile not found")
	}

	// Parse birth time (default to noon if unknown)
	hour, min := 12, 0
	if profile.BirthTimeKnown && profile.BirthTime != nil {
		hour, min = parseBirthTime(*profile.BirthTime)
	}

	// Calculate timezone offset AT the birth instant — this picks up the
	// historical rules (Soviet decree time, DST changes, wartime offsets)
	// that "now" lookups would miss.
	tzone := tz.OffsetForBirth(profile.Timezone, profile.BirthDate, hour, min)

	// Fetch chart from the configured calculation provider
	chart, err := s.provider.GetNatalChart(
		ctx,
		profile.BirthDate,
		hour, min,
		profile.Latitude, profile.Longitude,
		tzone,
	)
	if err != nil {
		// Fall back to cached raw chart data if API fails
		if profile.RawChartData != nil {
			var fallback domain.NatalChart
			if json.Unmarshal(*profile.RawChartData, &fallback) == nil {
				return &fallback, nil
			}
		}
		return nil, fmt.Errorf("failed to fetch chart: %w", err)
	}

	// Cache for 7 days (natal chart doesn't change)
	if data, err := json.Marshal(chart); err == nil {
		s.rdb.Set(ctx, cacheKey, data, 7*24*time.Hour)
	}

	return chart, nil
}

func (s *ChartService) GetChartSummary(ctx context.Context, userID uuid.UUID) (*domain.ChartSummary, error) {
	chart, err := s.GetNatalChart(ctx, userID)
	if err != nil {
		return nil, err
	}

	summary := &domain.ChartSummary{}
	for _, p := range chart.Planets {
		switch p.Name {
		case "Sun":
			summary.SunSign = p.Sign
			summary.SunDescription = sunDescription(p.Sign)
		case "Moon":
			summary.MoonSign = p.Sign
			summary.MoonDescription = moonDescription(p.Sign)
		}
	}

	// Rising sign from first house
	if len(chart.Houses) > 0 {
		summary.RisingSign = chart.Houses[0].Sign
		summary.RisingDescription = risingDescription(chart.Houses[0].Sign)
	}

	return summary, nil
}

// GetTimeline returns a transit-grounded forecast for the requested window.
// forecastType is one of "30d", "3m", "12m"; anything else falls back to 30d.
// We compute REAL transit events via Swiss Ephemeris, then ask the model to
// write narrative around them — the model never invents dates or aspects.
func (s *ChartService) GetTimeline(ctx context.Context, userID uuid.UUID, forecastType string) (*domain.TimelineForecast, error) {
	chart, err := s.GetNatalChart(ctx, userID)
	if err != nil {
		return nil, err
	}

	now := time.Now().UTC()
	var end time.Time
	switch forecastType {
	case "3m":
		end = now.AddDate(0, 3, 0)
	case "12m":
		end = now.AddDate(1, 0, 0)
	case "30d":
		fallthrough
	default:
		forecastType = "30d"
		end = now.AddDate(0, 0, 30)
	}

	// Day-by-day Swiss Ephemeris pass. For the year window this is 365 daily
	// position calculations × 11 bodies = ~4000 cgo calls — fine: takes a
	// couple seconds on the API container, and we cache the result.
	cacheKey := fmt.Sprintf("timeline:%s:%s:%s", userID, forecastType, now.Format("2006-01-02"))
	if cached, err := s.rdb.Get(ctx, cacheKey).Bytes(); err == nil {
		var hit domain.TimelineForecast
		if json.Unmarshal(cached, &hit) == nil {
			return &hit, nil
		}
	}

	events, err := swisseph.ComputeTransitEvents(chart, now, end)
	if err != nil {
		return nil, fmt.Errorf("compute transits: %w", err)
	}

	profile, err := s.profileRepo.GetByUserID(ctx, userID)
	if err != nil || profile == nil {
		return nil, fmt.Errorf("birth profile not found")
	}

	lite := transitEventsToLite(events)
	prompt := openai.BuildTimelinePrompt(profile, forecastType, lite, now, end)
	resp, err := s.aiClient.ChatCompletionJSON(ctx, prompt)
	if err != nil {
		return nil, fmt.Errorf("ai timeline: %w", err)
	}

	var parsed struct {
		Periods []domain.ForecastPeriod `json:"periods"`
	}
	if err := json.Unmarshal([]byte(resp), &parsed); err != nil {
		return nil, fmt.Errorf("parse timeline: %w", err)
	}

	out := &domain.TimelineForecast{
		Type:    forecastType,
		Periods: parsed.Periods,
	}

	if data, err := json.Marshal(out); err == nil {
		// Cache for 24h: transits don't change but the LLM rewrite is the
		// expensive part.
		s.rdb.Set(ctx, cacheKey, data, 24*time.Hour)
	}

	return out, nil
}

// GetYearlyForecast returns a 4-quarter narrative for the given calendar year,
// grounded in Swiss-Ephemeris-computed transits. Like GetTimeline, the model
// is given the real event list and instructed to write only around it.
func (s *ChartService) GetYearlyForecast(ctx context.Context, userID uuid.UUID, year int) (*domain.YearlyForecast, error) {
	chart, err := s.GetNatalChart(ctx, userID)
	if err != nil {
		return nil, err
	}

	cacheKey := fmt.Sprintf("yearly:%s:%d", userID, year)
	if cached, err := s.rdb.Get(ctx, cacheKey).Bytes(); err == nil {
		var hit domain.YearlyForecast
		if json.Unmarshal(cached, &hit) == nil {
			return &hit, nil
		}
	}

	start := time.Date(year, 1, 1, 0, 0, 0, 0, time.UTC)
	end := time.Date(year+1, 1, 1, 0, 0, 0, 0, time.UTC)
	events, err := swisseph.ComputeTransitEvents(chart, start, end)
	if err != nil {
		return nil, fmt.Errorf("compute transits: %w", err)
	}

	profile, err := s.profileRepo.GetByUserID(ctx, userID)
	if err != nil || profile == nil {
		return nil, fmt.Errorf("birth profile not found")
	}

	lite := transitEventsToLite(events)
	prompt := openai.BuildYearlyForecastPrompt(profile, year, lite)
	resp, err := s.aiClient.ChatCompletionJSON(ctx, prompt)
	if err != nil {
		return nil, fmt.Errorf("ai yearly: %w", err)
	}

	var parsed struct {
		Theme    string                   `json:"theme"`
		Overview string                   `json:"overview"`
		Quarters []domain.QuarterForecast `json:"quarters"`
	}
	if err := json.Unmarshal([]byte(resp), &parsed); err != nil {
		return nil, fmt.Errorf("parse yearly: %w", err)
	}

	out := &domain.YearlyForecast{
		Year:     year,
		Theme:    parsed.Theme,
		Overview: parsed.Overview,
		Quarters: parsed.Quarters,
	}

	if data, err := json.Marshal(out); err == nil {
		// 7d cache: yearly transits are stable but rerunning the LLM every
		// page load would burn tokens for no benefit.
		s.rdb.Set(ctx, cacheKey, data, 7*24*time.Hour)
	}

	return out, nil
}

// transitEventsToLite converts the swisseph package's event type into the
// flat string-only structure prompts.go consumes, so that prompts.go does not
// take a dependency on the provider package.
func transitEventsToLite(events []swisseph.TransitEvent) []openai.TransitEventLite {
	out := make([]openai.TransitEventLite, 0, len(events))
	for _, e := range events {
		out = append(out, openai.TransitEventLite{
			Date:        e.Date.Format("2006-01-02"),
			Type:        e.Type,
			Body:        e.Body,
			NatalPoint:  e.NatalPoint,
			Aspect:      e.Aspect,
			Sign:        e.Sign,
			Phase:       e.Phase,
			Description: e.Description,
		})
	}
	return out
}

// parseBirthTime parses "HH:MM" format into hour and minute.
func parseBirthTime(t string) (int, int) {
	parts := strings.Split(t, ":")
	if len(parts) != 2 {
		return 12, 0
	}
	h, err1 := strconv.Atoi(parts[0])
	m, err2 := strconv.Atoi(parts[1])
	if err1 != nil || err2 != nil {
		return 12, 0
	}
	return h, m
}


func sunDescription(sign string) string {
	descriptions := map[string]string{
		"Aries":       "Bold, pioneering, and full of initiative. You lead with courage.",
		"Taurus":      "Steady, sensual, and determined. You build lasting value.",
		"Gemini":      "Curious, versatile, and communicative. You connect ideas and people.",
		"Cancer":      "Nurturing, intuitive, and deeply emotional. You protect what matters.",
		"Leo":         "Radiant, generous, and creative. You inspire others naturally.",
		"Virgo":       "Analytical, dedicated, and practical. You refine everything you touch.",
		"Libra":       "Harmonious, fair, and relationship-oriented. You seek balance.",
		"Scorpio":     "Intense, transformative, and perceptive. You see beneath surfaces.",
		"Sagittarius": "Adventurous, philosophical, and optimistic. You expand horizons.",
		"Capricorn":   "Ambitious, disciplined, and strategic. You build toward mastery.",
		"Aquarius":    "Innovative, independent, and humanitarian. You envision the future.",
		"Pisces":      "Empathic, creative, and spiritually attuned. You feel deeply.",
	}
	return descriptions[sign]
}

func moonDescription(sign string) string {
	descriptions := map[string]string{
		"Aries":       "Your emotions are direct and fiery. You need action to process feelings.",
		"Taurus":      "Your emotions crave comfort and stability. You find peace in routine.",
		"Gemini":      "Your emotions shift quickly. You process feelings through conversation.",
		"Cancer":      "Your emotions run deep and nurturing. Home is your sanctuary.",
		"Leo":         "Your emotions are warm and dramatic. You need to feel appreciated.",
		"Virgo":       "Your emotions seek order. You process feelings through helpful action.",
		"Libra":       "Your emotions seek harmony. You need balanced relationships.",
		"Scorpio":     "Your emotions are intense and private. You feel everything deeply.",
		"Sagittarius": "Your emotions are optimistic and restless. You need freedom to feel.",
		"Capricorn":   "Your emotions are controlled and resilient. You mature through challenges.",
		"Aquarius":    "Your emotions are detached yet caring. You process through ideas.",
		"Pisces":      "Your emotions are boundless and compassionate. You absorb others' feelings.",
	}
	return descriptions[sign]
}

func risingDescription(sign string) string {
	descriptions := map[string]string{
		"Aries":       "You come across as confident and energetic. First impressions are bold.",
		"Taurus":      "You come across as calm and grounded. First impressions are reassuring.",
		"Gemini":      "You come across as witty and engaging. First impressions are lively.",
		"Cancer":      "You come across as warm and approachable. First impressions are caring.",
		"Leo":         "You come across as magnetic and confident. First impressions are memorable.",
		"Virgo":       "You come across as thoughtful and composed. First impressions are polished.",
		"Libra":       "You come across as charming and diplomatic. First impressions are graceful.",
		"Scorpio":     "You come across as mysterious and intense. First impressions are powerful.",
		"Sagittarius": "You come across as enthusiastic and open. First impressions are inspiring.",
		"Capricorn":   "You come across as composed and authoritative. First impressions are strong.",
		"Aquarius":    "You come across as unique and progressive. First impressions are intriguing.",
		"Pisces":      "You come across as gentle and dreamy. First impressions are ethereal.",
	}
	return descriptions[sign]
}
