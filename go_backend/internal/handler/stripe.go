package handler

import (
	"io"
	"net/http"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"
)

type StripeHandler struct {
	svc *service.StripeService
}

func NewStripeHandler(svc *service.StripeService) *StripeHandler {
	return &StripeHandler{svc: svc}
}

// PaymentSheet POSTs from the mobile client when the user taps "Subscribe".
// Body: { "plan": "monthly" | "yearly" }
// Returns the params the Flutter Payment Sheet needs to render itself.
func (h *StripeHandler) PaymentSheet(w http.ResponseWriter, r *http.Request) {
	if !h.svc.Configured() {
		respondError(w, http.StatusServiceUnavailable, "stripe_unconfigured",
			"Stripe is not configured on this server")
		return
	}

	userID := middleware.UserIDFromContext(r.Context())

	var input struct {
		Plan string `json:"plan"`
	}
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}

	plan := domain.PlanMonthly
	if input.Plan == string(domain.PlanYearly) {
		plan = domain.PlanYearly
	}

	params, err := h.svc.Subscribe(r.Context(), userID, plan)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "stripe_subscribe_error", err.Error())
		return
	}
	respondSuccess(w, params)
}

// Cancel marks the user's current Stripe subscription to terminate at
// period end (so they keep Premium until the period they paid for ends).
func (h *StripeHandler) Cancel(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	if err := h.svc.Cancel(r.Context(), userID); err != nil {
		respondError(w, http.StatusInternalServerError, "stripe_cancel_error", err.Error())
		return
	}
	respondNoContent(w)
}

// HandleWebhook is the public Stripe webhook endpoint. Stripe POSTs
// events here and signs them with our webhook secret; we verify the
// signature and update local subscription state.
func (h *StripeHandler) HandleWebhook(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		respondError(w, http.StatusBadRequest, "read_error", "Failed to read body")
		return
	}
	defer r.Body.Close()

	signature := r.Header.Get("Stripe-Signature")
	if err := h.svc.HandleStripeWebhook(r.Context(), body, signature); err != nil {
		respondError(w, http.StatusBadRequest, "webhook_error", err.Error())
		return
	}
	respondSuccess(w, map[string]string{"status": "ok"})
}
