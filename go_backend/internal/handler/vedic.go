package handler

import (
	"net/http"
	"strconv"

	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"

	"github.com/go-chi/chi/v5"
)

type VedicHandler struct {
	vedicSvc *service.VedicService
}

func NewVedicHandler(vedicSvc *service.VedicService) *VedicHandler {
	return &VedicHandler{vedicSvc: vedicSvc}
}

// GetChart returns the Rasi (D1) Vedic chart. Query: ?ayanamsa=lahiri|raman|krishnamurti|fagan
func (h *VedicHandler) GetChart(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	ayanamsa := r.URL.Query().Get("ayanamsa")
	chart, err := h.vedicSvc.GetVedicChart(r.Context(), userID, ayanamsa)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "vedic_chart_error", err.Error())
		return
	}
	respondSuccess(w, chart)
}

// GetDivisionalChart returns one of the Shodashvarga divisional charts.
// Path param: divisor in {2,3,4,7,9,10,12,16,20,24,27,30,40,45,60}.
// Query: ?ayanamsa=...
func (h *VedicHandler) GetDivisionalChart(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	ayanamsa := r.URL.Query().Get("ayanamsa")
	divStr := chi.URLParam(r, "divisor")
	divisor, err := strconv.Atoi(divStr)
	if err != nil || !isValidVarga(divisor) {
		respondError(w, http.StatusBadRequest, "invalid_divisor", "divisor must be one of 2,3,4,7,9,10,12,16,20,24,27,30,40,45,60")
		return
	}
	chart, err := h.vedicSvc.GetDivisionalChart(r.Context(), userID, ayanamsa, divisor)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "vedic_varga_error", err.Error())
		return
	}
	respondSuccess(w, chart)
}

// GetDasha returns the Vimshottari dasha tree. Query: ?ayanamsa=... &levels=1|2|3 (default 3).
func (h *VedicHandler) GetDasha(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	ayanamsa := r.URL.Query().Get("ayanamsa")
	levels := 3
	if l := r.URL.Query().Get("levels"); l != "" {
		if v, err := strconv.Atoi(l); err == nil {
			levels = v
		}
	}
	tree, err := h.vedicSvc.GetDasha(r.Context(), userID, ayanamsa, levels)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "vedic_dasha_error", err.Error())
		return
	}
	respondSuccess(w, tree)
}

// GetYogas returns active classical yogas. Query: ?ayanamsa=...
func (h *VedicHandler) GetYogas(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	ayanamsa := r.URL.Query().Get("ayanamsa")
	yogas, err := h.vedicSvc.GetYogas(r.Context(), userID, ayanamsa)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "vedic_yogas_error", err.Error())
		return
	}
	respondSuccess(w, map[string]any{"yogas": yogas})
}

// GetShadbala returns six-fold strength per planet. Query: ?ayanamsa=...
func (h *VedicHandler) GetShadbala(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	ayanamsa := r.URL.Query().Get("ayanamsa")
	bala, err := h.vedicSvc.GetShadbala(r.Context(), userID, ayanamsa)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "vedic_shadbala_error", err.Error())
		return
	}
	respondSuccess(w, map[string]any{"shadbala": bala})
}

// GetAshtakavarga returns Sarva + Bhinn bindu tables. Query: ?ayanamsa=...
func (h *VedicHandler) GetAshtakavarga(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	ayanamsa := r.URL.Query().Get("ayanamsa")
	av, err := h.vedicSvc.GetAshtakavarga(r.Context(), userID, ayanamsa)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "vedic_ashtakavarga_error", err.Error())
		return
	}
	respondSuccess(w, av)
}

// isValidVarga whitelists the 16 standard divisor codes (Shodashvarga).
func isValidVarga(d int) bool {
	switch d {
	case 2, 3, 4, 7, 9, 10, 12, 16, 20, 24, 27, 30, 40, 45, 60:
		return true
	}
	return false
}
