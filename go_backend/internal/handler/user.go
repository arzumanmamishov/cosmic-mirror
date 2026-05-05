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

// UploadAvatar reads a multipart "file" field, saves it via the avatar
// store, and returns the new public URL on the user object.
func (h *UserHandler) UploadAvatar(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())

	// Cap to 8MB so a misbehaving client can't fill the disk in one shot.
	const maxBytes = 8 << 20
	r.Body = http.MaxBytesReader(w, r.Body, maxBytes)

	if err := r.ParseMultipartForm(maxBytes); err != nil {
		respondError(w, http.StatusBadRequest, "upload_too_large",
			"File is too large or malformed (max 8MB).")
		return
	}
	file, header, err := r.FormFile("file")
	if err != nil {
		respondError(w, http.StatusBadRequest, "missing_file",
			"Form must include a file field named 'file'.")
		return
	}
	defer file.Close()

	url, err := h.userSvc.SetAvatar(r.Context(), userID, header.Filename, file)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "save_error", err.Error())
		return
	}
	respondSuccess(w, map[string]string{"avatar_url": url})
}

// DeleteAvatar removes the user's avatar file and clears the column.
func (h *UserHandler) DeleteAvatar(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	if err := h.userSvc.ClearAvatar(r.Context(), userID); err != nil {
		respondError(w, http.StatusInternalServerError, "clear_error", err.Error())
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

// GetStats returns the engagement snapshot for the profile screen
// (streak, journal entry count, AI chat thread count).
func (h *UserHandler) GetStats(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	stats, err := h.userSvc.GetStats(r.Context(), userID)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "stats_error", err.Error())
		return
	}
	respondSuccess(w, stats)
}

// GetBirthProfile returns the user's stored birth data so the profile
// screen can show real values instead of placeholders.
func (h *UserHandler) GetBirthProfile(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	profile, err := h.userSvc.GetBirthProfile(r.Context(), userID)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "profile_error", err.Error())
		return
	}
	if profile == nil {
		respondError(w, http.StatusNotFound, "not_found", "Birth profile not found")
		return
	}
	respondSuccess(w, profile)
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
