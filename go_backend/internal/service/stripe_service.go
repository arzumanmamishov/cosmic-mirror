package service

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net/http"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
	"github.com/stripe/stripe-go/v76"
	"github.com/stripe/stripe-go/v76/customer"
	stripewebhook "github.com/stripe/stripe-go/v76/webhook"

	stripesub "github.com/stripe/stripe-go/v76/subscription"
)

// StripeService is the gateway between the website and Stripe's billing
// API. It is the WEB purchase path only: the mobile apps must sell through
// App Store / Google Play (RevenueCat, see SubscriptionService). It owns
// three flows:
//
//  1. Subscribe — creates (or reuses) a Stripe Customer, opens a
//     Subscription with payment_behavior=default_incomplete, returns the
//     PaymentIntent (or, for a free trial, SetupIntent) client_secret +
//     ephemeral key so a Stripe payment form can complete it.
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

// PaymentSheetParams is the bundle a Stripe payment sheet / Payment
// Element needs to render itself. Sent back to the client after a
// Subscribe call.
type PaymentSheetParams struct {
	PublishableKey string `json:"publishable_key"`
	CustomerID     string `json:"customer_id"`
	EphemeralKey   string `json:"ephemeral_key"`
	ClientSecret   string `json:"client_secret"`
	SubscriptionID string `json:"subscription_id"`
	// IntentType says what ClientSecret belongs to: "payment" (a
	// PaymentIntent for the first charge) or "setup" (a SetupIntent that
	// saves the card for a free trial — nothing is charged until the trial
	// ends).
	IntentType string `json:"intent_type"`
	// TrialDays is the free trial granted on this subscription (0 = none).
	TrialDays int `json:"trial_days,omitempty"`
}

const (
	intentTypePayment = "payment"
	intentTypeSetup   = "setup"
)

// yearlyTrialDays is the free trial on the yearly plan, offered once per
// user (see trialEligible) — the same 3-day trial the stores run as an
// introductory offer on the yearly product.
const yearlyTrialDays = 3

// Sentinel errors the Stripe handler maps to 409 Conflict.
var (
	// ErrAlreadySubscribed: the user already has a live (active/trialing,
	// or past-due) subscription — creating another would double-bill.
	ErrAlreadySubscribed = errors.New("user already has an active subscription")
	// ErrSubscriptionPaymentPending: the first payment of the user's
	// pending subscription is still processing; wait for it to settle.
	ErrSubscriptionPaymentPending = errors.New("subscription payment is still processing")
)

