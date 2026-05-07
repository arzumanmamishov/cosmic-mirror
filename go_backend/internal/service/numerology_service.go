package service

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/numerology"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
)

// NumerologyService computes the full numerology reading for a user.
//
// Inputs needed: birth date (always required) and full name (preferred).
// Falls back to using the user's name from `users.name` if no separate full
// birth name is on file.
type NumerologyService struct {
	userRepo    repository.UserRepository
	profileRepo repository.BirthProfileRepository
}

func NewNumerologyService(userRepo repository.UserRepository, profileRepo repository.BirthProfileRepository) *NumerologyService {
	return &NumerologyService{userRepo: userRepo, profileRepo: profileRepo}
}

var ErrNumerologyMissingProfile = errors.New("birth profile is required for a numerology reading")

func (s *NumerologyService) GetReading(ctx context.Context, userID uuid.UUID) (*domain.NumerologyReading, error) {
	profile, err := s.profileRepo.GetByUserID(ctx, userID)
	if err != nil || profile == nil {
		return nil, ErrNumerologyMissingProfile
	}
	user, err := s.userRepo.GetByID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("user lookup: %w", err)
	}
	fullName := strings.TrimSpace(user.Name)
	if fullName == "" {
		fullName = "Unknown" // numerology gracefully handles odd input
	}

	now := time.Now()
	prof := computeProfile(fullName, profile.BirthDate)
	cyc := computeCycles(profile.BirthDate, prof.LifePath, now)

	return &domain.NumerologyReading{Profile: prof, Cycles: cyc}, nil
}

func (s *NumerologyService) Compare(ctx context.Context, userID uuid.UUID, req domain.NumerologyCompatibilityRequest) (*domain.NumerologyCompatibility, error) {
	myReading, err := s.GetReading(ctx, userID)
	if err != nil {
		return nil, err
	}
	otherDate, err := time.Parse("2006-01-02", req.BirthDate)
	if err != nil {
		return nil, fmt.Errorf("invalid birth_date: %w", err)
	}
	otherFullName := strings.TrimSpace(req.FullName)
	if otherFullName == "" {
		return nil, errors.New("full_name is required")
	}
	other := computeProfile(otherFullName, otherDate)

	report := numerology.Compatibility(
		toNum(myReading.Profile.LifePath),
		toNum(myReading.Profile.Expression),
		toNum(myReading.Profile.SoulUrge),
		toNum(other.LifePath),
		toNum(other.Expression),
		toNum(other.SoulUrge),
	)
	return &domain.NumerologyCompatibility{
		Score:           report.Score,
		LifePathScore:   report.LifePathScore,
		ExpressionScore: report.ExpressionScore,
		SoulUrgeScore:   report.SoulUrgeScore,
		Summary:         report.Summary,
		OtherProfile:    other,
	}, nil
}

// AnalyzeName runs the standalone Name Numerology Calculator on any
// arbitrary name (no auth scope, no birth profile). Returns the three
// classical name-derived numbers plus the per-letter breakdown so the
// UI can show how each total was built.
func (s *NumerologyService) AnalyzeName(name string) (*domain.NumerologyNameAnalysis, error) {
	trimmed := strings.TrimSpace(name)
	if trimmed == "" {
		return nil, errors.New("name is required")
	}
	expr := numerology.Expression(trimmed)
	soul := numerology.SoulUrge(trimmed)
	pers := numerology.Personality(trimmed)

	letters := numerology.LettersOf(trimmed)
	wire := make([]domain.NumerologyLetter, len(letters))
	for i, l := range letters {
		wire[i] = domain.NumerologyLetter{
			Letter:  string(l.Letter),
			Value:   l.Value,
			IsVowel: l.IsVowel,
		}
	}

	return &domain.NumerologyNameAnalysis{
		Name:          trimmed,
		Expression:    decorate(expr, "expression"),
		SoulUrge:      decorate(soul, "soul_urge"),
		Personality:   decorate(pers, "personality"),
		HiddenPassion: numerology.HiddenPassion(trimmed),
		KarmicLessons: numerology.KarmicLessons(trimmed),
		Letters:       wire,
	}, nil
}

// computeProfile is the pure-function bridge between the numerology package
// and the domain types — converts internal Numbers to wire-shape with
// canned descriptions baked in.
func computeProfile(fullName string, birthDate time.Time) domain.NumerologyProfile {
	life := numerology.LifePath(birthDate)
	expr := numerology.Expression(fullName)
	soul := numerology.SoulUrge(fullName)
	pers := numerology.Personality(fullName)
	mat := numerology.Maturity(life, expr)
	bday := numerology.Birthday(birthDate)

	return domain.NumerologyProfile{
		LifePath:      decorate(life, "life_path"),
		Expression:    decorate(expr, "expression"),
		SoulUrge:      decorate(soul, "soul_urge"),
		Personality:   decorate(pers, "personality"),
		Maturity:      decorate(mat, "maturity"),
		Birthday:      decorate(bday, "birthday"),
		KarmicLessons: numerology.KarmicLessons(fullName),
		HiddenPassion: numerology.HiddenPassion(fullName),
		FullName:      fullName,
		BirthDate:     birthDate,
	}
}

func computeCycles(birthDate time.Time, life domain.NumerologyNumber, now time.Time) domain.NumerologyCycles {
	currentAge := numerology.AgeAt(birthDate, now)
	py := numerology.PersonalYear(birthDate, now)
	pm := numerology.PersonalMonth(py, now)
	pd := numerology.PersonalDay(pm, now)

	pinnacles := numerology.Pinnacles(birthDate, toNum(life), currentAge)
	challenges := numerology.Challenges(birthDate, toNum(life), currentAge)

	out := domain.NumerologyCycles{
		PersonalYear:  decorate(py, "personal_year"),
		PersonalMonth: decorate(pm, "personal_month"),
		PersonalDay:   decorate(pd, "personal_day"),
		CurrentAge:    currentAge,
	}
	for i, p := range pinnacles {
		out.Pinnacles[i] = domain.NumerologyPinnacle{
			Index: p.Index, StartAge: p.StartAge, EndAge: p.EndAge,
			IsActive: p.IsActive,
			Number:   decorate(p.Number, "personal_year"), // reuse year descriptions for cycle vibes
		}
	}
	for i, c := range challenges {
		out.Challenges[i] = domain.NumerologyChallenge{
			Index: c.Index, StartAge: c.StartAge, EndAge: c.EndAge,
			IsActive: c.IsActive,
			Number:   decorate(c.Number, "personal_year"),
		}
	}
	return out
}

func decorate(n numerology.Number, kind string) domain.NumerologyNumber {
	display := fmt.Sprintf("%d", n.Value)
	if n.IsMaster {
		// Show as "11/2" so the UI can display both.
		reduced := 0
		v := n.Value
		for v > 0 {
			reduced += v % 10
			v /= 10
		}
		display = fmt.Sprintf("%d/%d", n.Value, reduced)
	}
	return domain.NumerologyNumber{
		Value:        n.Value,
		Display:      display,
		RawSum:       n.RawSum,
		IsMaster:     n.IsMaster,
		IsKarmicDebt: n.IsKarmicDebt,
		Description:  numerology.Description(kind, n),
	}
}

// toNum converts a domain wire-shape back to the internal numerology.Number.
// Used for compatibility scoring which needs the bare struct.
func toNum(n domain.NumerologyNumber) numerology.Number {
	return numerology.Number{
		Value:        n.Value,
		RawSum:       n.RawSum,
		IsMaster:     n.IsMaster,
		IsKarmicDebt: n.IsKarmicDebt,
	}
}
