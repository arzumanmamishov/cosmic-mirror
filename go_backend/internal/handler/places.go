package handler

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
	"unicode"

	"cosmic-mirror/internal/tz"
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
		"https://nominatim.openstreetmap.org/search?q=%s&format=json&limit=5&addressdetails=1&namedetails=1&accept-language=en",
		url.QueryEscape(query),
	)

	req, err := http.NewRequestWithContext(r.Context(), http.MethodGet, reqURL, nil)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "request_error", err.Error())
		return
	}
	req.Header.Set("User-Agent", "Lively/1.0")
	// Force Nominatim to return English place names regardless of the
	// device's locale (otherwise it returns names in the local language).
	req.Header.Set("Accept-Language", "en")

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
		// namedetails carries every language variant of the OSM name tag,
		// e.g. {"name:en": "Tbilisi", "name:ka": "თბილისი"}. We prefer the
		// English variant when present.
		NameDetails map[string]string `json:"namedetails"`
		Address     struct {
			City        string `json:"city"`
			Town        string `json:"town"`
			Village     string `json:"village"`
			Hamlet      string `json:"hamlet"`
			Suburb      string `json:"suburb"`
			County      string `json:"county"`
			State       string `json:"state"`
			Country     string `json:"country"`
			CountryCode string `json:"country_code"`
		} `json:"address"`
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

		// Resolve a Latin-script city name. Nominatim's address.city keeps
		// the local-language OSM tag (e.g. "თბილისი" for Tbilisi) even
		// when accept-language=en, so we explicitly check namedetails for
		// "name:en" first. If neither is in Latin, parse the first segment
		// of display_name (which IS translated by accept-language).
		city := r.NameDetails["name:en"]
		if city == "" {
			city = firstLatin(
				r.Address.City,
				r.Address.Town,
				r.Address.Village,
				r.Address.Hamlet,
				r.Address.Suburb,
				r.Address.County,
			)
		}
		if city == "" {
			// First comma-separated segment of display_name.
			if i := strings.Index(r.DisplayName, ","); i > 0 {
				city = strings.TrimSpace(r.DisplayName[:i])
			} else {
				city = r.DisplayName
			}
		}

		name := r.DisplayName
		if city != "" && r.Address.Country != "" {
			if r.Address.State != "" && r.Address.State != city {
				name = fmt.Sprintf("%s, %s, %s", city, r.Address.State, r.Address.Country)
			} else {
				name = fmt.Sprintf("%s, %s", city, r.Address.Country)
			}
		}

		places = append(places, placeSuggestion{
			Name:      name,
			Latitude:  lat,
			Longitude: lon,
			Timezone:  tz.FromCoords(lat, lon),
		})
	}

	respondSuccess(w, map[string]any{"places": places})
}

// firstNonEmpty returns the first non-empty string from the arguments.
func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if v != "" {
			return v
		}
	}
	return ""
}

// firstLatin returns the first non-empty argument whose letters are all in
// the Latin Unicode block (so we never hand back Georgian, Cyrillic, Arabic,
// etc. as a "city" name). Punctuation, spaces, and digits are ignored.
func firstLatin(values ...string) string {
	for _, v := range values {
		if v == "" {
			continue
		}
		latin := true
		for _, r := range v {
			if unicode.IsLetter(r) && !unicode.Is(unicode.Latin, r) {
				latin = false
				break
			}
		}
		if latin {
			return v
		}
	}
	return ""
}

