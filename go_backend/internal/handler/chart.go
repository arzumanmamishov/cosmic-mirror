package handler

import (
	"net/http"
	"strconv"
	"time"

	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"
)

type ChartHandler struct {
	chartSvc *service.ChartService
}

func NewChartHandler(chartSvc *service.ChartService) *ChartHandler {
	return &ChartHandler{chartSvc: chartSvc}
}

func (h *ChartHandler) GetChart(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	chart, err := h.chartSvc.GetNatalChart(r.Context(), userID)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "chart_error", err.Error())
		return
	}
	respondSuccess(w, chart)
}

func (h *ChartHandler) GetSummary(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	summary, err := h.chartSvc.GetChartSummary(r.Context(), userID)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "chart_error", err.Error())
		return
	}
	respondSuccess(w, summary)
}

func (h *ChartHandler) GetTimeline(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	forecastType := r.URL.Query().Get("type")
	timeline, err := h.chartSvc.GetTimeline(r.Context(), userID, forecastType)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "timeline_error", err.Error())
		return
	}
	respondSuccess(w, timeline)
}

func (h *ChartHandler) GetYearlyForecast(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	year := time.Now().UTC().Year()
	if y := r.URL.Query().Get("year"); y != "" {
		if parsed, err := strconv.Atoi(y); err == nil && parsed >= 1900 && parsed <= 2100 {
			year = parsed
		}
	}
	forecast, err := h.chartSvc.GetYearlyForecast(r.Context(), userID, year)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "yearly_error", err.Error())
		return
	}
	respondSuccess(w, forecast)
}
