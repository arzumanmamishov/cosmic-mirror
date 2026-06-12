package handler

import (
	"errors"
	"net/http"

	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"
)

type DestinyMatrixHandler struct {
	svc *service.DestinyMatrixService
}

func NewDestinyMatrixHandler(svc *service.DestinyMatrixService) *DestinyMatrixHandler {
	return &DestinyMatrixHandler{svc: svc}
}

// GetReading returns the Matrix of Destiny (22-arcana octagram) reading for
// the user.
func (h *DestinyMatrixHandler) GetReading(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	reading, err := h.svc.GetReading(r.Context(), userID)
	if err != nil {
		if errors.Is(err, service.ErrDestinyMatrixMissingProfile) {
			respondError(w, http.StatusNotFound, "missing_profile",
				"Set your birth profile first to get a destiny matrix reading.")
			return
		}
		respondError(w, http.StatusInternalServerError, "destiny_matrix_error", err.Error())
		return
	}
	respondSuccess(w, reading)
}
