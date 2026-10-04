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
	"github.com/redis/go-redis/v9"
)

// ErrPersonNotFound is returned when a saved-person lookup fails or the person
// belongs to a different user. Handlers map this to a 404.
var ErrPersonNotFound = errors.New("saved person not found")

// CompatibilityLimitError is returned by GenerateReport when a free user
// has used up today's report generations. It mirrors ChatLimitError so the
// handler can answer with the same structured 429 the chat cap uses.
type CompatibilityLimitError struct {
	Used    int
	Limit   int
	ResetAt time.Time
}

func (e *CompatibilityLimitError) Error() string {
	return fmt.Sprintf("daily compatibility report limit reached (%d/%d)", e.Used, e.Limit)
}

// compatReuseWindow is how long a generated report is handed back instead
// of paying for another LLM call.
const compatReuseWindow = time.Hour

type CompatibilityService struct {
	compatRepo  repository.CompatibilityRepository
	peopleRepo  repository.SavedPeopleRepository
	profileRepo repository.BirthProfileRepository
	aiClient    *openai.Client

	// Free-tier daily cap (see WithFreeDailyLimit). freeDailyLimit <= 0
	// disables the cap.
	rdb            *redis.Client
	freeDailyLimit int
	isPremium      func(ctx context.Context, userID uuid.UUID) bool
}

// WithFreeDailyLimit caps how many reports a non-premium user can generate
// per UTC day. Like the chat cap, the counter lives in Redis (atomic INCR,
// can't be reset by deleting saved people) with a DB count as fallback.
func (s *CompatibilityService) WithFreeDailyLimit(
	rdb *redis.Client,
	limit int,
	isPremium func(ctx context.Context, userID uuid.UUID) bool,
) *CompatibilityService {
	s.rdb = rdb
	s.freeDailyLimit = limit
	s.isPremium = isPremium
	return s
}

func compatUsageKey(userID uuid.UUID) string {
	return fmt.Sprintf("compat:gen:%s:%s", userID, time.Now().UTC().Format("20060102"))
}

// reserveGeneration counts one generation against today's free budget.
// Returns a release func that refunds the slot (call it when the
// generation fails so a flaky upstream doesn't burn the user's quota), or
// a *CompatibilityLimitError when the budget is exhausted.
func (s *CompatibilityService) reserveGeneration(ctx context.Context, userID uuid.UUID) (release func(), err error) {
	noop := func() {}
	if s.freeDailyLimit <= 0 || (s.isPremium != nil && s.isPremium(ctx, userID)) {
		return noop, nil
	}
	limitErr := &CompatibilityLimitError{Used: s.freeDailyLimit, Limit: s.freeDailyLimit, ResetAt: nextResetAt()}

	if s.rdb != nil {
		key := compatUsageKey(userID)
		if n, rerr := s.rdb.Incr(ctx, key).Result(); rerr == nil {
			if n == 1 {
				s.rdb.Expire(ctx, key, 48*time.Hour)
			}
			release := func() {
				// Detached from the request ctx: the refund must still
				// happen when the client disconnected mid-generation.
				rctx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 2*time.Second)
				defer cancel()
				s.rdb.Decr(rctx, key)
			}
			if int(n) > s.freeDailyLimit {
				release()
				return nil, limitErr
			}
			return release, nil
		}
		// Redis unavailable — fall through to the DB count.
	}

	now := time.Now().UTC()
	dayStart := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	used, err := s.compatRepo.CountUserReportsSince(ctx, userID, dayStart)
	if err != nil {
		return nil, fmt.Errorf("count reports: %w", err)
	}
	if used >= s.freeDailyLimit {
		return nil, limitErr
	}
	return noop, nil
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
	// Same rules as the user's own birth profile; failures wrap
	// domain.ErrValidation (→ 400).
	birthDate, err := validateBirthData(input.BirthDate, input.Latitude, input.Longitude, input.Timezone)
	if err != nil {
		return nil, err
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

// GetReport returns the user's latest report for the person, preferring
// one in the caller's language. nil, nil when none has been generated.
func (s *CompatibilityService) GetReport(ctx context.Context, userID, personID uuid.UUID) (*domain.CompatibilityReport, error) {
	return s.compatRepo.GetByUserAndPerson(ctx, userID, personID, middleware.LangFromContext(ctx))
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

	lang := middleware.LangFromContext(ctx)

	// Every generation is a paid LLM call; hand back a fresh-enough
	// existing report in the same language instead of regenerating on
	// each tap. Reuse doesn't count against the free daily cap.
	existing, err := s.compatRepo.GetByUserAndPerson(ctx, userID, personID, lang)
	if err != nil {
		return nil, fmt.Errorf("load existing report: %w", err)
	}
	if existing != nil && existing.Lang == lang && time.Since(existing.CreatedAt) < compatReuseWindow {
		return existing, nil
	}

	release, err := s.reserveGeneration(ctx, userID)
	if err != nil {
		return nil, err
	}
	// Refund the reserved slot unless a report is actually stored.
	stored := false
	defer func() {
		if !stored {
			release()
		}
	}()

	prompt := openai.BuildCompatibilityPrompt(userProfile, describePerson(person), lang)
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
		Lang:               lang,
	}
	report.ClampScores()
	report.CalculateOverall()

	if err := s.compatRepo.Create(ctx, report); err != nil {
		return nil, fmt.Errorf("store report: %w", err)
	}
	stored = true

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
