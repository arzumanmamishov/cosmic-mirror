package service

import (
	"context"
	"crypto/hmac"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
)

type SubscriptionService struct {
	subRepo       repository.SubscriptionRepository
	webhookSecret string
}

func NewSubscriptionService(subRepo repository.SubscriptionRepository, webhookSecret string) *SubscriptionService {
	return &SubscriptionService{subRepo: subRepo, webhookSecret: webhookSecret}
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

func (s *SubscriptionService) IsPremium(ctx context.Context, userID uuid.UUID) bool {
	sub, err := s.subRepo.GetByUserID(ctx, userID)
	if err != nil || sub == nil {
		return false
	}
	return sub.IsPremium()
}

type RevenueCatWebhookEvent struct {
	Event struct {
		Type              string `json:"type"`
		AppUserID         string `json:"app_user_id"`
		ProductID         string `json:"product_id"`
		ExpirationAtMs    int64  `json:"expiration_at_ms"`
		PurchasedAtMs     int64  `json:"purchased_at_ms"`
		OriginalAppUserID string `json:"original_app_user_id"`
	} `json:"event"`
}

// HandleWebhook applies a RevenueCat event. RevenueCat authenticates by
// sending the Authorization header value configured in its dashboard, so
// [authHeader] must equal the secret (optionally "Bearer "-prefixed).
// Fails closed: with no secret configured every call is rejected.
func (s *SubscriptionService) HandleWebhook(ctx context.Context, body []byte, authHeader string) error {
	if s.webhookSecret == "" {
		return fmt.Errorf("webhook not configured")
	}
	token := strings.TrimPrefix(authHeader, "Bearer ")
	if !hmac.Equal([]byte(token), []byte(s.webhookSecret)) {
		return fmt.Errorf("invalid webhook authorization")
	}

	var event RevenueCatWebhookEvent
	if err := json.Unmarshal(body, &event); err != nil {
		return fmt.Errorf("parse webhook: %w", err)
	}

	if event.Event.AppUserID == "" {
		return fmt.Errorf("missing app_user_id")
	}

	var status domain.SubscriptionStatus
	switch event.Event.Type {
	case "INITIAL_PURCHASE", "RENEWAL", "PRODUCT_CHANGE":
		status = domain.StatusActive
	case "CANCELLATION":
		status = domain.StatusCancelled
	case "EXPIRATION":
		status = domain.StatusExpired
	default:
		return nil // Ignore unhandled events
	}

	var expiresAt *time.Time
	if event.Event.ExpirationAtMs > 0 {
		t := time.UnixMilli(event.Event.ExpirationAtMs)
		expiresAt = &t
	}

	return s.subRepo.UpdateStatus(ctx, event.Event.AppUserID, status, expiresAt)
}
