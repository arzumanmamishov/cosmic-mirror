package service

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
	"github.com/stripe/stripe-go/v76"
)

var (
	rcNow    = time.Date(2026, 10, 4, 12, 0, 0, 0, time.UTC)
	rcUser   = uuid.MustParse("6f1c2b1e-3c55-4d3a-9a0e-1b2c3d4e5f60")
	rcUser2  = uuid.MustParse("0a7d9a64-0d7f-4c8e-8f0f-2b0b5e7f9c11")
	rcFuture = rcNow.Add(72 * time.Hour)
	rcPast   = rcNow.Add(-time.Hour)
)

func ms(t time.Time) int64 { return t.UnixMilli() }

func event(typ string, mut func(*revenueCatEvent)) revenueCatEvent {
	ev := revenueCatEvent{
		ID:               "evt",
		Type:             typ,
		EventTimestampMs: ms(rcNow.Add(-time.Minute)),
		AppUserID:        rcUser.String(),
		ProductID:        "lively_premium_yearly",
		EntitlementIDs:   []string{"premium"},
		PeriodType:       "NORMAL",
		ExpirationAtMs:   ms(rcFuture),
		Store:            "APP_STORE",
	}
	if mut != nil {
		mut(&ev)
	}
	return ev
}

func applyEvent(t *testing.T, ev revenueCatEvent) (domain.StoreSubscriptionState, bool) {
	t.Helper()
	targets := revenueCatTargets(ev)
	if len(targets) != 1 {
		t.Fatalf("targets = %d, want 1", len(targets))
	}
	return storeStateFromEvent(ev, targets[0], "premium", rcNow)
}

