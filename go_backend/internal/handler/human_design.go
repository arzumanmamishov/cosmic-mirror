package handler

import (
	"errors"
	"net/http"

	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"
)

type HumanDesignHandler struct {
	svc *service.HumanDesignService
}

func NewHumanDesignHandler(svc *service.HumanDesignService) *HumanDesignHandler {
	return &HumanDesignHandler{svc: svc}
}

func (h *HumanDesignHandler) GetChart(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	chart, err := h.svc.GetChart(r.Context(), userID)
	if err != nil {
		switch {
		case errors.Is(err, service.ErrHDMissingProfile):
			respondError(w, http.StatusBadRequest, "missing_profile",
				"Set your birth profile first.")
		case errors.Is(err, service.ErrHDMissingTime):
			respondError(w, http.StatusBadRequest, "missing_birth_time",
				"Birth time is required for a Human Design chart — please update your profile with the exact time.")
		default:
			respondError(w, http.StatusInternalServerError, "human_design_error", err.Error())
		}
		return
	}
	respondSuccess(w, chart)
}
