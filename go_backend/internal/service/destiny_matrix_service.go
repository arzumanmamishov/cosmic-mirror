package service

import (
	"context"
	"errors"

	"cosmic-mirror/internal/destinymatrix"
	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
)

// DestinyMatrixService computes the Matrix of Destiny (22-arcana octagram)
// reading for a user from their stored birth date.
type DestinyMatrixService struct {
	profileRepo repository.BirthProfileRepository
}

func NewDestinyMatrixService(profileRepo repository.BirthProfileRepository) *DestinyMatrixService {
	return &DestinyMatrixService{profileRepo: profileRepo}
}

var ErrDestinyMatrixMissingProfile = errors.New("birth profile is required for a destiny matrix reading")

// GetReading builds the full destiny matrix reading for the user.
func (s *DestinyMatrixService) GetReading(ctx context.Context, userID uuid.UUID) (*domain.DestinyMatrixReading, error) {
	profile, err := s.profileRepo.GetByUserID(ctx, userID)
	if err != nil || profile == nil {
		return nil, ErrDestinyMatrixMissingProfile
	}

	res := destinymatrix.Compute(profile.BirthDate)

	points := make([]domain.DestinyPoint, 0, len(destinymatrix.PointDefs))
	for _, pd := range destinymatrix.PointDefs {
		value := res.Value(pd.Key)
		name, meaning := destinymatrix.Arcana(value)
		points = append(points, domain.DestinyPoint{
			Key:        pd.Key,
			Position:   pd.Position,
			Title:      pd.Title,
			Arcana:     value,
			ArcanaName: name,
			Meaning:    meaning,
		})
	}

	lines := make([]domain.DestinyLine, 0, len(destinymatrix.LineDefs))
	for _, ld := range destinymatrix.LineDefs {
		keys := make([]string, len(ld.PointKeys))
		copy(keys, ld.PointKeys)
		lines = append(lines, domain.DestinyLine{
			Key:       ld.Key,
			Title:     ld.Title,
			PointKeys: keys,
			Theme:     ld.Theme,
		})
	}

	ladder := make([]domain.AgeArcana, 0, len(res.AgeLadder))
	for _, rung := range res.AgeLadder {
		ladder = append(ladder, domain.AgeArcana{
			Age:    rung.Age,
			Label:  rung.Label,
			Arcana: rung.Arcana,
		})
	}

	return &domain.DestinyMatrixReading{
		BirthDate: profile.BirthDate.Format("2006-01-02"),
		Points:    points,
		Lines:     lines,
		AgeLadder: ladder,
	}, nil
}