func TestStoreStateFromEvent(t *testing.T) {
	tests := []struct {
		name        string
		ev          revenueCatEvent
		wantOK      bool
		wantStatus  domain.SubscriptionStatus
		wantPremium bool
		wantTrial   bool
		wantRenew   bool
		wantBilling bool
		wantExpiry  *time.Time
	}{
		{
			name:   "initial purchase",
			ev:     event("INITIAL_PURCHASE", nil),
			wantOK: true, wantStatus: domain.StatusActive, wantPremium: true, wantRenew: true,
			wantExpiry: &rcFuture,
		},
		{
			name: "initial purchase in free trial",
			ev: event("INITIAL_PURCHASE", func(e *revenueCatEvent) {
				e.PeriodType = "TRIAL"
			}),
			wantOK: true, wantStatus: domain.StatusTrialing, wantPremium: true, wantTrial: true, wantRenew: true,
		},
		{
			name:   "renewal",
			ev:     event("RENEWAL", nil),
			wantOK: true, wantStatus: domain.StatusActive, wantPremium: true, wantRenew: true,
		},
		{
			name:   "product change",
			ev:     event("PRODUCT_CHANGE", nil),
			wantOK: true, wantStatus: domain.StatusActive, wantPremium: true, wantRenew: true,
		},
		{
			name:   "uncancellation",
			ev:     event("UNCANCELLATION", nil),
			wantOK: true, wantStatus: domain.StatusActive, wantPremium: true, wantRenew: true,
		},
		{
			name: "non-renewing purchase without expiry is lifetime",
			ev: event("NON_RENEWING_PURCHASE", func(e *revenueCatEvent) {
				e.ExpirationAtMs = 0
			}),
			wantOK: true, wantStatus: domain.StatusActive, wantPremium: true,
		},
		{
			name:   "cancellation keeps access until period end",
			ev:     event("CANCELLATION", nil),
			wantOK: true, wantStatus: domain.StatusActive, wantPremium: true, wantRenew: false,
			wantExpiry: &rcFuture,
		},
		{
			name: "cancellation of a trial keeps trial until it ends",
			ev: event("CANCELLATION", func(e *revenueCatEvent) {
				e.PeriodType = "TRIAL"
			}),
			wantOK: true, wantStatus: domain.StatusTrialing, wantPremium: true, wantTrial: true,
		},
		{
			name: "refund (cancellation with past expiry) revokes",
			ev: event("CANCELLATION", func(e *revenueCatEvent) {
				e.ExpirationAtMs = ms(rcPast)
			}),
			wantOK: true, wantStatus: domain.StatusExpired, wantPremium: false,
		},
		{
			name:   "expiration",
			ev:     event("EXPIRATION", func(e *revenueCatEvent) { e.ExpirationAtMs = ms(rcPast) }),
			wantOK: true, wantStatus: domain.StatusExpired, wantPremium: false,
			wantExpiry: &rcPast,
		},
		{
			name:   "expiration with a future expiry still revokes",
			ev:     event("EXPIRATION", nil),
			wantOK: true, wantStatus: domain.StatusExpired, wantPremium: false,
			wantExpiry: &rcNow,
		},
		{
			name: "billing issue inside grace period keeps access",
			ev: event("BILLING_ISSUE", func(e *revenueCatEvent) {
				e.ExpirationAtMs = ms(rcPast)
				e.GracePeriodExpirationAtMs = ms(rcFuture)
			}),
			wantOK: true, wantStatus: domain.StatusActive, wantPremium: true, wantRenew: true, wantBilling: true,
			wantExpiry: &rcFuture,
		},
		{
			name: "billing issue without grace period",
			ev: event("BILLING_ISSUE", func(e *revenueCatEvent) {
				e.ExpirationAtMs = ms(rcPast)
			}),
			wantOK: true, wantStatus: domain.StatusExpired, wantPremium: false, wantRenew: true, wantBilling: true,
		},
		{
			name:   "subscription paused keeps access until expiry",
			ev:     event("SUBSCRIPTION_PAUSED", nil),
			wantOK: true, wantStatus: domain.StatusActive, wantPremium: true,
		},
		{
			name: "other entitlement is ignored",
			ev: event("INITIAL_PURCHASE", func(e *revenueCatEvent) {
				e.EntitlementIDs = []string{"coins"}
			}),
			wantOK: false,
		},
		{
			name: "subscription event without expiry is ignored",
			ev: event("RENEWAL", func(e *revenueCatEvent) {
				e.ExpirationAtMs = 0
			}),
			wantOK: false,
		},
		{
			name:   "unhandled type",
			ev:     event("SUBSCRIBER_ALIAS", nil),
			wantOK: false,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			targets := revenueCatTargets(tt.ev)
			if len(targets) != 1 {
				t.Fatalf("targets = %d, want 1", len(targets))
			}
			st, ok := storeStateFromEvent(tt.ev, targets[0], "premium", rcNow)
			if ok != tt.wantOK {
				t.Fatalf("ok = %v, want %v", ok, tt.wantOK)
			}
			if !ok {
				return
			}
			if st.Status != tt.wantStatus {
				t.Errorf("status = %q, want %q", st.Status, tt.wantStatus)
			}
			if got := st.Premium(rcNow); got != tt.wantPremium {
				t.Errorf("premium = %v, want %v", got, tt.wantPremium)
			}
			if st.IsTrial != tt.wantTrial {
				t.Errorf("trial = %v, want %v", st.IsTrial, tt.wantTrial)
			}
			if st.WillRenew != tt.wantRenew {
				t.Errorf("willRenew = %v, want %v", st.WillRenew, tt.wantRenew)
			}
			if st.BillingIssue != tt.wantBilling {
				t.Errorf("billingIssue = %v, want %v", st.BillingIssue, tt.wantBilling)
			}
			if tt.wantExpiry != nil && (st.ExpiresAt == nil || !st.ExpiresAt.Equal(*tt.wantExpiry)) {
				t.Errorf("expiresAt = %v, want %v", st.ExpiresAt, *tt.wantExpiry)
			}
			if st.AppUserID != rcUser.String() || st.ProductID != "lively_premium_yearly" || st.Store != "app_store" {
				t.Errorf("identity fields = %+v", st)
			}
			if want := time.UnixMilli(tt.ev.EventTimestampMs).UTC(); !st.AsOf.Equal(want) {
				t.Errorf("asOf = %v, want event time %v", st.AsOf, want)
			}
		})
	}
}

func TestStoreStateFromEventIsDeterministic(t *testing.T) {
	ev := event("RENEWAL", nil)
	a, _ := applyEvent(t, ev)
	b, _ := applyEvent(t, ev)
	if a.Status != b.Status || !a.AsOf.Equal(b.AsOf) || !a.ExpiresAt.Equal(*b.ExpiresAt) {
		t.Fatalf("same event produced different states: %+v vs %+v", a, b)
	}
}

