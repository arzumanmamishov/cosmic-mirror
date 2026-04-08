package service

import (
	"context"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
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
		Type               string `json:"type"`
		AppUserID          string `json:"app_user_id"`
		ProductID          string `json:"product_id"`
		ExpirationAtMs     int64  `json:"expiration_at_ms"`
		PurchasedAtMs      int64  `json:"purchased_at_ms"`
		OriginalAppUserID  string `json:"original_app_user_id"`
	} `json:"event"`
}

func (s *SubscriptionService) HandleWebhook(ctx context.Context, body []byte, signature string) error {
	// Verify signature
	if s.webhookSecret != "" {
		mac := hmac.New(sha256.New, []byte(s.webhookSecret))
		mac.Write(body)
		expected := hex.EncodeToString(mac.Sum(nil))
		if !hmac.Equal([]byte(expected), []byte(signature)) {
			return fmt.Errorf("invalid webhook signature")
		}
	}

	var event RevenueCatWebhookEvent
	if err := json.Unmarshal(body, &event); err != nil {
		return fmt.Errorf("parse webhook: %w", err)
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
