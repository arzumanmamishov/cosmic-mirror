package handler

import (
	"bytes"
	"errors"
	"io"
	"net/http"
	"path/filepath"
	"regexp"
	"strings"
	"unicode/utf8"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/repository"
	"cosmic-mirror/internal/service"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type UserHandler struct {
	userSvc    *service.UserService
	prefsRepo  repository.PreferencesRepository
	ritualRepo repository.RitualRepository
}

func NewUserHandler(
	userSvc *service.UserService,
	prefsRepo repository.PreferencesRepository,
	ritualRepo repository.RitualRepository,
) *UserHandler {
	return &UserHandler{userSvc: userSvc, prefsRepo: prefsRepo, ritualRepo: ritualRepo}
}

// loadPrefs returns the user's stored preferences, falling back to defaults
// when they've never saved any.
func (h *UserHandler) loadPrefs(r *http.Request, userID uuid.UUID) (domain.UserPreferences, error) {
	stored, err := h.prefsRepo.Get(r.Context(), userID)
	if err != nil {
		return domain.UserPreferences{}, err
	}
	if stored == nil {
		return domain.DefaultUserPreferences(userID), nil
	}
	return *stored, nil
}

func (h *UserHandler) GetMe(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	user, err := h.userSvc.GetUser(r.Context(), userID)
	if err != nil || user == nil {
		respondError(w, http.StatusNotFound, "not_found", "User not found")
		return
	}
	// The client's router uses has_completed_onboarding to decide
	// /home vs /onboarding on every route change, so it MUST be
	// included here — omitting it made the Flutter side default to
	// false and trapped fresh-post-onboarding users in a
	// /home → /onboarding redirect loop.
	respondSuccess(w, map[string]any{
		"id":                       user.ID,
		"email":                    user.Email,
		"name":                     user.Name,
		"avatar_url":               user.AvatarURL,
		"has_completed_onboarding": h.userSvc.HasCompletedOnboarding(r.Context(), user.ID),
		"created_at":               user.CreatedAt,
		"updated_at":               user.UpdatedAt,
	})
}

func (h *UserHandler) UpdateMe(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	var input domain.UpdateUserInput
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	// The display name is shown to other users and fed into AI prompts.
	if input.Name != nil && utf8.RuneCountInString(*input.Name) > maxNameRunes {
		respondError(w, http.StatusBadRequest, "invalid_body", "Name must be at most 80 characters")
		return
	}
	if err := h.userSvc.UpdateUser(r.Context(), userID, input); err != nil {
		respondServiceError(w, http.StatusInternalServerError, "update_error", err)
		return
	}
	respondNoContent(w)
}

func (h *UserHandler) DeleteMe(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	if err := h.userSvc.DeleteUser(r.Context(), userID); err != nil {
		respondServiceError(w, http.StatusInternalServerError, "delete_error", err)
		return
	}
	respondNoContent(w)
}

// AvatarMaxBytes caps an avatar upload request (multipart body included)
// so a misbehaving client can't fill the disk in one shot. The router's
// global body limit uses the same value for this route only.
const AvatarMaxBytes = 8 << 20

// avatarExts / isAvatarImage mirror the avatar store's allow-list so an
// unsupported image is rejected with 415 here instead of surfacing as a
// 500 from the store.
var avatarExts = map[string]bool{".jpg": true, ".jpeg": true, ".png": true, ".webp": true, ".heic": true}

func isAvatarImage(head []byte) bool {
	switch http.DetectContentType(head) {
	case "image/jpeg", "image/png", "image/webp":
		return true
	}
	if len(head) >= 12 && string(head[4:8]) == "ftyp" {
		switch string(head[8:12]) {
		case "heic", "heix", "hevc", "hevx", "mif1", "msf1", "heim", "heis":
			return true
		}
	}
	return false
}

// UploadAvatar reads a multipart "file" field, saves it via the avatar
// store, and returns the new public URL on the user object.
func (h *UserHandler) UploadAvatar(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())

	const maxBytes = AvatarMaxBytes
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

	if !avatarExts[strings.ToLower(filepath.Ext(header.Filename))] {
		respondError(w, http.StatusUnsupportedMediaType, "unsupported_image",
			"Avatar must be a JPEG, PNG, WebP or HEIC image.")
		return
	}
	head := make([]byte, 512)
	n, err := io.ReadFull(file, head)
	if err != nil && !errors.Is(err, io.ErrUnexpectedEOF) {
		respondError(w, http.StatusBadRequest, "invalid_file", "Could not read the uploaded file.")
		return
	}
	if !isAvatarImage(head[:n]) {
		respondError(w, http.StatusUnsupportedMediaType, "unsupported_image",
			"Avatar must be a JPEG, PNG, WebP or HEIC image.")
		return
	}
	src := io.MultiReader(bytes.NewReader(head[:n]), file)

	url, err := h.userSvc.SetAvatar(r.Context(), userID, header.Filename, src)
	if err != nil {
		respondServiceError(w, http.StatusInternalServerError, "save_error", err)
		return
	}
	respondSuccess(w, map[string]string{"avatar_url": url})
}

