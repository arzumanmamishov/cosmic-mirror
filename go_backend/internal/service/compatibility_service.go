package service

import (
	"context"
	"encoding/json"
	"fmt"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/provider/openai"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
)

type CompatibilityService struct {
	compatRepo  repository.CompatibilityRepository
	profileRepo repository.BirthProfileRepository
	aiClient    *openai.Client
}

func NewCompatibilityService(
	compatRepo repository.CompatibilityRepository,
	profileRepo repository.BirthProfileRepository,
	aiClient *openai.Client,
) *CompatibilityService {
	return &CompatibilityService{
		compatRepo:  compatRepo,
		profileRepo: profileRepo,
		aiClient:    aiClient,
	}
}

func (s *CompatibilityService) GetReport(ctx context.Context, userID, personID uuid.UUID) (*domain.CompatibilityReport, error) {
	return s.compatRepo.GetByUserAndPerson(ctx, userID, personID)
}

func (s *CompatibilityService) GenerateReport(ctx context.Context, userID, personID uuid.UUID) (*domain.CompatibilityReport, error) {
	userProfile, err := s.profileRepo.GetByUserID(ctx, userID)
	if err != nil || userProfile == nil {
		return nil, fmt.Errorf("user birth profile not found")
	}

	prompt := openai.BuildCompatibilityPrompt(userProfile, personID.String())
	response, err := s.aiClient.ChatCompletionJSON(ctx, prompt)
	if err != nil {
		return nil, fmt.Errorf("AI generation failed: %w", err)
	}

	var aiResp domain.CompatibilityAIResponse
	if err := json.Unmarshal([]byte(response), &aiResp); err != nil {
		return nil, fmt.Errorf("parse AI response: %w", err)
	}

	report := &domain.CompatibilityReport{
		UserID:             userID,
		SavedPersonID:      personID,
		EmotionalScore:     aiResp.EmotionalScore,
		CommunicationScore: aiResp.CommunicationScore,
		ChemistryScore:     aiResp.ChemistryScore,
		ConflictPatterns:   aiResp.ConflictPatterns,
		Advice:             aiResp.Advice,
		FullReport:         aiResp.FullReport,
	}
	report.CalculateOverall()

	if err := s.compatRepo.Create(ctx, report); err != nil {
		return nil, fmt.Errorf("store report: %w", err)
	}

	return report, nil
}
