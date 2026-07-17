package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/middleware"
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
	lang := middleware.LangFromContext(ctx)

	// Check DB first — one row per (user, date, lang) so switching UI
	// language returns a fresh translated reading instead of the previous one.
	existing, err := s.readingRepo.GetByUserAndDate(ctx, userID, date, lang)
	if err != nil {
		return nil, fmt.Errorf("get reading from db: %w", err)
	}
	if existing != nil {
		return existing, nil
	}

	// Check Redis cache
	cacheKey := fmt.Sprintf("reading:%s:%s:%s", userID, date.Format("2006-01-02"), lang)
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
		if errors.Is(err, openai.ErrNotConfigured) {
			return stubReading(userID, date, lang), nil
		}
		return nil, fmt.Errorf("generate reading: %w", err)
	}
	reading.Lang = lang

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

// stubReading is the dev / no-OpenAI-key placeholder. Intentionally not
// cached: once OPENAI_API_KEY is wired, the next fetch gets a real one.
func stubReading(userID uuid.UUID, date time.Time, lang string) *domain.DailyReading {
	if lang == "tr" {
		const stub = "Kişiselleştirilmiş günlük okumalar, operatörünüz bir OpenAI anahtarı bağladığında görünür."
		return &domain.DailyReading{
			UserID:      userID,
			ReadingDate: date,
			EnergyLevel: 5,
			Emotional:   stub,
			Love:        stub,
			Career:      stub,
			Health:      stub,
			Caution:     "",
			Action:      "Bugünü gözlemlemeye ayır. Küçük detayları fark et.",
			Affirmation: "Bugün bana ulaşan rehberliğe açığım.",
			LuckyColor:  "altın",
			LuckyNumber: 7,
			Lang:        lang,
			CreatedAt:   time.Now(),
		}
	}
	const stub = "Personalized daily readings appear once your operator connects an OpenAI key."
	return &domain.DailyReading{
		UserID:      userID,
		ReadingDate: date,
		EnergyLevel: 5,
		Emotional:   stub,
		Love:        stub,
		Career:      stub,
		Health:      stub,
		Caution:     "",
		Action:      "Take today to observe. Notice the small things.",
		Affirmation: "I am open to the guidance that reaches me today.",
		LuckyColor:  "gold",
		LuckyNumber: 7,
		Lang:        "en",
		CreatedAt:   time.Now(),
	}
}

func (s *ReadingService) generateReading(ctx context.Context, userID uuid.UUID, date time.Time) (*domain.DailyReading, error) {
	profile, err := s.profileRepo.GetByUserID(ctx, userID)
	if err != nil || profile == nil {
		return nil, fmt.Errorf("birth profile not found for user %s", userID)
	}

	prompt := openai.BuildDailyReadingPrompt(profile, date, middleware.LangFromContext(ctx))
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
