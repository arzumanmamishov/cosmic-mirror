package domain

import (
	"errors"
	"testing"
	"time"
)

func intPtr(v int) *int { return &v }

func TestStripeSettingsOverrideValidate(t *testing.T) {
	tests := []struct {
		name    string
		in      StripeSettingsOverride
		wantErr bool
	}{
		{"empty means defaults", StripeSettingsOverride{}, false},
		{"valid prices and trial", StripeSettingsOverride{PriceMonthly: "price_123", PriceYearly: "price_456", YearlyTrialDays: intPtr(7)}, false},
		{"trial off", StripeSettingsOverride{YearlyTrialDays: intPtr(0)}, false},
		{"max trial", StripeSettingsOverride{YearlyTrialDays: intPtr(MaxYearlyTrialDays)}, false},
		{"product id instead of price", StripeSettingsOverride{PriceMonthly: "prod_123"}, true},
		{"price with whitespace inside", StripeSettingsOverride{PriceYearly: "price_1 23"}, true},
		{"negative trial", StripeSettingsOverride{YearlyTrialDays: intPtr(-1)}, true},
		{"trial too long", StripeSettingsOverride{YearlyTrialDays: intPtr(MaxYearlyTrialDays + 1)}, true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := tt.in.Validate()
			if (err != nil) != tt.wantErr {
				t.Fatalf("Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
			if err != nil && !errors.Is(err, ErrValidation) {
				t.Errorf("error %v doesn't wrap ErrValidation", err)
			}
		})
	}
}

func TestStripeSettingsOverrideNormalize(t *testing.T) {
	o := StripeSettingsOverride{PriceMonthly: "  price_abc \n", PriceYearly: "\tprice_def"}
	o.Normalize()
	if o.PriceMonthly != "price_abc" || o.PriceYearly != "price_def" {
		t.Fatalf("Normalize() = %+v", o)
	}
	if err := o.Validate(); err != nil {
		t.Fatalf("normalized override should validate: %v", err)
	}
}

func TestStripeSettingsOverrideApply(t *testing.T) {
	defaults := StripeSettings{PriceMonthly: "price_env_m", PriceYearly: "price_env_y", YearlyTrialDays: DefaultYearlyTrialDays}

	if got := (StripeSettingsOverride{}).Apply(defaults); got != defaults {
		t.Errorf("empty override: got %+v, want defaults %+v", got, defaults)
	}

	got := StripeSettingsOverride{PriceYearly: "price_new_y", YearlyTrialDays: intPtr(0)}.Apply(defaults)
	want := StripeSettings{PriceMonthly: "price_env_m", PriceYearly: "price_new_y", YearlyTrialDays: 0}
	if got != want {
		t.Errorf("partial override: got %+v, want %+v", got, want)
	}
}

func TestStripePriceValidateForPlan(t *testing.T) {
	monthly := StripePrice{ID: "price_m", Active: true, Interval: "month", IntervalCount: 1}
	yearly := StripePrice{ID: "price_y", Active: true, Interval: "year", IntervalCount: 1}

	if err := monthly.ValidateForPlan(PlanMonthly); err != nil {
		t.Errorf("monthly price for monthly plan: %v", err)
	}
	if err := yearly.ValidateForPlan(PlanYearly); err != nil {
		t.Errorf("yearly price for yearly plan: %v", err)
	}

	bad := []struct {
		name  string
		price StripePrice
		plan  PlanType
	}{
		{"yearly price on monthly plan", yearly, PlanMonthly},
		{"monthly price on yearly plan", monthly, PlanYearly},
		{"archived", StripePrice{ID: "price_x", Active: false, Interval: "month", IntervalCount: 1}, PlanMonthly},
		{"one-time", StripePrice{ID: "price_x", Active: true}, PlanMonthly},
		{"every 3 months", StripePrice{ID: "price_x", Active: true, Interval: "month", IntervalCount: 3}, PlanMonthly},
		{"weekly", StripePrice{ID: "price_x", Active: true, Interval: "week", IntervalCount: 1}, PlanMonthly},
	}
	for _, tt := range bad {
		err := tt.price.ValidateForPlan(tt.plan)
		if err == nil || !errors.Is(err, ErrValidation) {
			t.Errorf("%s: want a validation error, got %v", tt.name, err)
		}
	}
}

func TestPremiumSummary(t *testing.T) {
	future := time.Now().Add(72 * time.Hour)
	past := time.Now().Add(-time.Hour)

	if got := PremiumSummary(nil); got.Active {
		t.Errorf("no subscription row: %+v", got)
	}

	web := PremiumSummary(&Subscription{Status: StatusActive, ExpiresAt: &future, PlanType: PlanYearly, CancelAtPeriodEnd: true})
	if !web.Active || web.Channel != PremiumChannelWeb || web.Plan != PlanYearly || web.WillRenew || web.Trial {
		t.Errorf("web subscription: %+v", web)
	}

	store := PremiumSummary(&Subscription{
		StoreStatus: StatusTrialing, Store: "APP_STORE", StoreProductID: "lively_premium_yearly",
		StoreExpiresAt: &future, StoreWillRenew: true,
	})
	if !store.Active || store.Channel != PremiumChannelAppStore || store.Plan != PlanYearly || !store.Trial || !store.WillRenew {
		t.Errorf("app store trial: %+v", store)
	}

	// Both live: the store wins, like Subscription.Entitlement.
	both := PremiumSummary(&Subscription{
		Status: StatusActive, ExpiresAt: &future, PlanType: PlanMonthly,
		StoreStatus: StatusActive, Store: "play_store", StoreProductID: "lively_premium_monthly", StoreExpiresAt: &future,
	})
	if both.Channel != PremiumChannelPlayStore {
		t.Errorf("both live: channel = %q, want play_store", both.Channel)
	}

	expired := PremiumSummary(&Subscription{Status: StatusActive, ExpiresAt: &past, StoreStatus: StatusExpired})
	if expired.Active {
		t.Errorf("expired subscription reported active: %+v", expired)
	}
}

func TestAdminUserRowSubscription(t *testing.T) {
	if (AdminUserRow{}).Subscription() != nil || (AdminUserRow{}).SubscriptionDetail() != nil {
		t.Fatal("a user without a subscriptions row must have no subscription")
	}
	future := time.Now().Add(time.Hour)
	cus := "cus_123"
	row := AdminUserRow{HasSubscription: true, Status: "active", ExpiresAt: &future, PlanType: "monthly", StripeCustomerID: &cus}
	if got := row.Summary().Premium; !got.Active || got.Channel != PremiumChannelWeb {
		t.Errorf("premium = %+v", got)
	}
	if d := row.SubscriptionDetail(); d.StripeCustomerID != cus || d.StripeStatus != "active" {
		t.Errorf("detail = %+v", d)
	}
}

func TestValidAdminUserFilter(t *testing.T) {
	for _, f := range []string{"all", "premium", "free", "trial", "web", "app_store", "play_store", "banned"} {
		if !ValidAdminUserFilter(f) {
			t.Errorf("%q should be valid", f)
		}
	}
	for _, f := range []string{"", "everyone", "PREMIUM"} {
		if ValidAdminUserFilter(f) {
			t.Errorf("%q should be invalid", f)
		}
	}
}
