package domain

import (
	"encoding/json"
	"time"

	"github.com/google/uuid"
)

type User struct {
	ID          uuid.UUID  `db:"id" json:"id"`
	FirebaseUID string     `db:"firebase_uid" json:"-"`
	Email       string     `db:"email" json:"email"`
	Name        string     `db:"name" json:"name"`
	CreatedAt   time.Time  `db:"created_at" json:"created_at"`
	UpdatedAt   time.Time  `db:"updated_at" json:"updated_at"`
	DeletedAt   *time.Time `db:"deleted_at" json:"-"`
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

type CreateBirthProfileInput struct {
	BirthDate      string  `json:"birth_date" validate:"required"`
	BirthTime      *string `json:"birth_time"`
	BirthTimeKnown bool    `json:"birth_time_known"`
	BirthPlace     string  `json:"birth_place" validate:"required"`
	Latitude       float64 `json:"latitude" validate:"required"`
	Longitude      float64 `json:"longitude" validate:"required"`
	Timezone       string  `json:"timezone" validate:"required"`
}
