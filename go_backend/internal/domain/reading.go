package domain

import (
	"time"

	"github.com/google/uuid"
)

type DailyReading struct {
	ID          uuid.UUID `db:"id" json:"id"`
	UserID      uuid.UUID `db:"user_id" json:"user_id"`
	ReadingDate time.Time `db:"reading_date" json:"reading_date"`
	SunSign     string    `db:"sun_sign" json:"sun_sign"`
	MoonSign    string    `db:"moon_sign" json:"moon_sign"`
	RisingSign  string    `db:"rising_sign" json:"rising_sign"`
	EnergyLevel int       `db:"energy_level" json:"energy_level"`
	Emotional   string    `db:"emotional" json:"emotional"`
	Love        string    `db:"love" json:"love"`
	Career      string    `db:"career" json:"career"`
	Health      string    `db:"health" json:"health"`
	Caution     string    `db:"caution" json:"caution"`
	Action      string    `db:"action" json:"action"`
	Affirmation string    `db:"affirmation" json:"affirmation"`
	LuckyColor  string    `db:"lucky_color" json:"lucky_color"`
	LuckyNumber int       `db:"lucky_number" json:"lucky_number"`
	CreatedAt   time.Time `db:"created_at" json:"created_at"`
}

type DailyReadingAIResponse struct {
	EnergyLevel int    `json:"energy_level"`
	Emotional   string `json:"emotional"`
	Love        string `json:"love"`
	Career      string `json:"career"`
	Health      string `json:"health"`
	Caution     string `json:"caution"`
	Action      string `json:"action"`
	Affirmation string `json:"affirmation"`
	LuckyColor  string `json:"lucky_color"`
	LuckyNumber int    `json:"lucky_number"`
}
