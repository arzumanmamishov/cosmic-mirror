package domain

import (
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

type Subscription struct {
	ID           uuid.UUID          `db:"id" json:"id"`
	UserID       uuid.UUID          `db:"user_id" json:"user_id"`
	RevenueCatID string             `db:"revenuecat_id" json:"-"`
	PlanType     PlanType           `db:"plan_type" json:"plan_type"`
	Status       SubscriptionStatus `db:"status" json:"status"`
	ExpiresAt    *time.Time         `db:"expires_at" json:"expires_at"`
	TrialEndAt   *time.Time         `db:"trial_end_at" json:"trial_end_at"`
	CreatedAt    time.Time          `db:"created_at" json:"created_at"`
	UpdatedAt    time.Time          `db:"updated_at" json:"updated_at"`
}

func (s *Subscription) IsPremium() bool {
	return s.Status == StatusActive || s.Status == StatusTrialing
}

func (s *Subscription) IsTrialing() bool {
	return s.Status == StatusTrialing
}

func (s *Subscription) IsExpired() bool {
	if s.ExpiresAt == nil {
		return false
	}
	return time.Now().After(*s.ExpiresAt)
}
