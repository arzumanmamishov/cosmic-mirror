package handler

import (
	"errors"
	"net/http"
	"strconv"
	"time"
	"unicode/utf8"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/repository"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type JournalHandler struct {
	journalRepo repository.JournalRepository
}

func NewJournalHandler(journalRepo repository.JournalRepository) *JournalHandler {
	return &JournalHandler{journalRepo: journalRepo}
}

func (h *JournalHandler) List(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	limit := 20
	offset := 0

	if l := r.URL.Query().Get("limit"); l != "" {
		if v, err := strconv.Atoi(l); err == nil && v > 0 && v <= 50 {
			limit = v
		}
	}
	if o := r.URL.Query().Get("offset"); o != "" {
		if v, err := strconv.Atoi(o); err == nil && v >= 0 {
			offset = v
		}
	}

	entries, err := h.journalRepo.List(r.Context(), userID, limit, offset)
	if err != nil {
		respondServiceError(w, http.StatusInternalServerError, "journal_error", err)
		return
	}
	respondSuccess(w, map[string]any{"entries": entries})
}

// maxJournalRunes caps a single journal entry.
const maxJournalRunes = 10000

func (h *JournalHandler) Create(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	var input domain.CreateJournalInput
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	if utf8.RuneCountInString(input.Content) > maxJournalRunes ||
		(input.Mood != nil && len(*input.Mood) > 32) {
		respondError(w, http.StatusBadRequest, "invalid_body", "Journal entry is too long")
		return
	}

	entryDate := time.Now()
	if input.EntryDate != "" {
		if parsed, err := time.Parse("2006-01-02", input.EntryDate); err == nil {
			entryDate = parsed
		}
	}

	entry := &domain.JournalEntry{
		UserID:    userID,
		EntryDate: entryDate,
		Content:   input.Content,
		Mood:      input.Mood,
	}

	if err := h.journalRepo.Create(r.Context(), entry); err != nil {
		respondServiceError(w, http.StatusInternalServerError, "create_error", err)
		return
	}
	respondCreated(w, entry)
}

func (h *JournalHandler) Update(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	entryID, err := uuid.Parse(chi.URLParam(r, "entryID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid entry ID")
		return
	}

	var input domain.UpdateJournalInput
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	if (input.Content != nil && utf8.RuneCountInString(*input.Content) > maxJournalRunes) ||
		(input.Mood != nil && len(*input.Mood) > 32) {
		respondError(w, http.StatusBadRequest, "invalid_body", "Journal entry is too long")
		return
	}

	if err := h.journalRepo.Update(r.Context(), entryID, userID, input); err != nil {
		if errors.Is(err, repository.ErrJournalEntryNotFound) {
			respondError(w, http.StatusNotFound, "not_found", "Journal entry not found")
			return
		}
		respondServiceError(w, http.StatusInternalServerError, "update_error", err)
		return
	}
	respondNoContent(w)
}
