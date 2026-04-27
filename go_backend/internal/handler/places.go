package handler

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"
)

type PlacesHandler struct {
	httpClient *http.Client
}

func NewPlacesHandler() *PlacesHandler {
	return &PlacesHandler{
		httpClient: &http.Client{Timeout: 10 * time.Second},
	}
}

type placeSuggestion struct {
	Name      string  `json:"name"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Timezone  string  `json:"timezone"`
}

// Search uses the free Nominatim (OpenStreetMap) geocoding API.
func (h *PlacesHandler) Search(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("q")
	if len(query) < 3 {
		respondError(w, http.StatusBadRequest, "invalid_query", "Query must be at least 3 characters")
		return
	}

	reqURL := fmt.Sprintf(
		"https://nominatim.openstreetmap.org/search?q=%s&format=json&limit=5&addressdetails=1",
		url.QueryEscape(query),
	)

	req, err := http.NewRequestWithContext(r.Context(), http.MethodGet, reqURL, nil)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "request_error", err.Error())
		return
	}
	req.Header.Set("User-Agent", "Lively/1.0")

	resp, err := h.httpClient.Do(req)
	if err != nil {
		respondError(w, http.StatusBadGateway, "geocode_error", "Failed to search places")
		return
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "read_error", err.Error())
		return
	}

	var results []struct {
		DisplayName string `json:"display_name"`
		Lat         string `json:"lat"`
		Lon         string `json:"lon"`
	}
	if err := json.Unmarshal(body, &results); err != nil {
		respondError(w, http.StatusInternalServerError, "parse_error", err.Error())
		return
	}

	places := make([]placeSuggestion, 0, len(results))
	for _, r := range results {
		var lat, lon float64
		fmt.Sscanf(r.Lat, "%f", &lat)
		fmt.Sscanf(r.Lon, "%f", &lon)

		tz := timezoneFromCoords(lat, lon)
		places = append(places, placeSuggestion{
			Name:      r.DisplayName,
			Latitude:  lat,
			Longitude: lon,
			Timezone:  tz,
		})
	}

	respondSuccess(w, map[string]any{"places": places})
}

// timezoneFromCoords estimates timezone from longitude.
// For precise results, integrate a timezone API or use a library.
func timezoneFromCoords(lat, lon float64) string {
	_ = lat
	offset := int(lon / 15)
	if offset == 0 {
		return "Etc/UTC"
	}
	if offset > 0 {
		return fmt.Sprintf("Etc/GMT-%d", offset)
	}
	return fmt.Sprintf("Etc/GMT+%d", -offset)
}
