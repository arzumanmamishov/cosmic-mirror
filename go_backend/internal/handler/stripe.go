package handler

import (
	"errors"
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

// PaymentSheet POSTs from the web client when the user taps "Subscribe"
// (the mobile apps use App Store / Google Play in-app purchases instead).
// Body: { "plan": "monthly" | "yearly" }
// Returns the params a Stripe payment form needs; intent_type says whether
// client_secret is a PaymentIntent ("payment") or, for the yearly free
// trial, a SetupIntent ("setup").
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
		switch {
		case errors.Is(err, service.ErrAlreadySubscribed):
			respondError(w, http.StatusConflict, "already_subscribed",
				"You already have an active subscription")
		case errors.Is(err, service.ErrSubscriptionPaymentPending):
			respondError(w, http.StatusConflict, "payment_pending",
				"Your previous payment is still processing — please try again shortly")
		default:
			respondError(w, http.StatusInternalServerError, "stripe_subscribe_error", err.Error())
		}
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
	// Stripe payloads are usually a few KB, but events with expanded
	// objects (many line items) can exceed 64KB; a truncated body fails
	// signature verification and Stripe would retry forever.
	body, err := io.ReadAll(io.LimitReader(r.Body, 512<<10))
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
