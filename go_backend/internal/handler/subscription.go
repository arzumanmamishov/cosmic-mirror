package handler

import (
	"cosmic-mirror/internal/domain"
	"io"
	"log/slog"
	"net/http"

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
		respondError(w, http.StatusInternalServerError, "subscription_error", err.Error())
		return
	}
	// is_premium is computed with the same rule the server enforces
	// (RequirePremium), so the app never disagrees with the API.
	respondSuccess(w, struct {
		*domain.Subscription
		IsPremium bool `json:"is_premium"`
	}{sub, sub.IsPremium()})
}

func (h *SubscriptionHandler) HandleWebhook(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(io.LimitReader(r.Body, 64<<10))
	if err != nil {
		respondError(w, http.StatusBadRequest, "read_error", "Failed to read request body")
		return
	}
	defer r.Body.Close()

	if err := h.subSvc.HandleWebhook(r.Context(), body, r.Header.Get("Authorization")); err != nil {
		slog.Warn("revenuecat webhook rejected", "error", err)
		respondError(w, http.StatusUnauthorized, "webhook_error", "Webhook rejected")
		return
	}

	respondSuccess(w, map[string]string{"status": "ok"})
}
