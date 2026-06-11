package handler

import (
	"errors"
	"net/http"

	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"
)

type PsychomatrixHandler struct {
	svc *service.PsychomatrixService
}

func NewPsychomatrixHandler(svc *service.PsychomatrixService) *PsychomatrixHandler {
	return &PsychomatrixHandler{svc: svc}
}

// GetReading returns the Pythagoras Square (psychomatrix) reading for the user.
func (h *PsychomatrixHandler) GetReading(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	reading, err := h.svc.GetReading(r.Context(), userID)
	if err != nil {
		if errors.Is(err, service.ErrPsychomatrixMissingProfile) {
			respondError(w, http.StatusNotFound, "missing_profile",
				"Set your birth profile first to get a psychomatrix reading.")
			return
		}
		respondError(w, http.StatusInternalServerError, "psychomatrix_error", err.Error())
		return
	}
	respondSuccess(w, reading)
}
