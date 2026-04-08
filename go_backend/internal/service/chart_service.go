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

type ChartService struct {
	profileRepo repository.BirthProfileRepository
	rdb         *redis.Client
}

func NewChartService(profileRepo repository.BirthProfileRepository, rdb *redis.Client) *ChartService {
	return &ChartService{profileRepo: profileRepo, rdb: rdb}
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

	// In production: call astrology API here
	// For now, return data from cached raw chart data if available
	if profile.RawChartData != nil {
		var chart domain.NatalChart
		if err := json.Unmarshal(*profile.RawChartData, &chart); err == nil {
			// Cache for 7 days
			if data, err := json.Marshal(chart); err == nil {
				s.rdb.Set(ctx, cacheKey, data, 7*24*time.Hour)
			}
			return &chart, nil
		}
	}

	return nil, fmt.Errorf("chart data not available, astrology provider integration needed")
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