// DeleteAvatar removes the user's avatar file and clears the column.
func (h *UserHandler) DeleteAvatar(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	if err := h.userSvc.ClearAvatar(r.Context(), userID); err != nil {
		respondServiceError(w, http.StatusInternalServerError, "clear_error", err)
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
		respondServiceError(w, http.StatusInternalServerError, "profile_error", err)
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
		respondServiceError(w, http.StatusInternalServerError, "profile_error", err)
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
		respondServiceError(w, http.StatusInternalServerError, "stats_error", err)
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
		respondServiceError(w, http.StatusInternalServerError, "profile_error", err)
		return
	}
	if profile == nil {
		respondError(w, http.StatusNotFound, "not_found", "Birth profile not found")
		return
	}
	respondSuccess(w, profile)
}

func (h *UserHandler) GetPreferences(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	prefs, err := h.loadPrefs(r, userID)
	if err != nil {
		respondServiceError(w, http.StatusInternalServerError, "prefs_error", err)
		return
	}
	respondSuccess(w, map[string]any{
		"focus_areas":          prefs.FocusAreas,
		"notification_enabled": prefs.NotificationEnabled,
		"notification_time":    prefs.NotificationTime,
		"theme":                prefs.Theme,
	})
}

func (h *UserHandler) UpdatePreferences(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	var input domain.UpdatePreferencesInput
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	if input.FocusAreas != nil {
		if len(*input.FocusAreas) > 20 {
			respondError(w, http.StatusBadRequest, "invalid_body", "Too many focus areas")
			return
		}
		for _, f := range *input.FocusAreas {
			if len(f) > 64 {
				respondError(w, http.StatusBadRequest, "invalid_body", "Focus area is too long")
				return
			}
		}
	}
	if input.NotificationTime != nil && !isHHMM(*input.NotificationTime) {
		respondError(w, http.StatusBadRequest, "invalid_body", "notification_time must be HH:MM (24-hour)")
		return
	}
	if input.Theme != nil && !validThemes[strings.ToLower(strings.TrimSpace(*input.Theme))] {
		respondError(w, http.StatusBadRequest, "invalid_body", "theme must be one of: dark, light, system")
		return
	}
	prefs, err := h.loadPrefs(r, userID)
	if err != nil {
		respondServiceError(w, http.StatusInternalServerError, "prefs_error", err)
		return
	}
	if input.FocusAreas != nil {
		prefs.FocusAreas = *input.FocusAreas
	}
	if input.NotificationEnabled != nil {
		prefs.NotificationEnabled = *input.NotificationEnabled
	}
	if input.NotificationTime != nil {
		prefs.NotificationTime = *input.NotificationTime
	}
	if input.Theme != nil {
		prefs.Theme = strings.ToLower(strings.TrimSpace(*input.Theme))
	}
	if err := h.prefsRepo.Upsert(r.Context(), &prefs); err != nil {
		respondServiceError(w, http.StatusInternalServerError, "prefs_error", err)
		return
	}
	respondNoContent(w)
}

// validThemes are the values the theme column accepts (VARCHAR(20),
// default "dark"). The app doesn't send a theme today; this keeps
// arbitrary strings (or a 21+ char value → DB error → 500) out.
var validThemes = map[string]bool{"dark": true, "light": true, "system": true}

