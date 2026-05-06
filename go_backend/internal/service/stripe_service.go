package service

import (
	"context"
	"fmt"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
	"github.com/stripe/stripe-go/v76"
	"github.com/stripe/stripe-go/v76/customer"
	stripewebhook "github.com/stripe/stripe-go/v76/webhook"

	stripesub "github.com/stripe/stripe-go/v76/subscription"
)

// StripeService is the gateway between the app and Stripe's billing API.
// It owns three flows:
//
//  1. Subscribe — creates (or reuses) a Stripe Customer, opens a
//     Subscription with payment_behavior=default_incomplete, returns the
//     PaymentIntent client_secret + ephemeral key so the mobile Payment
//     Sheet can complete the first charge in-app.
//
//  2. Webhook — verifies Stripe signatures and reconciles subscription
//     state into our DB so the rest of the backend can authorize Premium
//     features without a network round-trip.
//
//  3. Cancel — flags the subscription to terminate at period end so the
//     user keeps Premium until the paid period elapses.
type StripeService struct {
	subRepo        repository.SubscriptionRepository
	userSvc        *UserService
	secretKey      string
	publishableKey string
	webhookSecret  string
	priceMonthly   string
	priceYearly    string
}

func NewStripeService(
	subRepo repository.SubscriptionRepository,
	userSvc *UserService,
	secretKey, publishableKey, webhookSecret, priceMonthly, priceYearly string,
) *StripeService {
	stripe.Key = secretKey
	return &StripeService{
		subRepo:        subRepo,
		userSvc:        userSvc,
		secretKey:      secretKey,
		publishableKey: publishableKey,
		webhookSecret:  webhookSecret,
		priceMonthly:   priceMonthly,
		priceYearly:    priceYearly,
	}
}

// Configured reports whether the service has the minimum env wired up.
// Called from the handler so we can return a clean 503 before the SDK
// barfs an opaque "no api key" error.
func (s *StripeService) Configured() bool {
	return s.secretKey != "" && s.publishableKey != "" &&
		(s.priceMonthly != "" || s.priceYearly != "")
}

// PaymentSheetParams is the bundle the Flutter Stripe payment sheet needs
// to render itself. Sent back to the client after a Subscribe call.
type PaymentSheetParams struct {
	PublishableKey string `json:"publishable_key"`
	CustomerID     string `json:"customer_id"`
	EphemeralKey   string `json:"ephemeral_key"`
	ClientSecret   string `json:"client_secret"`
	SubscriptionID string `json:"subscription_id"`
}

// Subscribe creates (or reuses) a Stripe customer for the given user and
// opens an incomplete subscription against the requested price. Returns
// the params the mobile Payment Sheet needs to confirm the first charge.
//
// planType picks between monthly/yearly using the configured price IDs.
func (s *StripeService) Subscribe(
	ctx context.Context,
	userID uuid.UUID,
	planType domain.PlanType,
) (*PaymentSheetParams, error) {
	if !s.Configured() {
		return nil, fmt.Errorf("stripe is not configured on this server")
	}

	priceID := s.priceMonthly
	if planType == domain.PlanYearly {
		priceID = s.priceYearly
	}
	if priceID == "" {
		return nil, fmt.Errorf("no price id configured for plan %q", planType)
	}

	user, err := s.userSvc.GetUser(ctx, userID)
	if err != nil || user == nil {
		return nil, fmt.Errorf("user not found")
	}

	// Reuse the customer id we stashed from a previous subscribe attempt
	// so we don't litter Stripe with one customer per tap of "Subscribe".
	existing, _ := s.subRepo.GetByUserID(ctx, userID)
	var customerID string
	if existing != nil && existing.StripeCustomerID != nil && *existing.StripeCustomerID != "" {
		customerID = *existing.StripeCustomerID
	} else {
		c, err := customer.New(&stripe.CustomerParams{
			Email: stripe.String(user.Email),
			Name:  stripe.String(user.Name),
			Metadata: map[string]string{
				"user_id": userID.String(),
			},
		})
		if err != nil {
			return nil, fmt.Errorf("create customer: %w", err)
		}
		customerID = c.ID
	}

	// Create the subscription "incomplete" so the first charge happens
	// through the mobile Payment Sheet rather than via a saved card.
	subParams := &stripe.SubscriptionParams{
		Customer: stripe.String(customerID),
		Items: []*stripe.SubscriptionItemsParams{
			{Price: stripe.String(priceID)},
		},
		PaymentBehavior: stripe.String("default_incomplete"),
		PaymentSettings: &stripe.SubscriptionPaymentSettingsParams{
			SaveDefaultPaymentMethod: stripe.String("on_subscription"),
		},
	}
	subParams.AddExpand("latest_invoice.payment_intent")

	sub, err := stripesub.New(subParams)
	if err != nil {
		return nil, fmt.Errorf("create subscription: %w", err)
	}

	if sub.LatestInvoice == nil || sub.LatestInvoice.PaymentIntent == nil {
		return nil, fmt.Errorf("stripe did not return a payment intent on the new subscription")
	}
	clientSecret := sub.LatestInvoice.PaymentIntent.ClientSecret

	// Stash everything we know — the webhook will fill in current_period_end
	// and flip status to active when the first invoice succeeds.
	row := domain.Subscription{
		UserID:               userID,
		StripeCustomerID:     stripe.String(customerID),
		StripeSubscriptionID: stripe.String(sub.ID),
		PriceID:              stripe.String(priceID),
		PlanType:             planType,
		Status:               mapStripeStatus(sub.Status),
		CurrentPeriodEnd:     timePtrFromUnix(sub.CurrentPeriodEnd),
		ExpiresAt:            timePtrFromUnix(sub.CurrentPeriodEnd),
		CancelAtPeriodEnd:    sub.CancelAtPeriodEnd,
	}
	if existing != nil {
		row.ID = existing.ID
		row.RevenueCatID = existing.RevenueCatID
		row.CreatedAt = existing.CreatedAt
	}
	if err := s.subRepo.Upsert(ctx, &row); err != nil {
		return nil, fmt.Errorf("persist subscription row: %w", err)
	}

	// EphemeralKey lets the Payment Sheet fetch the customer's saved
	// payment methods without giving the client our secret API key.
	ek, err := newEphemeralKey(customerID)
	if err != nil {
		return nil, fmt.Errorf("create ephemeral key: %w", err)
	}

	return &PaymentSheetParams{
		PublishableKey: s.publishableKey,
		CustomerID:     customerID,
		EphemeralKey:   ek,
		ClientSecret:   clientSecret,
		SubscriptionID: sub.ID,
	}, nil
}

