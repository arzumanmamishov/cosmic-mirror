package domain

import (
	"time"

	"github.com/google/uuid"
)

type JournalEntry struct {
	ID        uuid.UUID `db:"id" json:"id"`
	UserID    uuid.UUID `db:"user_id" json:"user_id"`
	EntryDate time.Time `db:"entry_date" json:"entry_date"`
	Prompt    *string   `db:"prompt" json:"prompt,omitempty"`
	Content   string    `db:"content" json:"content"`
	Mood      *string   `db:"mood" json:"mood,omitempty"`
	CreatedAt time.Time `db:"created_at" json:"created_at"`
	UpdatedAt time.Time `db:"updated_at" json:"updated_at"`
}

type RitualCompletion struct {
	ID            uuid.UUID `db:"id" json:"id"`
	UserID        uuid.UUID `db:"user_id" json:"user_id"`
	RitualType    string    `db:"ritual_type" json:"ritual_type"`
	CompletedDate time.Time `db:"completed_date" json:"completed_date"`
	StreakCount   int       `db:"streak_count" json:"streak_count"`
}

type CreateJournalInput struct {
	Content   string  `json:"content" validate:"required"`
	Mood      *string `json:"mood"`
	EntryDate string  `json:"entry_date"`
}

type UpdateJournalInput struct {
	Content *string `json:"content"`
	Mood    *string `json:"mood"`
}
