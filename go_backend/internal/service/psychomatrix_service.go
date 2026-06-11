package service

import (
	"context"
	"errors"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/psychomatrix"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
)

// PsychomatrixService computes the Pythagoras Square (psychomatrix) reading
// for a user from their stored birth date.
type PsychomatrixService struct {
	profileRepo repository.BirthProfileRepository
}

func NewPsychomatrixService(profileRepo repository.BirthProfileRepository) *PsychomatrixService {
	return &PsychomatrixService{profileRepo: profileRepo}
}

var ErrPsychomatrixMissingProfile = errors.New("birth profile is required for a psychomatrix reading")

// GetReading builds the full psychomatrix reading for the user.
func (s *PsychomatrixService) GetReading(ctx context.Context, userID uuid.UUID) (*domain.PsychomatrixReading, error) {
	profile, err := s.profileRepo.GetByUserID(ctx, userID)
	if err != nil || profile == nil {
		return nil, ErrPsychomatrixMissingProfile
	}

	res := psychomatrix.Compute(profile.BirthDate)

	cells := make([]domain.PsychomatrixCell, 0, 9)
	for digit := 1; digit <= 9; digit++ {
		count := res.Counts[digit]
		cells = append(cells, domain.PsychomatrixCell{
			Digit:    digit,
			Count:    count,
			Repeated: repeatedDigit(digit, count),
			Title:    psychomatrix.CellTitle(digit),
			Meaning:  psychomatrix.CellMeaning(digit, count),
		})
	}

	lines := make([]domain.PsychomatrixLine, 0, len(psychomatrix.LineDefs))
	for _, ld := range psychomatrix.LineDefs {
		strength := res.Lines[ld.Key]
		lines = append(lines, domain.PsychomatrixLine{
			Key:      ld.Key,
			Title:    psychomatrix.LineTitle(ld.Key),
			Cells:    []int{ld.Cells[0], ld.Cells[1], ld.Cells[2]},
			Strength: strength,
			Meaning:  psychomatrix.LineMeaning(ld.Key, strength),
		})
	}

	return &domain.PsychomatrixReading{
		BirthDate: profile.BirthDate.Format("2006-01-02"),
		WorkingNumbers: domain.PsychomatrixWorkingNumbers{
			First:  res.W1,
			Second: res.W2,
			Third:  res.W3,
			Fourth: res.W4,
		},
		Cells: cells,
		Lines: lines,
	}, nil
}

// repeatedDigit renders a digit repeated count times, e.g. (1, 3) -> "111".
// Returns "" when the digit is absent.
func repeatedDigit(digit, count int) string {
	if count <= 0 {
		return ""
	}
	out := make([]byte, count)
	c := byte('0' + digit)
	for i := range out {
		out[i] = c
	}
	return string(out)
}