// Subscribe creates (or reuses) a Stripe customer for the given user and
// opens an incomplete subscription against the requested price. Returns
// the params the mobile Payment Sheet needs to confirm the first charge.
//
// Guards against duplicate subscriptions:
//   - a user who is currently premium gets ErrAlreadySubscribed;
//   - an existing `incomplete` Stripe subscription (user tapped Subscribe,
//     then dismissed the sheet) is reused when it's for the same price,
//     otherwise cancelled before a new one is created;
//   - the row is only overwritten if it isn't premium at write time.
//
// planType picks between monthly/yearly using the configured price IDs.
// The yearly plan starts with a yearlyTrialDays free trial for users who
// never had a subscription or trial before; the card is then collected
// with a SetupIntent and the first charge happens when the trial ends.
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

	existing, err := s.subRepo.GetByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("load subscription: %w", err)
	}
	if existing != nil && existing.IsPremium() {
		return nil, ErrAlreadySubscribed
	}

	// Reuse the customer id we stashed from a previous subscribe attempt
	// so we don't litter Stripe with one customer per tap of "Subscribe".
	var customerID string
	reusedCustomer := false
	if existing != nil && existing.StripeCustomerID != nil && *existing.StripeCustomerID != "" {
		customerID = *existing.StripeCustomerID
		reusedCustomer = true
	} else {
		c, err := customer.New(&stripe.CustomerParams{
			Params: stripe.Params{Context: ctx},
			Email:  stripe.String(user.Email),
			Name:   stripe.String(user.Name),
			Metadata: map[string]string{
				"user_id": userID.String(),
			},
		})
		if err != nil {
			return nil, fmt.Errorf("create customer: %w", err)
		}
		customerID = c.ID
	}

	// A previous Stripe subscription may still be alive even though our
	// row says non-premium (abandoned payment sheet, or a missed webhook).
	if existing != nil && existing.StripeSubscriptionID != nil && *existing.StripeSubscriptionID != "" {
		params, err := s.reconcilePreviousSubscription(ctx, *existing.StripeSubscriptionID, priceID, customerID)
		if err != nil || params != nil {
			return params, err
		}
	}

	trialDays := 0
	if planType == domain.PlanYearly && s.trialEligible(ctx, existing, customerID, reusedCustomer) {
		trialDays = yearlyTrialDays
	}

	// Create the subscription "incomplete" so the first charge happens
	// through the Payment Sheet rather than via a saved card.
	subParams := &stripe.SubscriptionParams{
		Params:   stripe.Params{Context: ctx},
		Customer: stripe.String(customerID),
		Items: []*stripe.SubscriptionItemsParams{
			{Price: stripe.String(priceID)},
		},
		PaymentBehavior: stripe.String("default_incomplete"),
		PaymentSettings: &stripe.SubscriptionPaymentSettingsParams{
			SaveDefaultPaymentMethod: stripe.String("on_subscription"),
		},
		Metadata: map[string]string{"user_id": userID.String()},
	}
	subParams.AddExpand("latest_invoice.payment_intent")
	if trialDays > 0 {
		// A trial's first invoice is $0, so there is no PaymentIntent: the
		// card is saved through the subscription's pending SetupIntent.
		// Until it is (see stripeAccessStatus) the trial grants nothing,
		// and if the trial ends without a card the subscription cancels.
		subParams.TrialPeriodDays = stripe.Int64(int64(trialDays))
		subParams.TrialSettings = &stripe.SubscriptionTrialSettingsParams{
			EndBehavior: &stripe.SubscriptionTrialSettingsEndBehaviorParams{
				MissingPaymentMethod: stripe.String(string(stripe.SubscriptionTrialSettingsEndBehaviorMissingPaymentMethodCancel)),
			},
		}
		subParams.AddExpand("pending_setup_intent")
	}

	sub, err := stripesub.New(subParams)
	if err != nil {
		return nil, fmt.Errorf("create subscription: %w", err)
	}

	var clientSecret, intentType string
	switch {
	case trialDays > 0 && sub.PendingSetupIntent != nil && sub.PendingSetupIntent.ClientSecret != "":
		clientSecret, intentType = sub.PendingSetupIntent.ClientSecret, intentTypeSetup
	case sub.LatestInvoice != nil && sub.LatestInvoice.PaymentIntent != nil:
		clientSecret, intentType = sub.LatestInvoice.PaymentIntent.ClientSecret, intentTypePayment
	default:
		s.cancelQuietly(ctx, sub.ID)
		return nil, fmt.Errorf("stripe did not return a payment or setup intent on the new subscription")
	}

	// Stash everything we know — the webhook will fill in current_period_end
	// and flip status to active when the first invoice succeeds.
	row := domain.Subscription{
		UserID:               userID,
		StripeCustomerID:     stripe.String(customerID),
		StripeSubscriptionID: stripe.String(sub.ID),
		PriceID:              stripe.String(priceID),
		PlanType:             planType,
		Status:               stripeAccessStatus(sub),
		CurrentPeriodEnd:     timePtrFromUnix(sub.CurrentPeriodEnd),
		ExpiresAt:            timePtrFromUnix(sub.CurrentPeriodEnd),
		CancelAtPeriodEnd:    sub.CancelAtPeriodEnd,
		TrialEndAt:           timePtrFromUnix(sub.TrialEnd),
	}
	if existing != nil {
		row.ID = existing.ID
		row.RevenueCatID = existing.RevenueCatID
		row.CreatedAt = existing.CreatedAt
		row.TrialConsumed = existing.TrialConsumed
	}
	// Conditional write: if the row turned premium since we read it (e.g.
	// an App Store / Google Play purchase or a webhook landed meanwhile),
	// never replace it with this incomplete subscription — cancel the new
	// one instead.
	applied, err := s.subRepo.UpsertIfNotPremium(ctx, &row)
	if err != nil {
		s.cancelQuietly(ctx, sub.ID)
		return nil, fmt.Errorf("persist subscription row: %w", err)
	}
	if !applied {
		s.cancelQuietly(ctx, sub.ID)
		return nil, ErrAlreadySubscribed
	}

	params, err := s.paymentSheetParams(customerID, clientSecret, sub.ID, intentType)
	if params != nil {
		params.TrialDays = trialDays
	}
	return params, err
}

