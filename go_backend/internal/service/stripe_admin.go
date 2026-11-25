package service

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"cosmic-mirror/internal/domain"

	"github.com/stripe/stripe-go/v76"
	"github.com/stripe/stripe-go/v76/price"
)

// ErrStripeNotConfigured: STRIPE_SECRET_KEY is empty, so Stripe can't be
// queried.
var ErrStripeNotConfigured = errors.New("stripe is not configured on this server")

// StripeStatus says how Stripe is wired on this server, for the admin
// panel. It never contains a secret: the secret key is reduced to its
// mode prefix and last four characters.
type StripeStatus struct {
	// Mode is live | test | unknown, or "" when no secret key is set.
	Mode             string `json:"mode"`
	SecretKeySet     bool   `json:"secret_key_set"`
	SecretKeyHint    string `json:"secret_key_hint,omitempty"`
	PublishableKey   string `json:"publishable_key,omitempty"`
	WebhookSecretSet bool   `json:"webhook_secret_set"`
	// CheckoutReady is Configured(): keys set and at least one plan priced.
	CheckoutReady bool `json:"checkout_ready"`
}

// Status reports the Stripe configuration.
func (s *StripeService) Status(ctx context.Context) StripeStatus {
	return StripeStatus{
		Mode:             stripeKeyMode(s.secretKey),
		SecretKeySet:     s.secretKey != "",
		SecretKeyHint:    stripeKeyHint(s.secretKey),
		PublishableKey:   s.publishableKey,
		WebhookSecretSet: s.webhookSecret != "",
		CheckoutReady:    s.Configured(ctx),
	}
}

// stripeKeyMode reads live/test from a secret (sk_) or restricted (rk_)
// key's prefix.
func stripeKeyMode(key string) string {
	switch {
	case key == "":
		return ""
	case strings.HasPrefix(key, "sk_live_"), strings.HasPrefix(key, "rk_live_"):
		return "live"
	case strings.HasPrefix(key, "sk_test_"), strings.HasPrefix(key, "rk_test_"):
		return "test"
	}
	return "unknown"
}

// stripeKeyHint shows enough of a secret key to recognise it
// ("sk_live_…a1b2") and nothing more.
func stripeKeyHint(key string) string {
	if key == "" {
		return ""
	}
	if len(key) < 16 {
		return "set (too short to be a real key)"
	}
	prefix := key[:3]
	for _, p := range []string{"sk_live_", "sk_test_", "rk_live_", "rk_test_"} {
		if strings.HasPrefix(key, p) {
			prefix = p
			break
		}
	}
	return prefix + "…" + key[len(key)-4:]
}

// maxListedPrices bounds how many prices the admin price picker loads.
const maxListedPrices = 200

// ListPrices returns the account's active recurring prices, newest first.
func (s *StripeService) ListPrices(ctx context.Context) ([]domain.StripePrice, error) {
	if s.secretKey == "" {
		return nil, ErrStripeNotConfigured
	}
	params := &stripe.PriceListParams{
		Active: stripe.Bool(true),
		Type:   stripe.String(string(stripe.PriceTypeRecurring)),
	}
	params.Context = ctx
	params.Limit = stripe.Int64(100)
	params.AddExpand("data.product")
	out := []domain.StripePrice{}
	it := price.List(params)
	for it.Next() {
		out = append(out, toDomainPrice(it.Price()))
		if len(out) >= maxListedPrices {
			break
		}
	}
	if err := it.Err(); err != nil {
		return nil, fmt.Errorf("list stripe prices: %w", err)
	}
	return out, nil
}

// GetPrice looks up one price. Returns nil, nil when Stripe has no such
// price in this key's mode (a test-mode ID with a live key is "missing").
func (s *StripeService) GetPrice(ctx context.Context, id string) (*domain.StripePrice, error) {
	if s.secretKey == "" {
		return nil, ErrStripeNotConfigured
	}
	params := &stripe.PriceParams{Params: stripe.Params{Context: ctx}}
	params.AddExpand("product")
	p, err := price.Get(id, params)
	if isStripeResourceMissing(err) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("get stripe price: %w", err)
	}
	dp := toDomainPrice(p)
	return &dp, nil
}

func toDomainPrice(p *stripe.Price) domain.StripePrice {
	out := domain.StripePrice{
		ID:         p.ID,
		Nickname:   p.Nickname,
		LookupKey:  p.LookupKey,
		UnitAmount: p.UnitAmount,
		Currency:   string(p.Currency),
		Active:     p.Active,
		Livemode:   p.Livemode,
	}
	if p.Recurring != nil {
		out.Interval = string(p.Recurring.Interval)
		out.IntervalCount = p.Recurring.IntervalCount
	}
	if p.Product != nil {
		out.ProductID = p.Product.ID
		out.ProductName = p.Product.Name
		// An archived product's prices can't be bought either.
		if p.Product.Name != "" && !p.Product.Active {
			out.Active = false
		}
	}
	return out
}
