package service

import (
	"context"
	"crypto/hmac"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
)

// Webhook errors the handler maps to HTTP statuses. Anything else is a
// transient failure (RevenueCat API / DB) and is answered with 5xx so
// RevenueCat retries the delivery.
var (
	ErrWebhookUnauthorized = errors.New("invalid webhook authorization")
	ErrWebhookMalformed    = errors.New("malformed webhook payload")
)

type SubscriptionService struct {
	subRepo       repository.SubscriptionRepository
	webhookSecret string
	entitlementID string
	rc            *revenueCatClient // nil: derive state from webhook payloads
	now           func() time.Time
}

func NewSubscriptionService(subRepo repository.SubscriptionRepository, webhookSecret string) *SubscriptionService {
	return &SubscriptionService{
		subRepo:       subRepo,
		webhookSecret: webhookSecret,
		entitlementID: DefaultRevenueCatEntitlement,
		now:           time.Now,
	}
}

// WithRevenueCatAPI enables fetching authoritative subscriber state from
// the RevenueCat REST API (secret key, "sk_…") on every webhook, and sets
// the entitlement id that grants premium (default "premium"). Without a
// key, webhook payloads are applied directly.
func (s *SubscriptionService) WithRevenueCatAPI(secretAPIKey, entitlementID string) *SubscriptionService {
	if entitlementID != "" {
		s.entitlementID = entitlementID
	}
	if secretAPIKey != "" {
		s.rc = newRevenueCatClient(secretAPIKey)
	} else if s.webhookSecret != "" {
		slog.Warn("REVENUECAT_SECRET_API_KEY not set — RevenueCat webhooks are applied from the event payload only (TRANSFER recipients won't be credited until their next event)")
	}
	return s
}

func (s *SubscriptionService) GetStatus(ctx context.Context, userID uuid.UUID) (*domain.Subscription, error) {
	sub, err := s.subRepo.GetByUserID(ctx, userID)
	if err != nil {
		return nil, err
	}
	if sub == nil {
		return &domain.Subscription{
			UserID: userID,
			Status: domain.StatusExpired,
		}, nil
	}
	return sub, nil
}

// IsPremium reports whether the user has premium from any source (Stripe
// web subscription or App Store / Google Play via RevenueCat).
func (s *SubscriptionService) IsPremium(ctx context.Context, userID uuid.UUID) bool {
	sub, err := s.subRepo.GetByUserID(ctx, userID)
	if err != nil || sub == nil {
		return false
	}
	return sub.IsPremium()
}

// HandleWebhook applies a RevenueCat event. RevenueCat authenticates by
// sending the Authorization header value configured in its dashboard, so
// [authHeader] must equal the secret (optionally "Bearer "-prefixed).
// Fails closed: with no secret configured every call is rejected.
//
// The event only identifies the user; when a REST API key is configured
// the user's current entitlement is fetched from RevenueCat (so retries
// and out-of-order deliveries converge on the true state), otherwise it is
// derived from the payload. Applying the same event twice is a no-op.
func (s *SubscriptionService) HandleWebhook(ctx context.Context, body []byte, authHeader string) error {
	if s.webhookSecret == "" {
		return fmt.Errorf("%w: webhook not configured", ErrWebhookUnauthorized)
	}
	token := strings.TrimPrefix(authHeader, "Bearer ")
	if !hmac.Equal([]byte(token), []byte(s.webhookSecret)) {
		return ErrWebhookUnauthorized
	}

	var payload revenueCatWebhook
	if err := json.Unmarshal(body, &payload); err != nil {
		return fmt.Errorf("%w: %v", ErrWebhookMalformed, err)
	}
	ev := payload.Event
	if !revenueCatHandledEvents[ev.Type] {
		return nil // TEST and other informational events
	}

	targets := revenueCatTargets(ev)
	if len(targets) == 0 {
		// Anonymous purchase (made before Purchases.logIn) or an id that
		// isn't one of ours. RevenueCat sends a TRANSFER / new event once
		// the purchase is attached to a real user.
		slog.Info("revenuecat webhook: no user id to apply",
			"event_type", ev.Type, "event_id", ev.ID, "app_user_id", ev.AppUserID)
		return nil
	}

	for _, t := range targets {
		var (
			st domain.StoreSubscriptionState
			ok = true
		)
		if s.rc != nil {
			resp, err := s.rc.subscriber(ctx, t.AppUserID)
			if err != nil {
				return err
			}
			st = storeStateFromSubscriber(resp, t.AppUserID, s.entitlementID, s.now())
		} else {
			st, ok = storeStateFromEvent(ev, t, s.entitlementID, s.now())
		}
		if !ok {
			continue
		}
		applied, err := s.subRepo.ApplyStoreState(ctx, t.UserID, st)
		if err != nil {
			return fmt.Errorf("apply store state: %w", err)
		}
		slog.Info("revenuecat webhook applied",
			"event_type", ev.Type, "event_id", ev.ID, "user_id", t.UserID,
			"store_status", st.Status, "product_id", st.ProductID, "written", applied)
	}
	return nil
}
