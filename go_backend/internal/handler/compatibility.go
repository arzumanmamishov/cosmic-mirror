package handler

import (
	"errors"
	"net/http"
	"strings"

	"cosmic-mirror/internal/domain"
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
	userID := middleware.UserIDFromContext(r.Context())
	people, err := h.compatSvc.ListPeople(r.Context(), userID)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "people_error", err.Error())
		return
	}
	if people == nil {
		people = []domain.SavedPerson{}
	}
	respondSuccess(w, map[string]any{"people": people})
}

func (h *CompatibilityHandler) AddPerson(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	var input domain.AddPersonInput
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	if strings.TrimSpace(input.Name) == "" || input.BirthDate == "" ||
		strings.TrimSpace(input.BirthPlace) == "" || input.Timezone == "" {
		respondError(w, http.StatusBadRequest, "invalid_body",
			"name, birth_date, birth_place and timezone are required")
		return
	}
	person, err := h.compatSvc.AddPerson(r.Context(), userID, input)
	if err != nil {
		respondError(w, http.StatusBadRequest, "add_person_error", err.Error())
		return
	}
	respondCreated(w, person)
}

func (h *CompatibilityHandler) DeletePerson(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	personID, err := uuid.Parse(chi.URLParam(r, "personID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid person ID")
		return
	}
	if err := h.compatSvc.DeletePerson(r.Context(), userID, personID); err != nil {
		if errors.Is(err, service.ErrPersonNotFound) {
			respondError(w, http.StatusNotFound, "not_found", "Person not found")
			return
		}
		respondError(w, http.StatusInternalServerError, "delete_error", err.Error())
		return
	}
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
		if errors.Is(err, service.ErrPersonNotFound) {
			respondError(w, http.StatusNotFound, "not_found", "Person not found")
			return
		}
		respondError(w, http.StatusInternalServerError, "generate_error", err.Error())
		return
	}
	respondCreated(w, report)
}
