package handler

import (
	"net/http"

	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type CompatibilityHandler struct {
	compatSvc *service.CompatibilityService
}

func NewCompatibilityHandler(compatSvc *service.CompatibilityService) *CompatibilityHandler {
	return &CompatibilityHandler{compatSvc: compatSvc}
}

func (h *CompatibilityHandler) ListPeople(w http.ResponseWriter, r *http.Request) {
	respondSuccess(w, map[string]any{"people": []any{}})
}

func (h *CompatibilityHandler) AddPerson(w http.ResponseWriter, r *http.Request) {
	respondCreated(w, map[string]any{"id": uuid.New()})
}

func (h *CompatibilityHandler) DeletePerson(w http.ResponseWriter, r *http.Request) {
	respondNoContent(w)
}

func (h *CompatibilityHandler) GetReport(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	personID, err := uuid.Parse(chi.URLParam(r, "personID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid person ID")
		return
	}

	report, err := h.compatSvc.GetReport(r.Context(), userID, personID)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "report_error", err.Error())
		return
	}
	if report == nil {
		respondError(w, http.StatusNotFound, "not_found", "No report found. Generate one first.")
		return
	}
	respondSuccess(w, report)
}

func (h *CompatibilityHandler) GenerateReport(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	personID, err := uuid.Parse(chi.URLParam(r, "personID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid person ID")
		return
	}

	report, err := h.compatSvc.GenerateReport(r.Context(), userID, personID)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "generate_error", err.Error())
		return
	}
	respondCreated(w, report)
}
