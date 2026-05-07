package handler

import (
	"errors"
	"net/http"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"
)

type NumerologyHandler struct {
	svc *service.NumerologyService
}

func NewNumerologyHandler(svc *service.NumerologyService) *NumerologyHandler {
	return &NumerologyHandler{svc: svc}
}

// GetReading returns the full numerology profile + cycles for the user.
func (h *NumerologyHandler) GetReading(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	reading, err := h.svc.GetReading(r.Context(), userID)
	if err != nil {
		if errors.Is(err, service.ErrNumerologyMissingProfile) {
			respondError(w, http.StatusBadRequest, "missing_profile",
				"Set your birth profile first to get a numerology reading.")
			return
		}
		respondError(w, http.StatusInternalServerError, "numerology_error", err.Error())
		return
	}
	respondSuccess(w, reading)
}

// AnalyzeName is the standalone Name Numerology Calculator.
// Body: { "name": "Norma Jeane Baker" }
// Returns Expression / Soul Urge / Personality + the per-letter trace.
// Authed (consistent with the rest of the numerology endpoints) but does
// NOT require a birth profile.
func (h *NumerologyHandler) AnalyzeName(w http.ResponseWriter, r *http.Request) {
	var req domain.NumerologyNameRequest
	if err := decodeBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	out, err := h.svc.AnalyzeName(req.Name)
	if err != nil {
		respondError(w, http.StatusBadRequest, "name_required", err.Error())
		return
	}
	respondSuccess(w, out)
}

// Compare returns a compatibility report between the user and a partner,
// passed in the request body.
func (h *NumerologyHandler) Compare(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	var req domain.NumerologyCompatibilityRequest
	if err := decodeBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	out, err := h.svc.Compare(r.Context(), userID, req)
	if err != nil {
		if errors.Is(err, service.ErrNumerologyMissingProfile) {
			respondError(w, http.StatusBadRequest, "missing_profile",
				"Set your birth profile first.")
			return
		}
		respondError(w, http.StatusBadRequest, "numerology_compat_error", err.Error())
		return
	}
	respondSuccess(w, out)
}
