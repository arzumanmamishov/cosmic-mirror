package postgres

import (
	"context"
	"database/sql"
	"errors"

	"cosmic-mirror/internal/domain"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/lib/pq"
)

type PreferencesRepository struct {
	db *sqlx.DB
}

func NewPreferencesRepository(db *sqlx.DB) *PreferencesRepository {
	return &PreferencesRepository{db: db}
}

// Get returns the user's stored preferences, or nil if they've never saved
// any (callers fall back to domain.DefaultUserPreferences).
func (r *PreferencesRepository) Get(ctx context.Context, userID uuid.UUID) (*domain.UserPreferences, error) {
	var p domain.UserPreferences
	err := r.db.QueryRowxContext(ctx,
		`SELECT user_id, focus_areas, notification_enabled, notification_time, theme,
		        notif_daily_reading, notif_affirmation, notif_weekly
		 FROM user_preferences WHERE user_id = $1`, userID,
	).Scan(
		&p.UserID, pq.Array(&p.FocusAreas), &p.NotificationEnabled, &p.NotificationTime, &p.Theme,
		&p.NotifDailyReading, &p.NotifAffirmation, &p.NotifWeekly,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &p, nil
}

// Upsert writes the full preferences row (insert or replace by user_id).
func (r *PreferencesRepository) Upsert(ctx context.Context, p *domain.UserPreferences) error {
	_, err := r.db.ExecContext(ctx,
		`INSERT INTO user_preferences
		   (user_id, focus_areas, notification_enabled, notification_time, theme,
		    notif_daily_reading, notif_affirmation, notif_weekly)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
		 ON CONFLICT (user_id) DO UPDATE SET
		   focus_areas          = EXCLUDED.focus_areas,
		   notification_enabled = EXCLUDED.notification_enabled,
		   notification_time    = EXCLUDED.notification_time,
		   theme                = EXCLUDED.theme,
		   notif_daily_reading  = EXCLUDED.notif_daily_reading,
		   notif_affirmation    = EXCLUDED.notif_affirmation,
		   notif_weekly         = EXCLUDED.notif_weekly`,
		p.UserID, pq.Array(p.FocusAreas), p.NotificationEnabled, p.NotificationTime, p.Theme,
		p.NotifDailyReading, p.NotifAffirmation, p.NotifWeekly,
	)
	return err
}
