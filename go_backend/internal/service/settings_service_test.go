package service

import (
	"context"
	"encoding/json"
	"errors"
	"strings"
	"testing"
	"time"

	"cosmic-mirror/internal/domain"

	"github.com/google/uuid"
)

type fakeSettingsStore struct {
	rows   map[string]*domain.StoredSetting
	getErr error
}

func (f *fakeSettingsStore) GetSetting(_ context.Context, key string) (*domain.StoredSetting, error) {
	if f.getErr != nil {
		return nil, f.getErr
	}
	return f.rows[key], nil
}

func (f *fakeSettingsStore) PutSetting(_ context.Context, key string, value []byte, _ uuid.UUID) error {
	if f.rows == nil {
		f.rows = map[string]*domain.StoredSetting{}
	}
	f.rows[key] = &domain.StoredSetting{Key: key, Value: string(value), UpdatedAt: time.Now()}
	return nil
}

var testStripeDefaults = domain.StripeSettings{
	PriceMonthly: "price_env_m", PriceYearly: "price_env_y", YearlyTrialDays: domain.DefaultYearlyTrialDays,
}

func TestSettingsServiceStripeDefaultsWhenNothingSaved(t *testing.T) {
	svc := NewSettingsService(&fakeSettingsStore{}, testStripeDefaults)
	if got := svc.Stripe(context.Background()); got != testStripeDefaults {
		t.Fatalf("Stripe() = %+v, want defaults", got)
	}
}

func TestSettingsServiceSaveAndRead(t *testing.T) {
	store := &fakeSettingsStore{}
	svc := NewSettingsService(store, testStripeDefaults)
	trial := 7
	err := svc.SaveStripeOverride(context.Background(),
		domain.StripeSettingsOverride{PriceMonthly: " price_new_m ", YearlyTrialDays: &trial}, uuid.New())
	if err != nil {
		t.Fatal(err)
	}
	got := svc.Stripe(context.Background())
	want := domain.StripeSettings{PriceMonthly: "price_new_m", PriceYearly: "price_env_y", YearlyTrialDays: 7}
	if got != want {
		t.Fatalf("Stripe() = %+v, want %+v", got, want)
	}

	// Stored as JSON the next read (and other instances) can decode.
	var stored domain.StripeSettingsOverride
	if err := json.Unmarshal([]byte(store.rows[domain.SettingKeyStripe].Value), &stored); err != nil {
		t.Fatalf("stored value isn't JSON: %v", err)
	}
	if stored.PriceMonthly != "price_new_m" {
		t.Errorf("stored price = %q (should be trimmed)", stored.PriceMonthly)
	}
}

func TestSettingsServiceRejectsInvalid(t *testing.T) {
	svc := NewSettingsService(&fakeSettingsStore{}, testStripeDefaults)
	err := svc.SaveStripeOverride(context.Background(), domain.StripeSettingsOverride{PriceYearly: "prod_123"}, uuid.New())
	if !errors.Is(err, domain.ErrValidation) {
		t.Fatalf("want a validation error, got %v", err)
	}
}

func TestSettingsServiceFallsBackOnReadError(t *testing.T) {
	svc := NewSettingsService(&fakeSettingsStore{getErr: errors.New("db down")}, testStripeDefaults)
	if got := svc.Stripe(context.Background()); got != testStripeDefaults {
		t.Fatalf("Stripe() on a read error = %+v, want defaults", got)
	}
}

func TestStripeKeyHintNeverLeaksTheKey(t *testing.T) {
	// A fake key, built at runtime so secret scanners don't flag it.
	key := "sk_" + "live_" + strings.Repeat("x", 24) + "a1b2"
	hint := stripeKeyHint(key)
	if hint != "sk_live_…a1b2" {
		t.Errorf("hint = %q", hint)
	}
	if stripeKeyMode(key) != "live" || stripeKeyMode("sk_test_abc") != "test" || stripeKeyMode("") != "" {
		t.Error("stripeKeyMode mismatch")
	}
	if got := stripeKeyHint("short"); got == "short" {
		t.Error("a short value must not be echoed back")
	}
}
