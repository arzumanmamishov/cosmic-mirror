package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/provider/openai"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
)

// ErrPersonNotFound is returned when a saved-person lookup fails or the person
// belongs to a different user. Handlers map this to a 404.
var ErrPersonNotFound = errors.New("saved person not found")

type CompatibilityService struct {
	compatRepo  repository.CompatibilityRepository
	peopleRepo  repository.SavedPeopleRepository
	profileRepo repository.BirthProfileRepository
	aiClient    *openai.Client
}

func NewCompatibilityService(
	compatRepo repository.CompatibilityRepository,
	peopleRepo repository.SavedPeopleRepository,
	profileRepo repository.BirthProfileRepository,
	aiClient *openai.Client,
) *CompatibilityService {
	return &CompatibilityService{
		compatRepo:  compatRepo,
		peopleRepo:  peopleRepo,
		profileRepo: profileRepo,
		aiClient:    aiClient,
	}
}

// ListPeople returns the people the user has saved for compatibility checks.
func (s *CompatibilityService) ListPeople(ctx context.Context, userID uuid.UUID) ([]domain.SavedPerson, error) {
	return s.peopleRepo.List(ctx, userID)
}

// AddPerson validates the input, persists a new saved person for the user, and
// returns the stored record (with its generated id).
func (s *CompatibilityService) AddPerson(ctx context.Context, userID uuid.UUID, input domain.AddPersonInput) (*domain.SavedPerson, error) {
	birthDate, err := time.Parse("2006-01-02", input.BirthDate)
	if err != nil {
		return nil, fmt.Errorf("invalid birth_date format (want YYYY-MM-DD): %w", err)
	}
	person := &domain.SavedPerson{
		UserID:         userID,
		Name:           input.Name,
		BirthDate:      birthDate,
		BirthTime:      input.BirthTime,
		BirthTimeKnown: input.BirthTimeKnown,
		BirthPlace:     input.BirthPlace,
		Latitude:       input.Latitude,
		Longitude:      input.Longitude,
		Timezone:       input.Timezone,
	}
	if err := s.peopleRepo.Create(ctx, person); err != nil {
		return nil, fmt.Errorf("save person: %w", err)
	}
	return person, nil
}

// DeletePerson removes a saved person after verifying it belongs to the user.
func (s *CompatibilityService) DeletePerson(ctx context.Context, userID, personID uuid.UUID) error {
	person, err := s.peopleRepo.GetByID(ctx, personID)
	if err != nil {
		return err
	}
	if person == nil || person.UserID != userID {
		return ErrPersonNotFound
	}
	return s.peopleRepo.Delete(ctx, personID)
}

func (s *CompatibilityService) GetReport(ctx context.Context, userID, personID uuid.UUID) (*domain.CompatibilityReport, error) {
	return s.compatRepo.GetByUserAndPerson(ctx, userID, personID)
}

func (s *CompatibilityService) GenerateReport(ctx context.Context, userID, personID uuid.UUID) (*domain.CompatibilityReport, error) {
	userProfile, err := s.profileRepo.GetByUserID(ctx, userID)
	if err != nil || userProfile == nil {
		return nil, fmt.Errorf("user birth profile not found")
	}

	// Load the saved person and confirm it belongs to this user before we
	// send any of their birth data to the AI model.
	person, err := s.peopleRepo.GetByID(ctx, personID)
	if err != nil {
		return nil, fmt.Errorf("load person: %w", err)
	}
	if person == nil || person.UserID != userID {
		return nil, ErrPersonNotFound
	}

	prompt := openai.BuildCompatibilityPrompt(userProfile, describePerson(person), middleware.LangFromContext(ctx))
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

	report.PersonName = person.Name
	return report, nil
}

// describePerson renders a saved person's birth data into the natural-language
// blurb BuildCompatibilityPrompt expects as "Person 2 reference".
func describePerson(p *domain.SavedPerson) string {
	desc := fmt.Sprintf("%s — Birth date: %s, Birth place: %s (lat: %.4f, lng: %.4f), Timezone: %s",
		p.Name, p.BirthDate.Format("2006-01-02"), p.BirthPlace, p.Latitude, p.Longitude, p.Timezone)
	if p.BirthTimeKnown && p.BirthTime != nil {
		desc += fmt.Sprintf(", Birth time: %s", *p.BirthTime)
	} else {
		desc += ", Birth time: unknown (use noon as approximate)"
	}
	return desc
}
