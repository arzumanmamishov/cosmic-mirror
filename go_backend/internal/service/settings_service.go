package service

import (
	"context"
	"encoding/json"
	"fmt"
	"log/slog"

	"cosmic-mirror/internal/domain"

	"github.com/google/uuid"
)

// SettingsStore persists the runtime settings (app_settings).
type SettingsStore interface {
	GetSetting(ctx context.Context, key string) (*domain.StoredSetting, error)
	PutSetting(ctx context.Context, key string, value []byte, updatedBy uuid.UUID) error
}

// SettingsService serves the settings an admin can change at runtime.
// Today that's the Stripe web-checkout prices and the yearly free trial:
// the admin's saved values win, and anything left empty falls back to the
// server's env defaults (STRIPE_PRICE_MONTHLY / STRIPE_PRICE_YEARLY).
//
// Settings are read from the database on every use (one primary-key
// lookup), so a change takes effect immediately on every API instance.
type SettingsService struct {
	store          SettingsStore
	stripeDefaults domain.StripeSettings
}

func NewSettingsService(store SettingsStore, stripeDefaults domain.StripeSettings) *SettingsService {
	return &SettingsService{store: store, stripeDefaults: stripeDefaults}
}

// StripeDefaults are the env-configured values used when no override is
// saved.
func (s *SettingsService) StripeDefaults() domain.StripeSettings { return s.stripeDefaults }

// Stripe returns the effective Stripe settings. It never fails: when the
// saved override can't be read it logs and returns the defaults.
func (s *SettingsService) Stripe(ctx context.Context) domain.StripeSettings {
	o, _, err := s.StripeOverride(ctx)
	if err != nil {
		slog.Error("settings: read stripe override; using server defaults", "error", err)
		return s.stripeDefaults
	}
	return o.Apply(s.stripeDefaults)
}

// StripeOverride returns what an admin saved (zero value when nothing
// was) and the stored row, which is nil when nothing was saved.
func (s *SettingsService) StripeOverride(ctx context.Context) (domain.StripeSettingsOverride, *domain.StoredSetting, error) {
	var o domain.StripeSettingsOverride
	row, err := s.store.GetSetting(ctx, domain.SettingKeyStripe)
	if err != nil {
		return o, nil, fmt.Errorf("load stripe settings: %w", err)
	}
	if row == nil {
		return o, nil, nil
	}
	if err := json.Unmarshal([]byte(row.Value), &o); err != nil {
		return domain.StripeSettingsOverride{}, row, fmt.Errorf("decode stripe settings: %w", err)
	}
	return o, row, nil
}

// SaveStripeOverride validates and stores a Stripe override. The caller
// (AdminService) checks the price IDs against Stripe first.
func (s *SettingsService) SaveStripeOverride(ctx context.Context, o domain.StripeSettingsOverride, adminID uuid.UUID) error {
	o.Normalize()
	if err := o.Validate(); err != nil {
		return err
	}
	body, err := json.Marshal(o)
	if err != nil {
		return err
	}
	return s.store.PutSetting(ctx, domain.SettingKeyStripe, body, adminID)
}