func TestRevenueCatTargets(t *testing.T) {
	t.Run("app user id", func(t *testing.T) {
		got := revenueCatTargets(event("RENEWAL", nil))
		if len(got) != 1 || got[0].UserID != rcUser {
			t.Fatalf("got %+v", got)
		}
	})
	t.Run("anonymous id falls back to alias", func(t *testing.T) {
		got := revenueCatTargets(event("INITIAL_PURCHASE", func(e *revenueCatEvent) {
			e.AppUserID = "$RCAnonymousID:8f0e1c"
			e.OriginalAppUserID = "$RCAnonymousID:8f0e1c"
			e.Aliases = []string{"$RCAnonymousID:8f0e1c", rcUser.String()}
		}))
		if len(got) != 1 || got[0].UserID != rcUser || got[0].AppUserID != rcUser.String() {
			t.Fatalf("got %+v", got)
		}
	})
	t.Run("anonymous only is ignored", func(t *testing.T) {
		got := revenueCatTargets(event("INITIAL_PURCHASE", func(e *revenueCatEvent) {
			e.AppUserID = "$RCAnonymousID:8f0e1c"
			e.OriginalAppUserID = ""
		}))
		if len(got) != 0 {
			t.Fatalf("got %+v", got)
		}
	})
	t.Run("non-uuid id is ignored", func(t *testing.T) {
		got := revenueCatTargets(event("RENEWAL", func(e *revenueCatEvent) {
			e.AppUserID = "someone@example.com"
		}))
		if len(got) != 0 {
			t.Fatalf("got %+v", got)
		}
	})
	t.Run("transfer touches both sides", func(t *testing.T) {
		ev := event("TRANSFER", func(e *revenueCatEvent) {
			e.AppUserID = ""
			e.TransferredFrom = []string{rcUser.String(), "$RCAnonymousID:1"}
			e.TransferredTo = []string{rcUser2.String()}
		})
		got := revenueCatTargets(ev)
		if len(got) != 2 {
			t.Fatalf("got %+v", got)
		}
		if got[0].UserID != rcUser2 || got[0].LostAccess {
			t.Errorf("recipient = %+v", got[0])
		}
		if got[1].UserID != rcUser || !got[1].LostAccess {
			t.Errorf("source = %+v", got[1])
		}
		// Payload-only mode: the source loses access, the recipient waits
		// for authoritative state (the payload has no expiry for it).
		if st, ok := storeStateFromEvent(ev, got[1], "premium", rcNow); !ok || st.Premium(rcNow) {
			t.Errorf("source state = %+v ok=%v, want applied non-premium", st, ok)
		}
		if _, ok := storeStateFromEvent(ev, got[0], "premium", rcNow); ok {
			t.Error("recipient state applied from payload, want skipped")
		}
	})
}

func TestStoreStateFromSubscriber(t *testing.T) {
	const body = `{
	  "request_date_ms": 1791115200000,
	  "subscriber": {
	    "entitlements": {
	      "premium": {
	        "expires_date": "2026-10-07T12:00:00Z",
	        "grace_period_expires_date": null,
	        "product_identifier": "lively_premium_yearly",
	        "purchase_date": "2026-10-04T11:00:00Z"
	      }
	    },
	    "subscriptions": {
	      "lively_premium_yearly": {
	        "expires_date": "2026-10-07T12:00:00Z",
	        "period_type": "trial",
	        "store": "app_store",
	        "unsubscribe_detected_at": null,
	        "billing_issues_detected_at": null,
	        "is_sandbox": true
	      }
	    }
	  }
	}`
	var resp revenueCatSubscriber
	if err := json.Unmarshal([]byte(body), &resp); err != nil {
		t.Fatal(err)
	}

	st := storeStateFromSubscriber(resp, rcUser.String(), "premium", rcNow)
	if st.Status != domain.StatusTrialing || !st.IsTrial || !st.WillRenew || st.BillingIssue {
		t.Fatalf("state = %+v", st)
	}
	if st.Store != "app_store" || st.ProductID != "lively_premium_yearly" {
		t.Fatalf("state = %+v", st)
	}
	if want := time.Date(2026, 10, 7, 12, 0, 0, 0, time.UTC); st.ExpiresAt == nil || !st.ExpiresAt.Equal(want) {
		t.Fatalf("expiresAt = %v", st.ExpiresAt)
	}
	if want := time.UnixMilli(1791115200000).UTC(); !st.AsOf.Equal(want) {
		t.Fatalf("asOf = %v, want request date", st.AsOf)
	}

	t.Run("expired entitlement", func(t *testing.T) {
		later := time.Date(2026, 10, 8, 0, 0, 0, 0, time.UTC)
		st := storeStateFromSubscriber(resp, rcUser.String(), "premium", later)
		if st.Status != domain.StatusExpired || st.Premium(later) || st.IsTrial {
			t.Fatalf("state = %+v", st)
		}
	})

	t.Run("grace period extends access", func(t *testing.T) {
		r := resp
		grace := time.Date(2026, 10, 20, 0, 0, 0, 0, time.UTC)
		e := r.Subscriber.Entitlements["premium"]
		e.GracePeriodExpiresDate = &grace
		r.Subscriber.Entitlements = map[string]struct {
			ExpiresDate            *time.Time `json:"expires_date"`
			GracePeriodExpiresDate *time.Time `json:"grace_period_expires_date"`
			ProductIdentifier      string     `json:"product_identifier"`
		}{"premium": e}
		later := time.Date(2026, 10, 10, 0, 0, 0, 0, time.UTC)
		st := storeStateFromSubscriber(r, rcUser.String(), "premium", later)
		if !st.Premium(later) || !st.ExpiresAt.Equal(grace) {
			t.Fatalf("state = %+v", st)
		}
	})

	t.Run("no entitlement", func(t *testing.T) {
		var empty revenueCatSubscriber
		st := storeStateFromSubscriber(empty, rcUser.String(), "premium", rcNow)
		if st.Status != domain.StatusExpired || st.Premium(rcNow) || st.ProductID != "" {
			t.Fatalf("state = %+v", st)
		}
	})
}

