package handler

import (
	"net/http"
	"time"

	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"

	"github.com/go-chi/chi/v5"
)

type DailyReadingHandler struct {
	readingSvc *service.ReadingService
}

func NewDailyReadingHandler(readingSvc *service.ReadingService) *DailyReadingHandler {
	return &DailyReadingHandler{readingSvc: readingSvc}
}

func (h *DailyReadingHandler) GetToday(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	today := time.Now().Truncate(24 * time.Hour)

	reading, err := h.readingSvc.GetDailyReading(r.Context(), userID, today)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "reading_error", err.Error())
		return
	}
	respondSuccess(w, reading)
}

func (h *DailyReadingHandler) GetByDate(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	dateStr := chi.URLParam(r, "date")

	date, err := time.Parse("2006-01-02", dateStr)
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_date", "Date must be in YYYY-MM-DD format")
		return
	}

	reading, err := h.readingSvc.GetDailyReading(r.Context(), userID, date)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "reading_error", err.Error())
		return
	}
	respondSuccess(w, reading)
}