// trialEligible reports whether the user may start the yearly free trial:
// only if they never had a live subscription or trial before, from any
// source (trial-abuse prevention). Our row's trial_consumed flag covers
// App Store / Google Play and Stripe history recorded since it existed; a
// reused Stripe customer's own subscription history is checked too.
// Errors fail closed (no trial).
func (s *StripeService) trialEligible(ctx context.Context, existing *domain.Subscription, customerID string, reusedCustomer bool) bool {
	if existing != nil && existing.TrialConsumed {
		return false
	}
	if !reusedCustomer {
		return true
	}
	params := &stripe.SubscriptionListParams{
		Customer: stripe.String(customerID),
		Status:   stripe.String("all"),
	}
	params.Context = ctx
	params.Limit = stripe.Int64(100)
	it := stripesub.List(params)
	for it.Next() {
		if stripeSubscriptionHadAccess(it.Subscription()) {
			return false
		}
	}
	if err := it.Err(); err != nil {
		slog.Error("stripe: list customer subscriptions for trial check; no trial",
			"error", err, "stripe_customer_id", customerID)
		return false
	}
	return true
}

// stripeSubscriptionHadAccess reports whether a (possibly ended) Stripe
// subscription ever gave the customer premium: it was paid for, or a trial
// ran with a card on file. Abandoned checkouts (incomplete, or a trial
// whose card was never added) don't count.
func stripeSubscriptionHadAccess(sub *stripe.Subscription) bool {
	switch sub.Status {
	case stripe.SubscriptionStatusIncomplete, stripe.SubscriptionStatusIncompleteExpired:
		return false
	case stripe.SubscriptionStatusActive, stripe.SubscriptionStatusPastDue,
		stripe.SubscriptionStatusUnpaid, stripe.SubscriptionStatusPaused:
		return true
	}
	// trialing / canceled: only if a payment method was ever attached.
	return stripeHasPaymentMethod(sub)
}

func stripeHasPaymentMethod(sub *stripe.Subscription) bool {
	return sub.DefaultPaymentMethod != nil || sub.DefaultSource != nil
}

// stripeAccessStatus is the premium status a Stripe subscription grants.
// Like mapStripeStatus, except a trial without a payment method on file
// (the user opened the trial checkout but never added a card) grants
// nothing — otherwise the trial would be free premium with no card.
func stripeAccessStatus(sub *stripe.Subscription) domain.SubscriptionStatus {
	if sub.Status == stripe.SubscriptionStatusTrialing && !stripeHasPaymentMethod(sub) {
		return domain.StatusExpired
	}
	return mapStripeStatus(sub.Status)
}

