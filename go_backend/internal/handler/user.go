package handler

import (
	"net/http"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"
)

type UserHandler struct {
	userSvc *service.UserService
}

func NewUserHandler(userSvc *service.UserService) *UserHandler {
	return &UserHandler{userSvc: userSvc}
}

func (h *UserHandler) GetMe(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	user, err := h.userSvc.GetUser(r.Context(), userID)
	if err != nil || user == nil {
		respondError(w, http.StatusNotFound, "not_found", "User not found")
		return
	}
	respondSuccess(w, user)
}

func (h *UserHandler) UpdateMe(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	var input domain.UpdateUserInput
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	if err := h.userSvc.UpdateUser(r.Context(), userID, input); err != nil {
		respondError(w, http.StatusInternalServerError, "update_error", err.Error())
		return
	}
	respondNoContent(w)
}

func (h *UserHandler) DeleteMe(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	if err := h.userSvc.DeleteUser(r.Context(), userID); err != nil {
		respondError(w, http.StatusInternalServerError, "delete_error", err.Error())
		return
	}
	respondNoContent(w)
}

func (h *UserHandler) CreateBirthProfile(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	var input domain.CreateBirthProfileInput
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	profile, err := h.userSvc.CreateBirthProfile(r.Context(), userID, input)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "profile_error", err.Error())
		return
	}
	respondCreated(w, profile)
}

func (h *UserHandler) UpdateBirthProfile(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	var input domain.CreateBirthProfileInput
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	if err := h.userSvc.UpdateBirthProfile(r.Context(), userID, input); err != nil {
		respondError(w, http.StatusInternalServerError, "profile_error", err.Error())
		return
	}
	respondNoContent(w)
}

func (h *UserHandler) GetPreferences(w http.ResponseWriter, r *http.Request) {
	respondSuccess(w, map[string]any{
		"focus_areas":          []string{},
		"notification_enabled": true,
		"notification_time":    "09:00",
		"theme":                "dark",
	})
}

func (h *UserHandler) UpdatePreferences(w http.ResponseWriter, r *http.Request) {
	respondNoContent(w)
}

func (h *UserHandler) GetRitualsToday(w http.ResponseWriter, r *http.Request) {
	respondSuccess(w, map[string]any{
		"rituals": []map[string]any{
			{"type": "morning_intention", "title": "Morning Intention", "completed": false},
			{"type": "affirmation", "title": "Daily Affirmation", "completed": false},
			{"type": "evening_reflection", "title": "Evening Reflection", "completed": false},
		},
		"streak": 0,
	})
}

func (h *UserHandler) CompleteRitual(w http.ResponseWriter, r *http.Request) {
	respondSuccess(w, map[string]any{"completed": true, "streak": 1})
}

func (h *UserHandler) GetNotificationPrefs(w http.ResponseWriter, r *http.Request) {
	respondSuccess(w, map[string]any{
		"daily_reading": true,
		"affirmation":   true,
		"weekly":        true,
		"preferred_time": "09:00",
	})
}

func (h *UserHandler) UpdateNotificationPrefs(w http.ResponseWriter, r *http.Request) {
	respondNoContent(w)
}