// Cancel marks the user's active subscription to end at period end so
// they keep Premium until the period they already paid for elapses.
func (s *StripeService) Cancel(ctx context.Context, userID uuid.UUID) error {
	row, err := s.subRepo.GetByUserID(ctx, userID)
	if err != nil || row == nil || row.StripeSubscriptionID == nil {
		return fmt.Errorf("no active subscription to cancel")
	}
	_, err = stripesub.Update(*row.StripeSubscriptionID, &stripe.SubscriptionParams{
		CancelAtPeriodEnd: stripe.Bool(true),
	})
	return err
}

// HandleStripeWebhook verifies + applies a Stripe webhook payload. We
// listen for the small set of events that change billing state:
//   - customer.subscription.created / updated
//   - customer.subscription.deleted
//   - invoice.payment_succeeded   (renewal that succeeded)
//   - invoice.payment_failed      (renewal that didn't)
//
// Anything else is acked with 200 so Stripe doesn't retry.
func (s *StripeService) HandleStripeWebhook(
	ctx context.Context,
	payload []byte,
	signatureHeader string,
) error {
	if s.webhookSecret == "" {
		return fmt.Errorf("stripe webhook secret not configured")
	}

	event, err := stripewebhook.ConstructEvent(payload, signatureHeader, s.webhookSecret)
	if err != nil {
		return fmt.Errorf("invalid stripe signature: %w", err)
	}

	switch event.Type {
	case "customer.subscription.created",
		"customer.subscription.updated",
		"customer.subscription.deleted":
		return s.applySubscriptionEvent(ctx, event)
	case "invoice.payment_succeeded", "invoice.payment_failed":
		// We re-fetch the subscription from Stripe to get the current
		// state — invoice events include the subscription id but not
		// the full sub object.
		var inv stripe.Invoice
		if err := stripeUnmarshalEventData(event, &inv); err != nil {
			return err
		}
		if inv.Subscription == nil {
			return nil
		}
		sub, err := stripesub.Get(inv.Subscription.ID, nil)
		if err != nil {
			return fmt.Errorf("fetch sub on invoice event: %w", err)
		}
		return s.applySubscriptionRecord(ctx, sub)
	}
	return nil // unhandled event types are fine
}

func (s *StripeService) applySubscriptionEvent(ctx context.Context, event stripe.Event) error {
	var sub stripe.Subscription
	if err := stripeUnmarshalEventData(event, &sub); err != nil {
		return err
	}
	return s.applySubscriptionRecord(ctx, &sub)
}

func (s *StripeService) applySubscriptionRecord(ctx context.Context, sub *stripe.Subscription) error {
	priceID := ""
	planType := domain.PlanMonthly
	if sub.Items != nil && len(sub.Items.Data) > 0 {
		item := sub.Items.Data[0]
		if item.Price != nil {
			priceID = item.Price.ID
			if item.Price.Recurring != nil && item.Price.Recurring.Interval == "year" {
				planType = domain.PlanYearly
			}
		}
	}
	return s.subRepo.UpdateFromStripe(
		ctx,
		sub.ID,
		mapStripeStatus(sub.Status),
		priceID,
		planType,
		timePtrFromUnix(sub.CurrentPeriodEnd),
		sub.CancelAtPeriodEnd,
	)
}

func mapStripeStatus(s stripe.SubscriptionStatus) domain.SubscriptionStatus {
	switch s {
	case stripe.SubscriptionStatusActive:
		return domain.StatusActive
	case stripe.SubscriptionStatusTrialing:
		return domain.StatusTrialing
	case stripe.SubscriptionStatusCanceled:
		return domain.StatusCancelled
	case stripe.SubscriptionStatusPastDue,
		stripe.SubscriptionStatusUnpaid,
		stripe.SubscriptionStatusIncompleteExpired:
		return domain.StatusExpired
	default:
		// `incomplete` lives here too — the user has a subscription row
		// but hasn't completed first payment yet.
		return domain.StatusExpired
	}
}

func timePtrFromUnix(secs int64) *time.Time {
	if secs == 0 {
		return nil
	}
	t := time.Unix(secs, 0)
	return &t
}