// reconcilePreviousSubscription inspects the Stripe subscription our row
// points at before Subscribe creates a new one. It returns:
//   - params != nil: the previous subscription is an `incomplete` one for
//     the same price whose PaymentIntent can still be confirmed — reuse it;
//   - ErrAlreadySubscribed / ErrSubscriptionPaymentPending: it is live or
//     its first payment is in flight (our row was stale and is re-synced);
//   - (nil, nil): nothing reusable (it was cancelled/expired/unpaid or a
//     different plan, and has been cancelled if needed) — create a new one.
func (s *StripeService) reconcilePreviousSubscription(
	ctx context.Context,
	stripeSubID, priceID, customerID string,
) (*PaymentSheetParams, error) {
	getParams := &stripe.SubscriptionParams{Params: stripe.Params{Context: ctx}}
	getParams.AddExpand("latest_invoice.payment_intent")
	getParams.AddExpand("pending_setup_intent")
	prev, err := stripesub.Get(stripeSubID, getParams)
	if isStripeResourceMissing(err) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("fetch previous subscription: %w", err)
	}
	if prev.Customer != nil && prev.Customer.ID != customerID {
		// Row points at another customer's subscription — don't touch it.
		return nil, nil
	}

	if prev.Status == stripe.SubscriptionStatusTrialing && !stripeHasPaymentMethod(prev) {
		// A trial checkout whose card was never added: resume it when it's
		// for the same price and its SetupIntent can still be confirmed;
		// otherwise cancel it so it can't linger next to the new one.
		si := prev.PendingSetupIntent
		if si != nil && subscriptionPriceID(prev) == priceID && si.ClientSecret != "" &&
			(si.Status == stripe.SetupIntentStatusRequiresPaymentMethod ||
				si.Status == stripe.SetupIntentStatusRequiresConfirmation ||
				si.Status == stripe.SetupIntentStatusRequiresAction) {
			params, err := s.paymentSheetParams(customerID, si.ClientSecret, prev.ID, intentTypeSetup)
			if params != nil && prev.TrialEnd > 0 && prev.TrialStart > 0 {
				params.TrialDays = int((prev.TrialEnd - prev.TrialStart) / 86400)
			}
			return params, err
		}
		if si != nil && si.Status == stripe.SetupIntentStatusProcessing {
			return nil, ErrSubscriptionPaymentPending
		}
		if _, err := stripesub.Cancel(prev.ID, &stripe.SubscriptionCancelParams{
			Params: stripe.Params{Context: ctx},
		}); err != nil && !isStripeResourceMissing(err) {
			return nil, fmt.Errorf("cancel previous unconfirmed trial: %w", err)
		}
		return nil, nil
	}

	switch prev.Status {
	case stripe.SubscriptionStatusActive,
		stripe.SubscriptionStatusTrialing,
		stripe.SubscriptionStatusPastDue:
		// Our row is stale (missed webhook). Re-sync it and refuse: a
		// second subscription would double-bill. past_due users must fix
		// their payment method on the existing subscription instead.
		if err := s.applySubscriptionRecord(ctx, prev); err != nil {
			slog.Error("stripe: re-sync stale subscription row", "error", err,
				"stripe_subscription_id", prev.ID)
		}
		return nil, ErrAlreadySubscribed

	case stripe.SubscriptionStatusIncomplete:
		var pi *stripe.PaymentIntent
		if prev.LatestInvoice != nil {
			pi = prev.LatestInvoice.PaymentIntent
		}
		if pi != nil && pi.Status == stripe.PaymentIntentStatusProcessing {
			return nil, ErrSubscriptionPaymentPending
		}
		if pi != nil && subscriptionPriceID(prev) == priceID && pi.ClientSecret != "" &&
			(pi.Status == stripe.PaymentIntentStatusRequiresPaymentMethod ||
				pi.Status == stripe.PaymentIntentStatusRequiresConfirmation ||
				pi.Status == stripe.PaymentIntentStatusRequiresAction) {
			return s.paymentSheetParams(customerID, pi.ClientSecret, prev.ID, intentTypePayment)
		}
		// Different plan, or a PaymentIntent that can't be confirmed any
		// more: cancel it so it can't later complete alongside the new one.
		if _, err := stripesub.Cancel(prev.ID, &stripe.SubscriptionCancelParams{
			Params: stripe.Params{Context: ctx},
		}); err != nil && !isStripeResourceMissing(err) {
			return nil, fmt.Errorf("cancel previous incomplete subscription: %w", err)
		}
		return nil, nil

	case stripe.SubscriptionStatusUnpaid, stripe.SubscriptionStatusPaused:
		// Dead for billing purposes but not terminal — cancel so it can't
		// be revived alongside the new subscription.
		if _, err := stripesub.Cancel(prev.ID, &stripe.SubscriptionCancelParams{
			Params: stripe.Params{Context: ctx},
		}); err != nil && !isStripeResourceMissing(err) {
			return nil, fmt.Errorf("cancel previous %s subscription: %w", prev.Status, err)
		}
		return nil, nil
	}
	// canceled / incomplete_expired: terminal, nothing to clean up.
	return nil, nil
}

