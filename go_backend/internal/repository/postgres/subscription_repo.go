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
		`INSERT INTO subscriptions (id, user_id, revenuecat_id,
		 stripe_customer_id, stripe_subscription_id, price_id,
		 plan_type, status, expires_at, current_period_end,
		 cancel_at_period_end, trial_end_at, created_at, updated_at)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
		 ON CONFLICT (user_id) DO UPDATE SET
		 revenuecat_id = EXCLUDED.revenuecat_id,
		 stripe_customer_id = EXCLUDED.stripe_customer_id,
		 stripe_subscription_id = EXCLUDED.stripe_subscription_id,
		 price_id = EXCLUDED.price_id,
		 plan_type = EXCLUDED.plan_type,
		 status = EXCLUDED.status,
		 expires_at = EXCLUDED.expires_at,
		 current_period_end = EXCLUDED.current_period_end,
		 cancel_at_period_end = EXCLUDED.cancel_at_period_end,
		 trial_end_at = EXCLUDED.trial_end_at,
		 updated_at = EXCLUDED.updated_at`,
		sub.ID, sub.UserID, sub.RevenueCatID,
		sub.StripeCustomerID, sub.StripeSubscriptionID, sub.PriceID,
		sub.PlanType, sub.Status, sub.ExpiresAt, sub.CurrentPeriodEnd,
		sub.CancelAtPeriodEnd, sub.TrialEndAt, sub.CreatedAt, sub.UpdatedAt,
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

// GetByStripeCustomer finds the subscription row a Stripe customer belongs to.
// Used when we already created a Stripe customer for this user but need to
// reuse it across subscribe attempts (so we don't litter Stripe with dupes).
func (r *SubscriptionRepository) GetByStripeCustomer(ctx context.Context, stripeCustomerID string) (*domain.Subscription, error) {
	var sub domain.Subscription
	err := r.db.GetContext(ctx, &sub,
		`SELECT * FROM subscriptions WHERE stripe_customer_id = $1 LIMIT 1`,
		stripeCustomerID,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &sub, err
}

// UpdateFromStripe applies a Stripe subscription's authoritative state to
// our row. Keyed by the Stripe subscription id (not user id) because a
// single user can in theory churn through multiple subs over time.
func (r *SubscriptionRepository) UpdateFromStripe(
	ctx context.Context,
	stripeSubscriptionID string,
	status domain.SubscriptionStatus,
	priceID string,
	planType domain.PlanType,
	currentPeriodEnd *time.Time,
	cancelAtPeriodEnd bool,
) error {
	_, err := r.db.ExecContext(ctx,
		`UPDATE subscriptions SET
		   status = $1,
		   price_id = $2,
		   plan_type = $3,
		   current_period_end = $4,
		   expires_at = $4,
		   cancel_at_period_end = $5,
		   updated_at = $6
		 WHERE stripe_subscription_id = $7`,
		status, priceID, planType, currentPeriodEnd,
		cancelAtPeriodEnd, time.Now(), stripeSubscriptionID,
	)
	return err
}
