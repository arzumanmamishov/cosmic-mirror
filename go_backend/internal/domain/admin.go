package domain

import (
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
)

// ===== Runtime settings (app_settings) =====

// SettingKeyStripe is the app_settings key of the Stripe checkout settings.
const SettingKeyStripe = "stripe"

const (
	// DefaultYearlyTrialDays is the free trial on the yearly web plan when
	// no admin override is saved — the same 3-day trial the App Store and
	// Google Play run as an introductory offer on the yearly product.
	DefaultYearlyTrialDays = 3
	// MaxYearlyTrialDays caps what an admin can set.
	MaxYearlyTrialDays = 30
)

// StripeSettings are the effective web-checkout settings: what an admin
// saved, falling back to the server's env defaults.
type StripeSettings struct {
	PriceMonthly    string `json:"price_monthly"`
	PriceYearly     string `json:"price_yearly"`
	YearlyTrialDays int    `json:"yearly_trial_days"`
}

// StripeSettingsOverride is what an admin saved under app_settings
// "stripe". An empty price or a nil trial means "use the server default".
type StripeSettingsOverride struct {
	PriceMonthly    string `json:"price_monthly"`
	PriceYearly     string `json:"price_yearly"`
	YearlyTrialDays *int   `json:"yearly_trial_days"`
}

// Normalize trims the price IDs.
func (o *StripeSettingsOverride) Normalize() {
	o.PriceMonthly = strings.TrimSpace(o.PriceMonthly)
	o.PriceYearly = strings.TrimSpace(o.PriceYearly)
}

// Validate checks the shape of the override. It doesn't ask Stripe whether
// the prices exist; the admin service does that before saving. Errors
// wrap ErrValidation → 400.
func (o StripeSettingsOverride) Validate() error {
	for _, p := range []struct{ label, id string }{
		{"Monthly price", o.PriceMonthly},
		{"Yearly price", o.PriceYearly},
	} {
		if p.id == "" {
			continue
		}
		if !strings.HasPrefix(p.id, "price_") || len(p.id) > 255 || strings.ContainsAny(p.id, " \t\r\n") {
			return fmt.Errorf("%w: %s must be a Stripe price ID (it starts with price_)", ErrValidation, p.label)
		}
	}
	if o.YearlyTrialDays != nil && (*o.YearlyTrialDays < 0 || *o.YearlyTrialDays > MaxYearlyTrialDays) {
		return fmt.Errorf("%w: free trial must be between 0 and %d days", ErrValidation, MaxYearlyTrialDays)
	}
	return nil
}

// Apply returns the effective settings: o's values over [defaults].
func (o StripeSettingsOverride) Apply(defaults StripeSettings) StripeSettings {
	out := defaults
	if o.PriceMonthly != "" {
		out.PriceMonthly = o.PriceMonthly
	}
	if o.PriceYearly != "" {
		out.PriceYearly = o.PriceYearly
	}
	if o.YearlyTrialDays != nil {
		out.YearlyTrialDays = *o.YearlyTrialDays
	}
	return out
}

// StoredSetting is one app_settings row. Value is the raw JSON document.
type StoredSetting struct {
	Key       string    `db:"key"`
	Value     string    `db:"value"`
	UpdatedAt time.Time `db:"updated_at"`
	// UpdatedBy is the e-mail of the admin who saved it ("" when that
	// account no longer exists).
	UpdatedBy string `db:"updated_by"`
}

// StripePrice is a recurring Stripe price an admin can pick for a plan.
type StripePrice struct {
	ID            string `json:"id"`
	Nickname      string `json:"nickname,omitempty"`
	LookupKey     string `json:"lookup_key,omitempty"`
	ProductID     string `json:"product_id,omitempty"`
	ProductName   string `json:"product_name,omitempty"`
	UnitAmount    int64  `json:"unit_amount"` // minor units (cents)
	Currency      string `json:"currency"`
	Interval      string `json:"interval"` // day | week | month | year
	IntervalCount int64  `json:"interval_count"`
	Active        bool   `json:"active"`
	Livemode      bool   `json:"livemode"`
}

