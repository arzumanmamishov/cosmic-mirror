package postgres

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgconn"
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

// subscriptionUpsertSQL writes the Stripe side of the row. The store
// (rc_*) columns are deliberately absent: they belong to RevenueCat
// webhooks (ApplyStoreState) and a Stripe write must never clobber them.
const subscriptionUpsertSQL = `INSERT INTO subscriptions (id, user_id, revenuecat_id,
		 stripe_customer_id, stripe_subscription_id, price_id,
		 plan_type, status, expires_at, current_period_end,
		 cancel_at_period_end, trial_end_at, created_at, updated_at, trial_consumed)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
		 ON CONFLICT (user_id) DO UPDATE SET
		 revenuecat_id = COALESCE(NULLIF(EXCLUDED.revenuecat_id, ''), subscriptions.revenuecat_id),
		 stripe_customer_id = EXCLUDED.stripe_customer_id,
		 stripe_subscription_id = EXCLUDED.stripe_subscription_id,
		 price_id = EXCLUDED.price_id,
		 plan_type = EXCLUDED.plan_type,
		 status = EXCLUDED.status,
		 expires_at = EXCLUDED.expires_at,
		 current_period_end = EXCLUDED.current_period_end,
		 cancel_at_period_end = EXCLUDED.cancel_at_period_end,
		 trial_end_at = EXCLUDED.trial_end_at,
		 trial_consumed = subscriptions.trial_consumed OR EXCLUDED.trial_consumed,
		 updated_at = EXCLUDED.updated_at`

// premiumRowSQL is domain.Subscription.IsPremium as a SQL predicate on the
// existing row: the Stripe subscription or the store entitlement is live.
const premiumRowSQL = `((subscriptions.status IN ('active', 'trialing')
		    AND (subscriptions.expires_at IS NULL OR subscriptions.expires_at > NOW()))
		 OR (subscriptions.rc_status IN ('active', 'trialing')
		    AND (subscriptions.rc_expires_at IS NULL OR subscriptions.rc_expires_at > NOW())))`

func (r *SubscriptionRepository) prepareUpsert(sub *domain.Subscription) []any {
	if sub.ID == uuid.Nil {
		sub.ID = uuid.New()
	}
	sub.UpdatedAt = time.Now()
	if sub.CreatedAt.IsZero() {
		sub.CreatedAt = time.Now()
	}
	if sub.Status == domain.StatusActive || sub.Status == domain.StatusTrialing {
		sub.TrialConsumed = true
	}
	return []any{
		sub.ID, sub.UserID, sub.RevenueCatID,
		sub.StripeCustomerID, sub.StripeSubscriptionID, sub.PriceID,
		sub.PlanType, sub.Status, sub.ExpiresAt, sub.CurrentPeriodEnd,
		sub.CancelAtPeriodEnd, sub.TrialEndAt, sub.CreatedAt, sub.UpdatedAt,
		sub.TrialConsumed,
	}
}

func (r *SubscriptionRepository) Upsert(ctx context.Context, sub *domain.Subscription) error {
	_, err := r.db.ExecContext(ctx, subscriptionUpsertSQL, r.prepareUpsert(sub)...)
	return err
}

// UpsertIfNotPremium is Upsert, except an existing row that currently
// grants premium from either source (the same rule as
// domain.Subscription.IsPremium) is left untouched. Returns
// false when the write was skipped for that reason. The check happens in
// the same statement as the write, so a webhook that activates the row
// concurrently can't be overwritten by a new incomplete subscription.
func (r *SubscriptionRepository) UpsertIfNotPremium(ctx context.Context, sub *domain.Subscription) (bool, error) {
	res, err := r.db.ExecContext(ctx,
		subscriptionUpsertSQL+`
		 WHERE NOT `+premiumRowSQL,
		r.prepareUpsert(sub)...,
	)
	if err != nil {
		return false, err
	}
	n, err := res.RowsAffected()
	if err != nil {
		return false, err
	}
	return n > 0, nil
}

// ApplyStoreState records a RevenueCat (App Store / Google Play) snapshot
// on the user's row, creating the row if needed. Only the store columns
// (plus revenuecat_id and trial_consumed) are written, so the Stripe side
// of the row is never touched. A snapshot older than the stored one
// (rc_as_of) is ignored, which makes retried or out-of-order webhooks
// idempotent. Returns false when nothing was written: either the stored
// snapshot is newer or the user no longer exists (deleted account).
func (r *SubscriptionRepository) ApplyStoreState(ctx context.Context, userID uuid.UUID, st domain.StoreSubscriptionState) (bool, error) {
	now := time.Now()
	// Any store purchase history (even an expired one) uses up the trial.
	trialConsumed := st.Status == domain.StatusActive || st.Status == domain.StatusTrialing ||
		st.ProductID != ""
	res, err := r.db.ExecContext(ctx,
		`INSERT INTO subscriptions (id, user_id, revenuecat_id, plan_type, status,
		   rc_status, rc_product_id, rc_store, rc_expires_at, rc_is_trial,
		   rc_will_renew, rc_billing_issue, rc_as_of, trial_consumed,
		   created_at, updated_at)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $15)
		 ON CONFLICT (user_id) DO UPDATE SET
		   revenuecat_id = EXCLUDED.revenuecat_id,
		   rc_status = EXCLUDED.rc_status,
		   rc_product_id = EXCLUDED.rc_product_id,
		   rc_store = EXCLUDED.rc_store,
		   rc_expires_at = EXCLUDED.rc_expires_at,
		   rc_is_trial = EXCLUDED.rc_is_trial,
		   rc_will_renew = EXCLUDED.rc_will_renew,
		   rc_billing_issue = EXCLUDED.rc_billing_issue,
		   rc_as_of = EXCLUDED.rc_as_of,
		   trial_consumed = subscriptions.trial_consumed OR EXCLUDED.trial_consumed,
		   updated_at = EXCLUDED.updated_at
		 WHERE subscriptions.rc_as_of IS NULL OR subscriptions.rc_as_of <= EXCLUDED.rc_as_of`,
		uuid.New(), userID, st.AppUserID, domain.PlanTypeForProduct(st.ProductID), domain.StatusExpired,
		st.Status, st.ProductID, st.Store, st.ExpiresAt, st.IsTrial,
		st.WillRenew, st.BillingIssue, st.AsOf, trialConsumed,
		now,
	)
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == "23503" {
		// foreign_key_violation: the user was deleted. Nothing to record.
		return false, nil
	}
	if err != nil {
		return false, err
	}
	n, err := res.RowsAffected()
	if err != nil {
		return false, err
	}
	return n > 0, nil
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
	res, err := r.db.ExecContext(ctx,
		`UPDATE subscriptions SET
		   status = $1,
		   price_id = $2,
		   plan_type = $3,
		   current_period_end = $4,
		   expires_at = $4,
		   cancel_at_period_end = $5,
		   updated_at = $6,
		   trial_consumed = trial_consumed OR $8
		 WHERE stripe_subscription_id = $7`,
		status, priceID, planType, currentPeriodEnd,
		cancelAtPeriodEnd, time.Now(), stripeSubscriptionID,
		status == domain.StatusActive || status == domain.StatusTrialing,
	)
	if err != nil {
		return err
	}
	n, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if n == 0 {
		return repository.ErrSubscriptionNotFound
	}
	return nil
}