func TestSubscriptionPremiumEitherSource(t *testing.T) {
	past := time.Now().Add(-24 * time.Hour)
	stripeActive := domain.Subscription{Status: domain.StatusActive, ExpiresAt: ptr(time.Now().Add(time.Hour))}
	storeActive := domain.Subscription{Status: domain.StatusExpired, StoreStatus: domain.StatusTrialing,
		StoreExpiresAt: ptr(time.Now().Add(time.Hour)), StoreIsTrial: true, StoreProductID: "lively_premium_yearly"}
	both := stripeActive
	both.StoreStatus, both.StoreExpiresAt = domain.StatusExpired, &past
	none := domain.Subscription{Status: domain.StatusCancelled, StoreStatus: domain.StatusExpired}

	if !stripeActive.IsPremium() {
		t.Error("stripe active should be premium")
	}
	if src, _, _, _ := stripeActive.Entitlement(); src != domain.SourceStripe {
		t.Errorf("source = %q", src)
	}
	if !storeActive.IsPremium() || !storeActive.IsTrialing() {
		t.Error("store trial should be premium + trialing")
	}
	if src, _, trial, plan := storeActive.Entitlement(); src != domain.SourceRevenueCat || !trial || plan != domain.PlanYearly {
		t.Errorf("entitlement = %q %v %q", src, trial, plan)
	}
	if !both.IsPremium() {
		t.Error("an expired store entitlement must not revoke an active Stripe subscription")
	}
	if none.IsPremium() {
		t.Error("nothing active should not be premium")
	}
}

func ptr[T any](v T) *T { return &v }

func TestStripeAccessStatus(t *testing.T) {
	trialNoCard := &stripe.Subscription{Status: stripe.SubscriptionStatusTrialing}
	if got := stripeAccessStatus(trialNoCard); got != domain.StatusExpired {
		t.Errorf("trial without card = %q, want expired", got)
	}
	trialWithCard := &stripe.Subscription{Status: stripe.SubscriptionStatusTrialing,
		DefaultPaymentMethod: &stripe.PaymentMethod{ID: "pm_1"}}
	if got := stripeAccessStatus(trialWithCard); got != domain.StatusTrialing {
		t.Errorf("trial with card = %q, want trialing", got)
	}
	if got := stripeAccessStatus(&stripe.Subscription{Status: stripe.SubscriptionStatusActive}); got != domain.StatusActive {
		t.Errorf("active = %q", got)
	}
	if stripeSubscriptionHadAccess(&stripe.Subscription{Status: stripe.SubscriptionStatusCanceled}) {
		t.Error("canceled checkout without a card should not consume the trial")
	}
	if !stripeSubscriptionHadAccess(&stripe.Subscription{Status: stripe.SubscriptionStatusCanceled,
		DefaultPaymentMethod: &stripe.PaymentMethod{ID: "pm_1"}}) {
		t.Error("canceled paid subscription should consume the trial")
	}
}

// fakeSubRepo records ApplyStoreState calls; the other methods are unused.
type fakeSubRepo struct {
	repository.SubscriptionRepository
	applied map[uuid.UUID]domain.StoreSubscriptionState
}

func (f *fakeSubRepo) ApplyStoreState(_ context.Context, userID uuid.UUID, st domain.StoreSubscriptionState) (bool, error) {
	if prev, ok := f.applied[userID]; ok && prev.AsOf.After(st.AsOf) {
		return false, nil
	}
	f.applied[userID] = st
	return true, nil
}