// ValidateForPlan checks that the price can back [plan]: active, and
// billing once a month (monthly) or once a year (yearly). Errors wrap
// ErrValidation → 400.
func (p StripePrice) ValidateForPlan(plan PlanType) error {
	want := "month"
	if plan == PlanYearly {
		want = "year"
	}
	if !p.Active {
		return fmt.Errorf("%w: %s price %s is archived in Stripe; pick an active price", ErrValidation, plan, p.ID)
	}
	if p.Interval == "" {
		return fmt.Errorf("%w: %s price %s is a one-time price; pick a recurring price", ErrValidation, plan, p.ID)
	}
	if p.Interval != want || p.IntervalCount != 1 {
		return fmt.Errorf("%w: %s price must bill every %s, but %s bills every %d %s",
			ErrValidation, plan, want, p.ID, p.IntervalCount, p.Interval)
	}
	return nil
}

// ===== Dashboard statistics =====

// AdminUserStats counts accounts. Active users are those who opened the
// app (a session refresh) in the window.
type AdminUserStats struct {
	Total     int `db:"total"      json:"total"`
	New1d     int `db:"new_1d"     json:"new_1d"`
	New7d     int `db:"new_7d"     json:"new_7d"`
	New30d    int `db:"new_30d"    json:"new_30d"`
	Onboarded int `db:"onboarded"  json:"onboarded"`
	Banned    int `db:"banned"     json:"banned"`
	Active1d  int `db:"active_1d"  json:"active_1d"`
	Active7d  int `db:"active_7d"  json:"active_7d"`
	Active30d int `db:"active_30d" json:"active_30d"`
}

// AdminPremiumStats counts users with premium right now. Each user is
// counted once, under the source that grants their access (the store wins
// when both are live, as in Subscription.Entitlement).
type AdminPremiumStats struct {
	Total         int `db:"total"          json:"total"`
	Stripe        int `db:"stripe"         json:"stripe"`
	AppStore      int `db:"app_store"      json:"app_store"`
	PlayStore     int `db:"play_store"     json:"play_store"`
	OtherStore    int `db:"other_store"    json:"other_store"`
	Monthly       int `db:"-"              json:"monthly"`
	Yearly        int `db:"yearly"         json:"yearly"`
	Trialing      int `db:"trialing"       json:"trialing"`
	Cancelling    int `db:"cancelling"     json:"cancelling"`
	BillingIssues int `db:"billing_issues" json:"billing_issues"`
}

// AdminContentStats counts community content and feature usage.
type AdminContentStats struct {
	Spaces                 int `db:"spaces"                   json:"spaces"`
	Posts                  int `db:"posts"                    json:"posts"`
	Posts7d                int `db:"posts_7d"                 json:"posts_7d"`
	Comments               int `db:"comments"                 json:"comments"`
	Comments7d             int `db:"comments_7d"              json:"comments_7d"`
	AIMessages7d           int `db:"ai_messages_7d"           json:"ai_messages_7d"`
	JournalEntries7d       int `db:"journal_entries_7d"       json:"journal_entries_7d"`
	CompatibilityReports7d int `db:"compatibility_reports_7d" json:"compatibility_reports_7d"`
	OpenReports            int `db:"open_reports"             json:"open_reports"`
}

// DayCount is one point of a daily series. Day is YYYY-MM-DD (UTC).
type DayCount struct {
	Day   string `db:"day"   json:"day"`
	Count int    `db:"count" json:"count"`
}

// AdminStats is the dashboard payload.
type AdminStats struct {
	GeneratedAt time.Time         `json:"generated_at"`
	Users       AdminUserStats    `json:"users"`
	Premium     AdminPremiumStats `json:"premium"`
	Content     AdminContentStats `json:"content"`
	Signups     []DayCount        `json:"signups"`
	ActiveUsers []DayCount        `json:"active_users"`
}

// ===== Customers =====

// Customer-list filters.
const (
	AdminUserFilterAll       = "all"
	AdminUserFilterPremium   = "premium"
	AdminUserFilterFree      = "free"
	AdminUserFilterTrial     = "trial"
	AdminUserFilterWeb       = "web"
	AdminUserFilterAppStore  = "app_store"
	AdminUserFilterPlayStore = "play_store"
	AdminUserFilterBanned    = "banned"
)

