package handler

import (
	"errors"
	"net/http"
	"strings"
	"time"
	"unicode/utf8"

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
		respondServiceError(w, http.StatusInternalServerError, "numerology_error", err)
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
	if strings.TrimSpace(req.Name) == "" {
		respondError(w, http.StatusBadRequest, "name_required", "Name is required")
		return
	}
	if utf8.RuneCountInString(req.Name) > 200 {
		respondError(w, http.StatusBadRequest, "invalid_body", "Name must be at most 200 characters")
		return
	}
	out, err := h.svc.AnalyzeName(r.Context(), req.Name)
	if err != nil {
		respondServiceError(w, http.StatusInternalServerError, "numerology_error", err)
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
	// Validate here so bad input is a clean 400 and every remaining service
	// error (DB / profile lookup) is a 500 whose detail stays server-side.
	if strings.TrimSpace(req.FullName) == "" {
		respondError(w, http.StatusBadRequest, "invalid_body", "full_name is required")
		return
	}
	if utf8.RuneCountInString(req.FullName) > 200 {
		respondError(w, http.StatusBadRequest, "invalid_body", "full_name must be at most 200 characters")
		return
	}
	if _, err := time.Parse("2006-01-02", req.BirthDate); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "birth_date must be a date in YYYY-MM-DD format")
		return
	}
	out, err := h.svc.Compare(r.Context(), userID, req)
	if err != nil {
		if errors.Is(err, service.ErrNumerologyMissingProfile) {
			respondError(w, http.StatusBadRequest, "missing_profile",
				"Set your birth profile first.")
			return
		}
		respondServiceError(w, http.StatusInternalServerError, "numerology_compat_error", err)
		return
	}
	respondSuccess(w, out)
}
