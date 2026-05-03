package handler

import (
	"errors"
	"net/http"
	"strconv"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/repository/postgres"
	"cosmic-mirror/internal/service"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type SpacesHandler struct {
	communitySvc *service.CommunityService
}

func NewSpacesHandler(communitySvc *service.CommunityService) *SpacesHandler {
	return &SpacesHandler{communitySvc: communitySvc}
}

func (h *SpacesHandler) List(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	q := r.URL.Query()

	filter := postgres.SpaceFilterAll
	if q.Get("filter") == "joined" {
		filter = postgres.SpaceFilterJoined
	}
	var categoryID *uuid.UUID
	if c := q.Get("category"); c != "" {
		if id, err := uuid.Parse(c); err == nil {
			categoryID = &id
		}
	}
	limit := parseLimit(q.Get("limit"), 20, 100)
	offset := parseOffset(q.Get("offset"))

	spaces, err := h.communitySvc.ListSpaces(r.Context(), userID, filter, categoryID, q.Get("q"), limit, offset)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "spaces_list_error", err.Error())
		return
	}
	respondSuccess(w, map[string]any{"spaces": spaces})
}

func (h *SpacesHandler) Create(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	var input domain.CreateSpaceInput
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	space, err := h.communitySvc.CreateSpace(r.Context(), userID, input)
	if err != nil {
		switch {
		case errors.Is(err, service.ErrInvalidHandle):
			respondError(w, http.StatusBadRequest, "invalid_handle", err.Error())
		case errors.Is(err, service.ErrHandleTaken):
			respondError(w, http.StatusConflict, "handle_taken", err.Error())
		default:
			respondError(w, http.StatusInternalServerError, "create_space_error", err.Error())
		}
		return
	}
	respondCreated(w, space)
}

func (h *SpacesHandler) Get(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	id, err := uuid.Parse(chi.URLParam(r, "spaceID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid space ID")
		return
	}
	space, err := h.communitySvc.GetSpace(r.Context(), id, userID)
	if err != nil {
		if errors.Is(err, service.ErrSpaceNotFound) {
			respondError(w, http.StatusNotFound, "not_found", err.Error())
			return
		}
		respondError(w, http.StatusInternalServerError, "get_space_error", err.Error())
		return
	}
	respondSuccess(w, space)
}

func (h *SpacesHandler) Update(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	id, err := uuid.Parse(chi.URLParam(r, "spaceID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid space ID")
		return
	}
	var input domain.UpdateSpaceInput
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	if err := h.communitySvc.UpdateSpace(r.Context(), id, userID, input); err != nil {
		respondCommunityError(w, err)
		return
	}
	respondNoContent(w)
}

func (h *SpacesHandler) Delete(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	id, err := uuid.Parse(chi.URLParam(r, "spaceID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid space ID")
		return
	}
	if err := h.communitySvc.DeleteSpace(r.Context(), id, userID); err != nil {
		respondCommunityError(w, err)
		return
	}
	respondNoContent(w)
}

func (h *SpacesHandler) Join(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	id, err := uuid.Parse(chi.URLParam(r, "spaceID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid space ID")
		return
	}
	if err := h.communitySvc.JoinSpace(r.Context(), id, userID); err != nil {
		respondCommunityError(w, err)
		return
	}
	respondNoContent(w)
}

func (h *SpacesHandler) Leave(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	id, err := uuid.Parse(chi.URLParam(r, "spaceID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid space ID")
		return
	}
	if err := h.communitySvc.LeaveSpace(r.Context(), id, userID); err != nil {
		respondCommunityError(w, err)
		return
	}
	respondNoContent(w)
}

func (h *SpacesHandler) Members(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "spaceID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid space ID")
		return
	}
	q := r.URL.Query()
	limit := parseLimit(q.Get("limit"), 50, 200)
	offset := parseOffset(q.Get("offset"))
	members, err := h.communitySvc.ListMembers(r.Context(), id, limit, offset)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "members_error", err.Error())
		return
	}
	respondSuccess(w, map[string]any{"members": members})
}

// ----- shared helpers (also used by other community handlers) -----

func parseLimit(raw string, def, max int) int {
	if raw == "" {
		return def
	}
	v, err := strconv.Atoi(raw)
	if err != nil || v <= 0 {
		return def
	}
	if v > max {
		return max
	}
	return v
}

func parseOffset(raw string) int {
	if raw == "" {
		return 0
	}
	v, err := strconv.Atoi(raw)
	if err != nil || v < 0 {
		return 0
	}
	return v
}

// respondCommunityError maps known community-service errors to HTTP statuses.
func respondCommunityError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, service.ErrSpaceNotFound),
		errors.Is(err, service.ErrPostNotFound),
		errors.Is(err, service.ErrCommentNotFound):
		respondError(w, http.StatusNotFound, "not_found", err.Error())
	case errors.Is(err, service.ErrForbidden):
		respondError(w, http.StatusForbidden, "forbidden", err.Error())
	case errors.Is(err, service.ErrInvalidHandle),
		errors.Is(err, service.ErrInvalidTargetType):
		respondError(w, http.StatusBadRequest, "invalid_input", err.Error())
	case errors.Is(err, service.ErrHandleTaken):
		respondError(w, http.StatusConflict, "conflict", err.Error())
	default:
		respondError(w, http.StatusInternalServerError, "internal_error", err.Error())
	}
}