// hhmm matches a 24-hour "HH:MM" time — the notification_time column is
// VARCHAR(5) and the notification worker compares it to HH24:MI.
var hhmm = regexp.MustCompile(`^([01][0-9]|2[0-3]):[0-5][0-9]$`)

func isHHMM(s string) bool { return hhmm.MatchString(s) }

// ritualCatalog is the fixed set of daily rituals the app offers. Completion
// state is layered on from the user's ritual_completions rows.
var ritualCatalog = []struct{ Type, Title string }{
	{"morning_intention", "Morning Intention"},
	{"affirmation", "Daily Affirmation"},
	{"evening_reflection", "Evening Reflection"},
}

func (h *UserHandler) GetRitualsToday(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	completions, err := h.ritualRepo.GetTodayCompletions(r.Context(), userID)
	if err != nil {
		respondServiceError(w, http.StatusInternalServerError, "rituals_error", err)
		return
	}
	done := make(map[string]bool, len(completions))
	for _, c := range completions {
		done[c.RitualType] = true
	}
	rituals := make([]map[string]any, 0, len(ritualCatalog))
	for _, rt := range ritualCatalog {
		rituals = append(rituals, map[string]any{
			"type":      rt.Type,
			"title":     rt.Title,
			"completed": done[rt.Type],
		})
	}
	streak, err := h.ritualRepo.GetStreak(r.Context(), userID)
	if err != nil {
		respondServiceError(w, http.StatusInternalServerError, "rituals_error", err)
		return
	}
	respondSuccess(w, map[string]any{"rituals": rituals, "streak": streak})
}

func (h *UserHandler) CompleteRitual(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	ritualType := chi.URLParam(r, "type")
	valid := false
	for _, rt := range ritualCatalog {
		if rt.Type == ritualType {
			valid = true
			break
		}
	}
	if !valid {
		respondError(w, http.StatusBadRequest, "invalid_ritual", "Unknown ritual type")
		return
	}
	c := &domain.RitualCompletion{UserID: userID, RitualType: ritualType}
	if err := h.ritualRepo.Complete(r.Context(), c); err != nil {
		respondServiceError(w, http.StatusInternalServerError, "ritual_error", err)
		return
	}
	streak, err := h.ritualRepo.GetStreak(r.Context(), userID)
	if err != nil {
		respondServiceError(w, http.StatusInternalServerError, "ritual_error", err)
		return
	}
	respondSuccess(w, map[string]any{"completed": true, "streak": streak})
}

func (h *UserHandler) GetNotificationPrefs(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	prefs, err := h.loadPrefs(r, userID)
	if err != nil {
		respondServiceError(w, http.StatusInternalServerError, "prefs_error", err)
		return
	}
	respondSuccess(w, map[string]any{
		"daily_reading":  prefs.NotifDailyReading,
		"affirmation":    prefs.NotifAffirmation,
		"weekly":         prefs.NotifWeekly,
		"preferred_time": prefs.NotificationTime,
	})
}

func (h *UserHandler) UpdateNotificationPrefs(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	var input domain.UpdateNotificationPrefsInput
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	if input.PreferredTime != nil && !isHHMM(*input.PreferredTime) {
		respondError(w, http.StatusBadRequest, "invalid_body", "preferred_time must be HH:MM (24-hour)")
		return
	}
	prefs, err := h.loadPrefs(r, userID)
	if err != nil {
		respondServiceError(w, http.StatusInternalServerError, "prefs_error", err)
		return
	}
	if input.DailyReading != nil {
		prefs.NotifDailyReading = *input.DailyReading
	}
	if input.Affirmation != nil {
		prefs.NotifAffirmation = *input.Affirmation
	}
	if input.Weekly != nil {
		prefs.NotifWeekly = *input.Weekly
	}
	if input.PreferredTime != nil {
		prefs.NotificationTime = *input.PreferredTime
	}
	if err := h.prefsRepo.Upsert(r.Context(), &prefs); err != nil {
		respondServiceError(w, http.StatusInternalServerError, "prefs_error", err)
		return
	}
	respondNoContent(w)
}
