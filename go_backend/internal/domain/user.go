package domain

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

type User struct {
	ID              uuid.UUID  `db:"id" json:"id"`
	FirebaseUID     string     `db:"firebase_uid" json:"-"`
	Email           string     `db:"email" json:"email"`
	Name            string     `db:"name" json:"name"`
	AvatarURL       *string    `db:"avatar_url" json:"avatar_url"`
	PasswordHash    *string    `db:"password_hash" json:"-"`
	EmailVerifiedAt *time.Time `db:"email_verified_at" json:"-"`
	LastLoginAt     *time.Time `db:"last_login_at" json:"-"`
	CreatedAt       time.Time  `db:"created_at" json:"created_at"`
	UpdatedAt       time.Time  `db:"updated_at" json:"updated_at"`
	DeletedAt       *time.Time `db:"deleted_at" json:"-"`
}

type BirthProfile struct {
	ID             uuid.UUID        `db:"id" json:"id"`
	UserID         uuid.UUID        `db:"user_id" json:"user_id"`
	BirthDate      time.Time        `db:"birth_date" json:"birth_date"`
	BirthTime      *string          `db:"birth_time" json:"birth_time"`
	BirthTimeKnown bool             `db:"birth_time_known" json:"birth_time_known"`
	BirthPlace     string           `db:"birth_place" json:"birth_place"`
	Latitude       float64          `db:"latitude" json:"latitude"`
	Longitude      float64          `db:"longitude" json:"longitude"`
	Timezone       string           `db:"timezone" json:"timezone"`
	RawChartData   *json.RawMessage `db:"raw_chart_data" json:"-"`
	CreatedAt      time.Time        `db:"created_at" json:"created_at"`
	UpdatedAt      time.Time        `db:"updated_at" json:"updated_at"`
}

type UserPreferences struct {
	UserID              uuid.UUID `db:"user_id" json:"user_id"`
	FocusAreas          []string  `db:"focus_areas" json:"focus_areas"`
	NotificationEnabled bool      `db:"notification_enabled" json:"notification_enabled"`
	NotificationTime    string    `db:"notification_time" json:"notification_time"`
	Theme               string    `db:"theme" json:"theme"`
	NotifDailyReading   bool      `db:"notif_daily_reading" json:"notif_daily_reading"`
	NotifAffirmation    bool      `db:"notif_affirmation" json:"notif_affirmation"`
	NotifWeekly         bool      `db:"notif_weekly" json:"notif_weekly"`
}

// DefaultUserPreferences mirrors the column defaults in migration 001/009 so
// a user who has never saved preferences still gets a sensible row to read
// and to merge partial updates onto.
func DefaultUserPreferences(userID uuid.UUID) UserPreferences {
	return UserPreferences{
		UserID:              userID,
		FocusAreas:          []string{},
		NotificationEnabled: true,
		NotificationTime:    "09:00",
		Theme:               "dark",
		NotifDailyReading:   true,
		NotifAffirmation:    true,
		NotifWeekly:         true,
	}
}

// UpdatePreferencesInput is a partial update — only non-nil fields are applied.
type UpdatePreferencesInput struct {
	FocusAreas          *[]string `json:"focus_areas"`
	NotificationEnabled *bool     `json:"notification_enabled"`
	NotificationTime    *string   `json:"notification_time"`
	Theme               *string   `json:"theme"`
}

// UpdateNotificationPrefsInput is a partial update for the per-category
// notification toggles (preferred_time maps to notification_time).
type UpdateNotificationPrefsInput struct {
	DailyReading  *bool   `json:"daily_reading"`
	Affirmation   *bool   `json:"affirmation"`
	Weekly        *bool   `json:"weekly"`
	PreferredTime *string `json:"preferred_time"`
}

type CreateUserInput struct {
	FirebaseUID string `json:"firebase_uid" validate:"required"`
	Email       string `json:"email" validate:"required,email"`
	Name        string `json:"name"`
}

type UpdateUserInput struct {
	Name  *string `json:"name"`
	Email *string `json:"email"`
}

// RefreshToken is one row of the refresh_tokens table. The plaintext is
// never persisted — only sha256(plaintext) — so a DB dump can't be
// replayed to forge sessions.
type RefreshToken struct {
	ID          uuid.UUID  `db:"id"`
	UserID      uuid.UUID  `db:"user_id"`
	TokenHash   string     `db:"token_hash"`
	ExpiresAt   time.Time  `db:"expires_at"`
	RevokedAt   *time.Time `db:"revoked_at"`
	RotatedToID *uuid.UUID `db:"rotated_to_id"`
	IP          *string    `db:"ip"`
	UserAgent   *string    `db:"user_agent"`
	CreatedAt   time.Time  `db:"created_at"`
}

// UserStats is a user-engagement snapshot used to populate the profile
// stats row. Streak counts consecutive UTC days ending today with any
// activity; the other fields are simple totals.
type UserStats struct {
	Streak         int `json:"streak"`
	JournalEntries int `json:"journal_entries"`
	AIChats        int `json:"ai_chats"`
}

type CreateBirthProfileInput struct {
	BirthDate      string  `json:"birth_date" validate:"required"`
	BirthTime      *string `json:"birth_time"`
	BirthTimeKnown bool    `json:"birth_time_known"`
	BirthPlace     string  `json:"birth_place" validate:"required"`
	Latitude       float64 `json:"latitude" validate:"required"`
	Longitude      float64 `json:"longitude" validate:"required"`
	Timezone       string  `json:"timezone" validate:"required"`
}