// ValidAdminUserFilter reports whether f is a known customer-list filter.
func ValidAdminUserFilter(f string) bool {
	switch f {
	case AdminUserFilterAll, AdminUserFilterPremium, AdminUserFilterFree, AdminUserFilterTrial,
		AdminUserFilterWeb, AdminUserFilterAppStore, AdminUserFilterPlayStore, AdminUserFilterBanned:
		return true
	}
	return false
}

// AdminUserQuery is the customer-list query.
type AdminUserQuery struct {
	// Search matches e-mail or name (substring), or exactly a user ID or a
	// Stripe customer ID.
	Search string
	Filter string
	Limit  int
	Offset int
}

// AdminUserRow is a user joined with their subscriptions row, as read for
// the admin panel. The subscription columns are zero-valued when the user
// has no row.
type AdminUserRow struct {
	ID              uuid.UUID  `db:"id"`
	Email           string     `db:"email"`
	Name            string     `db:"name"`
	AvatarURL       *string    `db:"avatar_url"`
	CreatedAt       time.Time  `db:"created_at"`
	LastLoginAt     *time.Time `db:"last_login_at"`
	EmailVerifiedAt *time.Time `db:"email_verified_at"`
	BannedAt        *time.Time `db:"banned_at"`
	LastSeenAt      *time.Time `db:"last_seen_at"`

	HasSubscription      bool       `db:"has_subscription"`
	Status               string     `db:"status"`
	ExpiresAt            *time.Time `db:"expires_at"`
	CurrentPeriodEnd     *time.Time `db:"current_period_end"`
	PlanType             string     `db:"plan_type"`
	CancelAtPeriodEnd    bool       `db:"cancel_at_period_end"`
	TrialEndAt           *time.Time `db:"trial_end_at"`
	StripeCustomerID     *string    `db:"stripe_customer_id"`
	StripeSubscriptionID *string    `db:"stripe_subscription_id"`
	PriceID              *string    `db:"price_id"`
	RevenueCatID         string     `db:"revenuecat_id"`
	StoreStatus          string     `db:"rc_status"`
	StoreProductID       string     `db:"rc_product_id"`
	Store                string     `db:"rc_store"`
	StoreExpiresAt       *time.Time `db:"rc_expires_at"`
	StoreIsTrial         bool       `db:"rc_is_trial"`
	StoreWillRenew       bool       `db:"rc_will_renew"`
	StoreBillingIssue    bool       `db:"rc_billing_issue"`
	StoreAsOf            *time.Time `db:"rc_as_of"`
	TrialConsumed        bool       `db:"trial_consumed"`
}

// Subscription rebuilds the domain subscription so the premium rules live
// in one place (Subscription.Entitlement). Nil when the user has no row.
func (r AdminUserRow) Subscription() *Subscription {
	if !r.HasSubscription {
		return nil
	}
	return &Subscription{
		UserID:               r.ID,
		RevenueCatID:         r.RevenueCatID,
		StripeCustomerID:     r.StripeCustomerID,
		StripeSubscriptionID: r.StripeSubscriptionID,
		PriceID:              r.PriceID,
		PlanType:             PlanType(r.PlanType),
		Status:               SubscriptionStatus(r.Status),
		ExpiresAt:            r.ExpiresAt,
		CurrentPeriodEnd:     r.CurrentPeriodEnd,
		CancelAtPeriodEnd:    r.CancelAtPeriodEnd,
		TrialEndAt:           r.TrialEndAt,
		StoreStatus:          SubscriptionStatus(r.StoreStatus),
		StoreProductID:       r.StoreProductID,
		Store:                r.Store,
		StoreExpiresAt:       r.StoreExpiresAt,
		StoreIsTrial:         r.StoreIsTrial,
		StoreWillRenew:       r.StoreWillRenew,
		StoreBillingIssue:    r.StoreBillingIssue,
		StoreAsOf:            r.StoreAsOf,
		TrialConsumed:        r.TrialConsumed,
	}
}

