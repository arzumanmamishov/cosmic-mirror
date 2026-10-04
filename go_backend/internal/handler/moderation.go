package handler

import (
	"errors"
	"net/http"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

// ModerationHandler serves reporting, blocking and the admin moderation
// queue (App Store 1.2 / Google Play UGC requirements).
type ModerationHandler struct {
	modSvc *service.ModerationService
}

func NewModerationHandler(modSvc *service.ModerationService) *ModerationHandler {
	return &ModerationHandler{modSvc: modSvc}
}

// CreateReport — POST /reports. 201 for a new report, 200 (same body)
// when the caller had already reported this target.
func (h *ModerationHandler) CreateReport(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	var input domain.CreateReportInput
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	report, created, err := h.modSvc.CreateReport(r.Context(), userID, input)
	if err != nil {
		respondModerationError(w, err)
		return
	}
	if created {
		respondCreated(w, report)
		return
	}
	respondSuccess(w, report)
}

// Block — POST /users/{userID}/block.
func (h *ModerationHandler) Block(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	target, err := uuid.Parse(chi.URLParam(r, "userID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid user ID")
		return
	}
	if err := h.modSvc.Block(r.Context(), userID, target); err != nil {
		respondModerationError(w, err)
		return
	}
	respondNoContent(w)
}

// Unblock — DELETE /users/{userID}/block.
func (h *ModerationHandler) Unblock(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	target, err := uuid.Parse(chi.URLParam(r, "userID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid user ID")
		return
	}
	if err := h.modSvc.Unblock(r.Context(), userID, target); err != nil {
		respondModerationError(w, err)
		return
	}
	respondNoContent(w)
}

// ListBlocks — GET /users/me/blocks.
func (h *ModerationHandler) ListBlocks(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	blocks, err := h.modSvc.ListBlocks(r.Context(), userID)
	if err != nil {
		respondModerationError(w, err)
		return
	}
	respondSuccess(w, map[string]any{"blocks": blocks})
}

// AdminListReports — GET /admin/reports?status=open&limit=&offset=.
func (h *ModerationHandler) AdminListReports(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	reports, err := h.modSvc.ListReports(r.Context(), q.Get("status"),
		parseLimit(q.Get("limit"), 50, 200),
		parseOffset(q.Get("offset")),
	)
	if err != nil {
		respondModerationError(w, err)
		return
	}
	respondSuccess(w, map[string]any{"reports": reports})
}

// AdminResolveReport — POST /admin/reports/{reportID}/resolve
// {action: dismiss|hide|delete|ban_user, note}.
func (h *ModerationHandler) AdminResolveReport(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "reportID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid report ID")
		return
	}
	var input domain.ResolveReportInput
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	report, err := h.modSvc.ResolveReport(r.Context(), id, input)
	if err != nil {
		respondModerationError(w, err)
		return
	}
	respondSuccess(w, report)
}

func respondModerationError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, service.ErrReportTargetNotFound),
		errors.Is(err, service.ErrReportNotFound),
		errors.Is(err, service.ErrUserNotFound):
		respondError(w, http.StatusNotFound, "not_found", err.Error())
	default:
		// ErrValidation → 400 with its message; anything else → 500.
		respondServiceError(w, http.StatusInternalServerError, "moderation_error", err)
	}
}
