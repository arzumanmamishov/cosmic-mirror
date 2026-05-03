package handler

import (
	"net/http"

	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type CommunityNotificationsHandler struct {
	notifSvc *service.CommunityNotificationService
}

func NewCommunityNotificationsHandler(notifSvc *service.CommunityNotificationService) *CommunityNotificationsHandler {
	return &CommunityNotificationsHandler{notifSvc: notifSvc}
}

func (h *CommunityNotificationsHandler) List(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	q := r.URL.Query()
	unreadOnly := q.Get("unread") == "true"
	limit := parseLimit(q.Get("limit"), 30, 100)
	offset := parseOffset(q.Get("offset"))

	notifs, err := h.notifSvc.List(r.Context(), userID, unreadOnly, limit, offset)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "notifications_list_error", err.Error())
		return
	}
	respondSuccess(w, map[string]any{"notifications": notifs})
}

func (h *CommunityNotificationsHandler) UnreadCount(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	count, err := h.notifSvc.UnreadCount(r.Context(), userID)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "unread_count_error", err.Error())
		return
	}
	respondSuccess(w, map[string]any{"unread_count": count})
}

func (h *CommunityNotificationsHandler) MarkRead(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	id, err := uuid.Parse(chi.URLParam(r, "notificationID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid notification ID")
		return
	}
	if err := h.notifSvc.MarkRead(r.Context(), id, userID); err != nil {
		respondError(w, http.StatusInternalServerError, "mark_read_error", err.Error())
		return
	}
	respondNoContent(w)
}

func (h *CommunityNotificationsHandler) MarkAllRead(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	if err := h.notifSvc.MarkAllRead(r.Context(), userID); err != nil {
		respondError(w, http.StatusInternalServerError, "mark_all_read_error", err.Error())
		return
	}
	respondNoContent(w)
}