func (s *StripeService) paymentSheetParams(customerID, clientSecret, subID, intentType string) (*PaymentSheetParams, error) {
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
		SubscriptionID: subID,
		IntentType:     intentType,
	}, nil
}

// cancelQuietly best-effort cancels a subscription we just created but
// can't hand to the user, so it doesn't linger as a payable duplicate.
func (s *StripeService) cancelQuietly(ctx context.Context, subID string) {
	cctx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 10*time.Second)
	defer cancel()
	if _, err := stripesub.Cancel(subID, &stripe.SubscriptionCancelParams{
		Params: stripe.Params{Context: cctx},
	}); err != nil && !isStripeResourceMissing(err) {
		slog.Error("stripe: failed to cancel orphaned subscription",
			"error", err, "stripe_subscription_id", subID)
	}
}

// CancelImmediately terminates the user's Stripe subscription right away
// (no period-end grace) and records the cancellation locally. Used by
// account deletion so a deleted account is never billed again. A user
// without a Stripe subscription, or whose subscription is already
// terminal, is a no-op. App-store (RevenueCat) subscriptions can't be
// cancelled server-side and are not touched.
func (s *StripeService) CancelImmediately(ctx context.Context, userID uuid.UUID) error {
	row, err := s.subRepo.GetByUserID(ctx, userID)
	if err != nil {
		return fmt.Errorf("load subscription: %w", err)
	}
	if row == nil || row.StripeSubscriptionID == nil || *row.StripeSubscriptionID == "" {
		return nil
	}
	if s.secretKey == "" {
		// A retry can't fix missing config, and failing here would block
		// account deletion indefinitely. Proceed, but flag for ops.
		slog.Error("stripe not configured: subscription NOT cancelled on account deletion — cancel manually",
			"user_id", userID, "stripe_subscription_id", *row.StripeSubscriptionID)
		return nil
	}
	subID := *row.StripeSubscriptionID

	current, err := stripesub.Get(subID, &stripe.SubscriptionParams{Params: stripe.Params{Context: ctx}})
	if isStripeResourceMissing(err) {
		return nil
	}
	if err != nil {
		return fmt.Errorf("fetch subscription: %w", err)
	}
	if current.Status == stripe.SubscriptionStatusCanceled ||
		current.Status == stripe.SubscriptionStatusIncompleteExpired {
		return s.applySubscriptionRecord(ctx, current)
	}

	cancelled, err := stripesub.Cancel(subID, &stripe.SubscriptionCancelParams{
		Params: stripe.Params{Context: ctx},
	})
	if isStripeResourceMissing(err) {
		return nil
	}
	if err != nil {
		return fmt.Errorf("cancel subscription: %w", err)
	}
	return s.applySubscriptionRecord(ctx, cancelled)
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

// applySubscriptionEvent applies a customer.subscription.* event. Stripe
// does not guarantee delivery order, so the payload is only used for the
// subscription id: the current state is re-fetched from the API (as the
// invoice path does) so a late `updated` can't overwrite a newer
// `deleted`/`active` state. If the subscription no longer exists (e.g.
// the customer was deleted) the event snapshot is the best we have.
func (s *StripeService) applySubscriptionEvent(ctx context.Context, event stripe.Event) error {
	var snapshot stripe.Subscription
	if err := stripeUnmarshalEventData(event, &snapshot); err != nil {
		return err
	}
	if snapshot.ID == "" {
		return fmt.Errorf("%s event without subscription id", event.Type)
	}
	sub, err := stripesub.Get(snapshot.ID, &stripe.SubscriptionParams{Params: stripe.Params{Context: ctx}})
	if isStripeResourceMissing(err) {
		slog.Warn("stripe: subscription missing on re-fetch; applying event snapshot",
			"stripe_subscription_id", snapshot.ID, "event_type", event.Type)
		return s.applySubscriptionRecord(ctx, &snapshot)
	}
	if err != nil {
		// Returning an error makes Stripe retry the webhook later.
		return fmt.Errorf("fetch sub on %s event: %w", event.Type, err)
	}
	return s.applySubscriptionRecord(ctx, sub)
}

// subscriptionPriceID returns the price of the subscription's first item.
func subscriptionPriceID(sub *stripe.Subscription) string {
	if sub.Items != nil && len(sub.Items.Data) > 0 && sub.Items.Data[0].Price != nil {
		return sub.Items.Data[0].Price.ID
	}
	return ""
}

func (s *StripeService) applySubscriptionRecord(ctx context.Context, sub *stripe.Subscription) error {
	priceID := subscriptionPriceID(sub)
	planType := domain.PlanMonthly
	if sub.Items != nil && len(sub.Items.Data) > 0 {
		if p := sub.Items.Data[0].Price; p != nil && p.Recurring != nil && p.Recurring.Interval == "year" {
			planType = domain.PlanYearly
		}
	}
	status := stripeAccessStatus(sub)
	periodEnd := timePtrFromUnix(sub.CurrentPeriodEnd)
	err := s.subRepo.UpdateFromStripe(
		ctx, sub.ID, status, priceID, planType, periodEnd, sub.CancelAtPeriodEnd,
	)
	if !errors.Is(err, repository.ErrSubscriptionNotFound) {
		return err
	}

	// No row carries this Stripe subscription id yet. This happens when a
	// `subscription.created` webhook races ahead of the Subscribe flow's
	// write. If we already have a row for this customer (created by
	// Subscribe), link the subscription id onto it; otherwise log and let
	// Subscribe create the row — don't silently drop the event.
	if sub.Customer != nil {
		existing, gerr := s.subRepo.GetByStripeCustomer(ctx, sub.Customer.ID)
		if gerr != nil {
			return gerr
		}
		// Only link when the row has no subscription yet, or when this
		// subscription is live and the row's isn't. Otherwise this is an
		// event for a superseded subscription (e.g. the `deleted` event of
		// an abandoned incomplete sub Subscribe just cancelled) and must
		// not clobber the row's current subscription.
		if existing != nil && existing.StripeSubscriptionID != nil && *existing.StripeSubscriptionID != "" &&
			!((status == domain.StatusActive || status == domain.StatusTrialing) && !existing.StripePremium()) {
			slog.Info("stripe webhook for superseded subscription; ignoring",
				"stripe_subscription_id", sub.ID,
				"current_subscription_id", *existing.StripeSubscriptionID)
			return nil
		}
		if existing != nil {
			subID := sub.ID
			pid := priceID
			existing.StripeSubscriptionID = &subID
			existing.Status = status
			existing.PriceID = &pid
			existing.PlanType = planType
			existing.CurrentPeriodEnd = periodEnd
			existing.ExpiresAt = periodEnd
			existing.CancelAtPeriodEnd = sub.CancelAtPeriodEnd
			existing.TrialEndAt = timePtrFromUnix(sub.TrialEnd)
			return s.subRepo.Upsert(ctx, existing)
		}
	}
	slog.Warn("stripe webhook for unknown subscription; will be reconciled by subscribe flow",
		"stripe_subscription_id", sub.ID)
	return nil
}

// isStripeResourceMissing reports whether err is Stripe's 404
// "resource_missing" (deleted customer/subscription).
func isStripeResourceMissing(err error) bool {
	var se *stripe.Error
	return errors.As(err, &se) &&
		(se.Code == stripe.ErrorCodeResourceMissing || se.HTTPStatusCode == http.StatusNotFound)
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
