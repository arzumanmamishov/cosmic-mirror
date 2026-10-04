package handler

import (
	"errors"
	"io"
	"log/slog"
	"net/http"
	"time"

	"cosmic-mirror/internal/domain"

	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"
)

type SubscriptionHandler struct {
	subSvc *service.SubscriptionService
}

func NewSubscriptionHandler(subSvc *service.SubscriptionService) *SubscriptionHandler {
	return &SubscriptionHandler{subSvc: subSvc}
}

func (h *SubscriptionHandler) GetStatus(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	sub, err := h.subSvc.GetStatus(r.Context(), userID)
	if err != nil {
		respondServiceError(w, http.StatusInternalServerError, "subscription_error", err)
		return
	}
	// is_premium is computed with the same rule the server enforces
	// (RequirePremium): Stripe (web) OR App Store / Google Play via
	// RevenueCat. source / expires_at / is_trial / plan_type describe the
	// access currently in effect.
	source, expiresAt, isTrial, plan := sub.Entitlement()
	var store string
	if source == domain.SourceRevenueCat {
		store = sub.Store
	}
	respondSuccess(w, struct {
		*domain.Subscription
		IsPremium bool            `json:"is_premium"`
		Source    string          `json:"source"`
		Store     string          `json:"store,omitempty"`
		ExpiresAt *time.Time      `json:"expires_at"`
		IsTrial   bool            `json:"is_trial"`
		PlanType  domain.PlanType `json:"plan_type"`
		WillRenew bool            `json:"will_renew"`
	}{
		Subscription: sub,
		IsPremium:    source != "",
		Source:       source,
		Store:        store,
		ExpiresAt:    expiresAt,
		IsTrial:      isTrial,
		PlanType:     plan,
		WillRenew: (source == domain.SourceRevenueCat && sub.StoreWillRenew) ||
			(source == domain.SourceStripe && !sub.CancelAtPeriodEnd),
	})
}

func (h *SubscriptionHandler) HandleWebhook(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(io.LimitReader(r.Body, 64<<10))
	if err != nil {
		respondError(w, http.StatusBadRequest, "read_error", "Failed to read request body")
		return
	}
	defer r.Body.Close()

	if err := h.subSvc.HandleWebhook(r.Context(), body, r.Header.Get("Authorization")); err != nil {
		switch {
		case errors.Is(err, service.ErrWebhookUnauthorized):
			slog.Warn("revenuecat webhook rejected", "error", err)
			respondError(w, http.StatusUnauthorized, "webhook_error", "Webhook rejected")
		case errors.Is(err, service.ErrWebhookMalformed):
			slog.Warn("revenuecat webhook malformed", "error", err)
			respondError(w, http.StatusBadRequest, "webhook_error", "Malformed webhook")
		default:
			// Transient (RevenueCat API / database): 5xx makes RevenueCat
			// retry the delivery later.
			slog.Error("revenuecat webhook failed", "error", err)
			respondError(w, http.StatusInternalServerError, "webhook_error", "Webhook processing failed")
		}
		return
	}

	respondSuccess(w, map[string]string{"status": "ok"})
}
