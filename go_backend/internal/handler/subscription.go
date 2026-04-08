package handler

import (
	"io"
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
	respondSuccess(w, sub)
}

func (h *SubscriptionHandler) HandleWebhook(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		respondError(w, http.StatusBadRequest, "read_error", "Failed to read request body")
		return
	}
	defer r.Body.Close()

	signature := r.Header.Get("X-RevenueCat-Signature")

	if err := h.subSvc.HandleWebhook(r.Context(), body, signature); err != nil {
		respondError(w, http.StatusBadRequest, "webhook_error", err.Error())
		return
	}

	respondSuccess(w, map[string]string{"status": "ok"})
}
