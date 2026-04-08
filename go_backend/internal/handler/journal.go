package handler

import (
	"net/http"
	"strconv"
	"time"

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
		respondError(w, http.StatusInternalServerError, "journal_error", err.Error())
		return
	}
	respondSuccess(w, map[string]any{"entries": entries})
}

func (h *JournalHandler) Create(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	var input domain.CreateJournalInput
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
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
		respondError(w, http.StatusInternalServerError, "create_error", err.Error())
		return
	}
	respondCreated(w, entry)
}

func (h *JournalHandler) Update(w http.ResponseWriter, r *http.Request) {
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

	if err := h.journalRepo.Update(r.Context(), entryID, input); err != nil {
		respondError(w, http.StatusInternalServerError, "update_error", err.Error())
		return
	}
	respondNoContent(w)
}
