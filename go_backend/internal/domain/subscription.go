package domain

import (
	"strings"
	"time"

	"github.com/google/uuid"
)

type PlanType string
type SubscriptionStatus string

const (
	PlanMonthly PlanType = "monthly"
	PlanYearly  PlanType = "yearly"

	StatusActive    SubscriptionStatus = "active"
	StatusTrialing  SubscriptionStatus = "trialing"
	StatusExpired   SubscriptionStatus = "expired"
	StatusCancelled SubscriptionStatus = "cancelled"
)

// Where a user's premium access comes from.
const (
	SourceStripe     = "stripe"     // web checkout (Stripe Billing)
	SourceRevenueCat = "revenuecat" // App Store / Google Play via RevenueCat
)

// Subscription is the user's single subscriptions row. It carries two
// independent sources of premium:
//   - Stripe (web): Status / ExpiresAt / Stripe* / PriceID / PlanType;
//   - App Store / Google Play via RevenueCat: the Store* fields.
//
// Premium is granted when either source is live, so an event from one
// source can never revoke access paid for through the other.
type Subscription struct {
	ID                   uuid.UUID          `db:"id" json:"id"`
	UserID               uuid.UUID          `db:"user_id" json:"user_id"`
	RevenueCatID         string             `db:"revenuecat_id" json:"-"`
	StripeCustomerID     *string            `db:"stripe_customer_id" json:"-"`
	StripeSubscriptionID *string            `db:"stripe_subscription_id" json:"-"`
	PriceID              *string            `db:"price_id" json:"price_id,omitempty"`
	PlanType             PlanType           `db:"plan_type" json:"plan_type"`
	Status               SubscriptionStatus `db:"status" json:"status"`
	ExpiresAt            *time.Time         `db:"expires_at" json:"expires_at"`
	CurrentPeriodEnd     *time.Time         `db:"current_period_end" json:"current_period_end,omitempty"`
	CancelAtPeriodEnd    bool               `db:"cancel_at_period_end" json:"cancel_at_period_end"`
	TrialEndAt           *time.Time         `db:"trial_end_at" json:"trial_end_at"`
	CreatedAt            time.Time          `db:"created_at" json:"created_at"`
	UpdatedAt            time.Time          `db:"updated_at" json:"updated_at"`

	// App Store / Google Play entitlement as last reported by RevenueCat.
	StoreStatus       SubscriptionStatus `db:"rc_status" json:"-"`
	StoreProductID    string             `db:"rc_product_id" json:"-"`
	Store             string             `db:"rc_store" json:"-"`
	StoreExpiresAt    *time.Time         `db:"rc_expires_at" json:"-"`
	StoreIsTrial      bool               `db:"rc_is_trial" json:"-"`
	StoreWillRenew    bool               `db:"rc_will_renew" json:"-"`
	StoreBillingIssue bool               `db:"rc_billing_issue" json:"-"`
	StoreAsOf         *time.Time         `db:"rc_as_of" json:"-"`

	// TrialConsumed is set once the user ever had a live subscription or
	// trial from any source; the web free trial is offered only before.
	TrialConsumed bool `db:"trial_consumed" json:"-"`
}

// IsPremium reports whether the user currently has premium access from
// any source.
func (s *Subscription) IsPremium() bool {
	return s.StripePremium() || s.StorePremium()
}

// StripePremium reports whether the Stripe (web) subscription is live.
func (s *Subscription) StripePremium() bool {
	if s.Status != StatusActive && s.Status != StatusTrialing {
		return false
	}
	// Even when the status wasn't flipped to expired (e.g. a missed or
	// late billing webhook), a subscription whose expiry has already
	// passed must not grant premium access.
	return !s.IsExpired()
}

// StorePremium reports whether the App Store / Google Play entitlement
// (via RevenueCat) is live.
func (s *Subscription) StorePremium() bool {
	if s.StoreStatus != StatusActive && s.StoreStatus != StatusTrialing {
		return false
	}
	return s.StoreExpiresAt == nil || time.Now().Before(*s.StoreExpiresAt)
}

// IsTrialing reports whether the premium access currently in effect is a
// free trial.
func (s *Subscription) IsTrialing() bool {
	_, _, trial, _ := s.Entitlement()
	return trial
}

// IsExpired reports whether the Stripe subscription's expiry has passed.
func (s *Subscription) IsExpired() bool {
	if s.ExpiresAt == nil {
		return false
	}
	return time.Now().After(*s.ExpiresAt)
}

// Entitlement describes the premium access in effect: its source
// (SourceStripe / SourceRevenueCat, "" when not premium), when it ends
// (nil = no known end), whether it is a free trial and the plan. When both
// sources are live the store one wins — it's the one the mobile app can
// manage.
func (s *Subscription) Entitlement() (source string, expiresAt *time.Time, isTrial bool, plan PlanType) {
	switch {
	case s.StorePremium():
		return SourceRevenueCat, s.StoreExpiresAt, s.StoreIsTrial || s.StoreStatus == StatusTrialing,
			PlanTypeForProduct(s.StoreProductID)
	case s.StripePremium():
		exp := s.ExpiresAt
		if exp == nil {
			exp = s.CurrentPeriodEnd
		}
		return SourceStripe, exp, s.Status == StatusTrialing, s.PlanType
	}
	return "", nil, false, s.PlanType
}

// PlanTypeForProduct guesses the billing period from a store product id
// (e.g. "lively_premium_yearly", "lively_annual:p1y"). Defaults to monthly.
func PlanTypeForProduct(productID string) PlanType {
	p := strings.ToLower(productID)
	for _, hint := range []string{"year", "annual", "p1y", "12m"} {
		if strings.Contains(p, hint) {
			return PlanYearly
		}
	}
	return PlanMonthly
}

// StoreSubscriptionState is a snapshot of a user's App Store / Google Play
// entitlement, as reported by RevenueCat (REST API or webhook payload).
type StoreSubscriptionState struct {
	// AppUserID is the RevenueCat app_user_id (our user UUID).
	AppUserID string
	// Status is StatusActive, StatusTrialing or StatusExpired.
	Status       SubscriptionStatus
	ProductID    string
	Store        string
	ExpiresAt    *time.Time
	IsTrial      bool
	WillRenew    bool
	BillingIssue bool
	// AsOf is when this snapshot was true. Older snapshots never overwrite
	// newer ones.
	AsOf time.Time
}

// Premium reports whether the snapshot grants premium at time now.
func (st StoreSubscriptionState) Premium(now time.Time) bool {
	if st.Status != StatusActive && st.Status != StatusTrialing {
		return false
	}
	return st.ExpiresAt == nil || now.Before(*st.ExpiresAt)
}