// Where premium is bought, as shown in the admin panel.
const (
	PremiumChannelWeb       = "web" // Stripe checkout
	PremiumChannelAppStore  = "app_store"
	PremiumChannelPlayStore = "play_store"
)

// AdminPremium summarises a user's premium access.
type AdminPremium struct {
	Active bool `json:"active"`
	// Channel is web | app_store | play_store | another RevenueCat store
	// id; "" when not premium.
	Channel   string     `json:"channel,omitempty"`
	Plan      PlanType   `json:"plan,omitempty"`
	Trial     bool       `json:"trial"`
	ExpiresAt *time.Time `json:"expires_at,omitempty"`
	WillRenew bool       `json:"will_renew"`
}

// PremiumSummary describes the premium access a subscription grants now.
func PremiumSummary(s *Subscription) AdminPremium {
	if s == nil {
		return AdminPremium{}
	}
	source, expires, trial, plan := s.Entitlement()
	switch source {
	case SourceRevenueCat:
		channel := strings.ToLower(strings.TrimSpace(s.Store))
		if channel == "" {
			channel = "store"
		}
		return AdminPremium{Active: true, Channel: channel, Plan: plan, Trial: trial,
			ExpiresAt: expires, WillRenew: s.StoreWillRenew}
	case SourceStripe:
		return AdminPremium{Active: true, Channel: PremiumChannelWeb, Plan: plan, Trial: trial,
			ExpiresAt: expires, WillRenew: !s.CancelAtPeriodEnd}
	}
	return AdminPremium{}
}

// AdminUserSummary is one row of the customer list.
type AdminUserSummary struct {
	ID          uuid.UUID    `json:"id"`
	Email       string       `json:"email"`
	Name        string       `json:"name"`
	AvatarURL   *string      `json:"avatar_url,omitempty"`
	CreatedAt   time.Time    `json:"created_at"`
	LastLoginAt *time.Time   `json:"last_login_at,omitempty"`
	LastSeenAt  *time.Time   `json:"last_seen_at,omitempty"`
	BannedAt    *time.Time   `json:"banned_at,omitempty"`
	Premium     AdminPremium `json:"premium"`
}

// Summary converts a row for the customer list.
func (r AdminUserRow) Summary() AdminUserSummary {
	return AdminUserSummary{
		ID: r.ID, Email: r.Email, Name: r.Name, AvatarURL: r.AvatarURL,
		CreatedAt: r.CreatedAt, LastLoginAt: r.LastLoginAt, LastSeenAt: r.LastSeenAt,
		BannedAt: r.BannedAt, Premium: PremiumSummary(r.Subscription()),
	}
}

// AdminSubscriptionDetail is everything stored about a user's billing.
type AdminSubscriptionDetail struct {
	// Web (Stripe)
	StripeStatus            string     `json:"stripe_status"`
	StripePlan              string     `json:"stripe_plan"`
	StripePriceID           string     `json:"stripe_price_id,omitempty"`
	StripeCustomerID        string     `json:"stripe_customer_id,omitempty"`
	StripeSubscriptionID    string     `json:"stripe_subscription_id,omitempty"`
	StripeCurrentPeriodEnd  *time.Time `json:"stripe_current_period_end,omitempty"`
	StripeCancelAtPeriodEnd bool       `json:"stripe_cancel_at_period_end"`
	StripeTrialEndAt        *time.Time `json:"stripe_trial_end_at,omitempty"`
	// App Store / Google Play (RevenueCat)
	Store               string     `json:"store,omitempty"`
	StoreStatus         string     `json:"store_status,omitempty"`
	StoreProductID      string     `json:"store_product_id,omitempty"`
	StoreExpiresAt      *time.Time `json:"store_expires_at,omitempty"`
	StoreIsTrial        bool       `json:"store_is_trial"`
	StoreWillRenew      bool       `json:"store_will_renew"`
	StoreBillingIssue   bool       `json:"store_billing_issue"`
	StoreUpdatedAt      *time.Time `json:"store_updated_at,omitempty"`
	RevenueCatAppUserID string     `json:"revenuecat_app_user_id,omitempty"`

	TrialConsumed bool `json:"trial_consumed"`
}

