package handler

import (
	"net/http"

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
	// forecastType := r.URL.Query().Get("type")
	respondSuccess(w, map[string]any{
		"type":    r.URL.Query().Get("type"),
		"periods": []any{},
	})
}

func (h *ChartHandler) GetYearlyForecast(w http.ResponseWriter, r *http.Request) {
	respondSuccess(w, map[string]any{
		"year":     2024,
		"theme":    "",
		"overview": "",
		"quarters": []any{},
	})
}