func TestHandleWebhook(t *testing.T) {
	const secret = "whsec-test"
	body := func(ev revenueCatEvent) []byte {
		b, _ := json.Marshal(revenueCatWebhook{Event: ev})
		return b
	}

	t.Run("rejects bad or missing secret", func(t *testing.T) {
		svc := NewSubscriptionService(&fakeSubRepo{applied: map[uuid.UUID]domain.StoreSubscriptionState{}}, secret)
		err := svc.HandleWebhook(context.Background(), body(event("RENEWAL", nil)), "Bearer nope")
		if !errors.Is(err, ErrWebhookUnauthorized) {
			t.Fatalf("err = %v", err)
		}
		unconfigured := NewSubscriptionService(&fakeSubRepo{}, "")
		if err := unconfigured.HandleWebhook(context.Background(), body(event("RENEWAL", nil)), ""); !errors.Is(err, ErrWebhookUnauthorized) {
			t.Fatalf("unconfigured err = %v", err)
		}
	})

	t.Run("rejects malformed body", func(t *testing.T) {
		svc := NewSubscriptionService(&fakeSubRepo{applied: map[uuid.UUID]domain.StoreSubscriptionState{}}, secret)
		if err := svc.HandleWebhook(context.Background(), []byte("{"), secret); !errors.Is(err, ErrWebhookMalformed) {
			t.Fatalf("err = %v", err)
		}
	})

	t.Run("payload mode applies and is idempotent; stale events lose", func(t *testing.T) {
		repo := &fakeSubRepo{applied: map[uuid.UUID]domain.StoreSubscriptionState{}}
		svc := NewSubscriptionService(repo, secret)
		svc.now = func() time.Time { return rcNow }
		renewal := body(event("RENEWAL", nil))
		for i := 0; i < 2; i++ {
			if err := svc.HandleWebhook(context.Background(), renewal, secret); err != nil {
				t.Fatal(err)
			}
		}
		// An EXPIRATION that happened before the renewal arrives late.
		late := body(event("EXPIRATION", func(e *revenueCatEvent) {
			e.EventTimestampMs = ms(rcNow.Add(-time.Hour))
		}))
		if err := svc.HandleWebhook(context.Background(), late, secret); err != nil {
			t.Fatal(err)
		}
		if st := repo.applied[rcUser]; !st.Premium(rcNow) {
			t.Fatalf("state = %+v, want premium", st)
		}
	})

	t.Run("REST mode uses the subscriber record", func(t *testing.T) {
		var gotPath, gotAuth string
		srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			gotPath, gotAuth = r.URL.Path, r.Header.Get("Authorization")
			_, _ = w.Write([]byte(`{"request_date_ms": ` + strconv.FormatInt(ms(rcNow), 10) + `,
			  "subscriber": {"entitlements": {}, "subscriptions": {"lively_premium_monthly": {"store": "play_store"}}}}`))
		}))
		defer srv.Close()
		repo := &fakeSubRepo{applied: map[uuid.UUID]domain.StoreSubscriptionState{}}
		svc := NewSubscriptionService(repo, secret).WithRevenueCatAPI("sk_test", "")
		svc.rc.baseURL = srv.URL
		svc.now = func() time.Time { return rcNow }
		// The payload claims an active purchase, but RevenueCat says the
		// entitlement is gone: the REST answer wins.
		if err := svc.HandleWebhook(context.Background(), body(event("INITIAL_PURCHASE", nil)), "Bearer "+secret); err != nil {
			t.Fatal(err)
		}
		if gotPath != "/subscribers/"+rcUser.String() || gotAuth != "Bearer sk_test" {
			t.Fatalf("request = %q auth=%q", gotPath, gotAuth)
		}
		st := repo.applied[rcUser]
		if st.Premium(rcNow) || st.ProductID != "lively_premium_monthly" {
			t.Fatalf("state = %+v", st)
		}
	})

	t.Run("REST failure is returned so RevenueCat retries", func(t *testing.T) {
		srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.WriteHeader(http.StatusBadGateway)
		}))
		defer srv.Close()
		svc := NewSubscriptionService(&fakeSubRepo{applied: map[uuid.UUID]domain.StoreSubscriptionState{}}, secret).
			WithRevenueCatAPI("sk_test", "premium")
		svc.rc.baseURL = srv.URL
		err := svc.HandleWebhook(context.Background(), body(event("RENEWAL", nil)), secret)
		if err == nil || errors.Is(err, ErrWebhookUnauthorized) || errors.Is(err, ErrWebhookMalformed) {
			t.Fatalf("err = %v, want transient error", err)
		}
	})
}