// SubscriptionDetail returns the billing detail, nil without a row.
func (r AdminUserRow) SubscriptionDetail() *AdminSubscriptionDetail {
	if !r.HasSubscription {
		return nil
	}
	deref := func(p *string) string {
		if p == nil {
			return ""
		}
		return *p
	}
	return &AdminSubscriptionDetail{
		StripeStatus:            r.Status,
		StripePlan:              r.PlanType,
		StripePriceID:           deref(r.PriceID),
		StripeCustomerID:        deref(r.StripeCustomerID),
		StripeSubscriptionID:    deref(r.StripeSubscriptionID),
		StripeCurrentPeriodEnd:  r.CurrentPeriodEnd,
		StripeCancelAtPeriodEnd: r.CancelAtPeriodEnd,
		StripeTrialEndAt:        r.TrialEndAt,
		Store:                   r.Store,
		StoreStatus:             r.StoreStatus,
		StoreProductID:          r.StoreProductID,
		StoreExpiresAt:          r.StoreExpiresAt,
		StoreIsTrial:            r.StoreIsTrial,
		StoreWillRenew:          r.StoreWillRenew,
		StoreBillingIssue:       r.StoreBillingIssue,
		StoreUpdatedAt:          r.StoreAsOf,
		RevenueCatAppUserID:     r.RevenueCatID,
		TrialConsumed:           r.TrialConsumed,
	}
}

// AdminUserActivity counts what a user has done in the app.
type AdminUserActivity struct {
	Onboarded            bool `db:"onboarded"             json:"onboarded"`
	ActiveSessions       int  `db:"active_sessions"       json:"active_sessions"`
	AIThreads            int  `db:"ai_threads"            json:"ai_threads"`
	AIMessages           int  `db:"ai_messages"           json:"ai_messages"`
	JournalEntries       int  `db:"journal_entries"       json:"journal_entries"`
	SavedPeople          int  `db:"saved_people"          json:"saved_people"`
	CompatibilityReports int  `db:"compatibility_reports" json:"compatibility_reports"`
	Posts                int  `db:"posts"                 json:"posts"`
	Comments             int  `db:"comments"              json:"comments"`
	SpacesCreated        int  `db:"spaces_created"        json:"spaces_created"`
	ReportsFiled         int  `db:"reports_filed"         json:"reports_filed"`
	// ReportsAgainst counts reports on the user, their posts and comments.
	ReportsAgainst     int `db:"reports_against"      json:"reports_against"`
	OpenReportsAgainst int `db:"open_reports_against" json:"open_reports_against"`
}

// AdminUserDetail is the customer page.
type AdminUserDetail struct {
	AdminUserSummary
	EmailVerifiedAt *time.Time               `json:"email_verified_at,omitempty"`
	IsAdmin         bool                     `json:"is_admin"`
	Subscription    *AdminSubscriptionDetail `json:"subscription"`
	Activity        AdminUserActivity        `json:"activity"`
	// StripeMode (live | test | "") lets the panel link to the right half
	// of the Stripe dashboard.
	StripeMode string `json:"stripe_mode"`
}

// ===== Audit log =====

// Admin audit actions.
const (
	AuditUserBan        = "user.ban"
	AuditUserUnban      = "user.unban"
	AuditUserDelete     = "user.delete"
	AuditStripeSettings = "settings.stripe.update"
	AuditReportResolve  = "report.resolve"
)

// AuditEntry is one admin_audit_log row.
type AuditEntry struct {
	ID          uuid.UUID       `db:"id"           json:"id"`
	AdminID     *uuid.UUID      `db:"admin_id"     json:"admin_id,omitempty"`
	AdminEmail  string          `db:"admin_email"  json:"admin_email"`
	Action      string          `db:"action"       json:"action"`
	TargetType  string          `db:"target_type"  json:"target_type"`
	TargetID    string          `db:"target_id"    json:"target_id"`
	DetailsJSON string          `db:"details"      json:"-"`
	Details     json.RawMessage `db:"-"            json:"details"`
	CreatedAt   time.Time       `db:"created_at"   json:"created_at"`
}
