package domain

import (
	"time"

	"github.com/google/uuid"
)

type SavedPerson struct {
	ID             uuid.UUID `db:"id" json:"id"`
	UserID         uuid.UUID `db:"user_id" json:"user_id"`
	Name           string    `db:"name" json:"name"`
	BirthDate      time.Time `db:"birth_date" json:"birth_date"`
	BirthTime      *string   `db:"birth_time" json:"birth_time"`
	BirthTimeKnown bool      `db:"birth_time_known" json:"birth_time_known"`
	BirthPlace     string    `db:"birth_place" json:"birth_place"`
	Latitude       float64   `db:"latitude" json:"latitude"`
	Longitude      float64   `db:"longitude" json:"longitude"`
	Timezone       string    `db:"timezone" json:"timezone"`
	CreatedAt      time.Time `db:"created_at" json:"created_at"`
}

type CompatibilityReport struct {
	ID                 uuid.UUID `db:"id" json:"id"`
	UserID             uuid.UUID `db:"user_id" json:"user_id"`
	SavedPersonID      uuid.UUID `db:"saved_person_id" json:"saved_person_id"`
	PersonName         string    `db:"-" json:"person_name"`
	EmotionalScore     int       `db:"emotional_score" json:"emotional_score"`
	CommunicationScore int       `db:"communication_score" json:"communication_score"`
	ChemistryScore     int       `db:"chemistry_score" json:"chemistry_score"`
	OverallScore       int       `db:"-" json:"overall_score"`
	ConflictPatterns   string    `db:"conflict_patterns" json:"conflict_patterns"`
	Advice             string    `db:"advice" json:"advice"`
	FullReport         string    `db:"full_report" json:"full_report"`
	CreatedAt          time.Time `db:"created_at" json:"created_at"`
}

func (cr *CompatibilityReport) CalculateOverall() {
	cr.OverallScore = (cr.EmotionalScore + cr.CommunicationScore + cr.ChemistryScore) / 3
}

type AddPersonInput struct {
	Name           string  `json:"name" validate:"required,min=2,max=50"`
	BirthDate      string  `json:"birth_date" validate:"required"`
	BirthTime      *string `json:"birth_time"`
	BirthTimeKnown bool    `json:"birth_time_known"`
	BirthPlace     string  `json:"birth_place" validate:"required"`
	Latitude       float64 `json:"latitude" validate:"required"`
	Longitude      float64 `json:"longitude" validate:"required"`
	Timezone       string  `json:"timezone" validate:"required"`
}

type CompatibilityAIResponse struct {
	EmotionalScore     int    `json:"emotional_score"`
	CommunicationScore int    `json:"communication_score"`
	ChemistryScore     int    `json:"chemistry_score"`
	ConflictPatterns   string `json:"conflict_patterns"`
	Advice             string `json:"advice"`
	FullReport         string `json:"full_report"`
}
