package service

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/provider/openai"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

type ReadingService struct {
	readingRepo repository.DailyReadingRepository
	profileRepo repository.BirthProfileRepository
	aiClient    *openai.Client
	rdb         *redis.Client
}

func NewReadingService(
	readingRepo repository.DailyReadingRepository,
	profileRepo repository.BirthProfileRepository,
	aiClient *openai.Client,
	rdb *redis.Client,
) *ReadingService {
	return &ReadingService{
		readingRepo: readingRepo,
		profileRepo: profileRepo,
		aiClient:    aiClient,
		rdb:         rdb,
	}
}

func (s *ReadingService) GetDailyReading(ctx context.Context, userID uuid.UUID, date time.Time) (*domain.DailyReading, error) {
	// Check DB first
	existing, err := s.readingRepo.GetByUserAndDate(ctx, userID, date)
	if err != nil {
		return nil, fmt.Errorf("get reading from db: %w", err)
	}
	if existing != nil {
		return existing, nil
	}

	// Check Redis cache
	cacheKey := fmt.Sprintf("reading:%s:%s", userID, date.Format("2006-01-02"))
	cached, err := s.rdb.Get(ctx, cacheKey).Bytes()
	if err == nil {
		var reading domain.DailyReading
		if json.Unmarshal(cached, &reading) == nil {
			return &reading, nil
		}
	}

	// Generate via AI
	reading, err := s.generateReading(ctx, userID, date)
	if err != nil {
		return nil, fmt.Errorf("generate reading: %w", err)
	}

	// Store in DB
	if err := s.readingRepo.Create(ctx, reading); err != nil {
		slog.Error("failed to store reading", "error", err, "user_id", userID)
	}

	// Cache in Redis for 24h
	if data, err := json.Marshal(reading); err == nil {
		s.rdb.Set(ctx, cacheKey, data, 24*time.Hour)
	}

	return reading, nil
}

func (s *ReadingService) generateReading(ctx context.Context, userID uuid.UUID, date time.Time) (*domain.DailyReading, error) {
	profile, err := s.profileRepo.GetByUserID(ctx, userID)
	if err != nil || profile == nil {
		return nil, fmt.Errorf("birth profile not found for user %s", userID)
	}

	prompt := openai.BuildDailyReadingPrompt(profile, date)
	response, err := s.aiClient.ChatCompletionJSON(ctx, prompt)
	if err != nil {
		return nil, fmt.Errorf("AI generation failed: %w", err)
	}

	var aiResp domain.DailyReadingAIResponse
	if err := json.Unmarshal([]byte(response), &aiResp); err != nil {
		return nil, fmt.Errorf("parse AI response: %w", err)
	}

	reading := &domain.DailyReading{
		UserID:      userID,
		ReadingDate: date,
		EnergyLevel: aiResp.EnergyLevel,
		Emotional:   aiResp.Emotional,
		Love:        aiResp.Love,
		Career:      aiResp.Career,
		Health:      aiResp.Health,
		Caution:     aiResp.Caution,
		Action:      aiResp.Action,
		Affirmation: aiResp.Affirmation,
		LuckyColor:  aiResp.LuckyColor,
		LuckyNumber: aiResp.LuckyNumber,
	}

	return reading, nil
}
