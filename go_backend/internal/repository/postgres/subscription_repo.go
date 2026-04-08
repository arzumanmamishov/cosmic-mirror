package postgres

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"cosmic-mirror/internal/domain"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type SubscriptionRepository struct {
	db *sqlx.DB
}

func NewSubscriptionRepository(db *sqlx.DB) *SubscriptionRepository {
	return &SubscriptionRepository{db: db}
}

func (r *SubscriptionRepository) GetByUserID(ctx context.Context, userID uuid.UUID) (*domain.Subscription, error) {
	var sub domain.Subscription
	err := r.db.GetContext(ctx, &sub,
		`SELECT * FROM subscriptions WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1`, userID,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &sub, err
}

func (r *SubscriptionRepository) Upsert(ctx context.Context, sub *domain.Subscription) error {
	if sub.ID == uuid.Nil {
		sub.ID = uuid.New()
	}
	sub.UpdatedAt = time.Now()
	if sub.CreatedAt.IsZero() {
		sub.CreatedAt = time.Now()
	}

	_, err := r.db.ExecContext(ctx,
		`INSERT INTO subscriptions (id, user_id, revenuecat_id, plan_type, status,
		 expires_at, trial_end_at, created_at, updated_at)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
		 ON CONFLICT (user_id) DO UPDATE SET
		 revenuecat_id = EXCLUDED.revenuecat_id,
		 plan_type = EXCLUDED.plan_type,
		 status = EXCLUDED.status,
		 expires_at = EXCLUDED.expires_at,
		 trial_end_at = EXCLUDED.trial_end_at,
		 updated_at = EXCLUDED.updated_at`,
		sub.ID, sub.UserID, sub.RevenueCatID, sub.PlanType, sub.Status,
		sub.ExpiresAt, sub.TrialEndAt, sub.CreatedAt, sub.UpdatedAt,
	)
	return err
}

func (r *SubscriptionRepository) UpdateStatus(ctx context.Context, revenueCatID string, status domain.SubscriptionStatus, expiresAt *time.Time) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE subscriptions SET status = $1, expires_at = $2, updated_at = $3
		 WHERE revenuecat_id = $4`,
		status, expiresAt, time.Now(), revenueCatID,
	)
	return err
}
