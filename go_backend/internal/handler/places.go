package handler

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"strings"
	"sync"
	"time"
	"unicode"
	"unicode/utf8"

	"cosmic-mirror/internal/tz"

	"github.com/redis/go-redis/v9"
)

// Nominatim usage policy (https://operations.osmfoundation.org/policies/nominatim/):
// at most 1 request/second for the whole application, an identifying
// User-Agent with contact details, and results must be cached. The public
// instance is a stop-gap — switch to a paid or self-hosted geocoder before
// traffic grows.
const (
	nominatimUserAgent = "Lively/1.0 (+https://livelyapp.co; hello@livelyapp.co)"
	// placesCacheTTL: place coordinates practically never change.
	placesCacheTTL = 30 * 24 * time.Hour
	// placesEmptyCacheTTL: a miss may be fixed by an OSM edit; retry sooner.
	placesEmptyCacheTTL = 24 * time.Hour
	// placesMaxQueue is the longest a request may wait for an upstream
	// slot before we answer 503 instead of piling up goroutines.
	placesMaxQueue    = 3 * time.Second
	placesMemCacheMax = 5000
	placesMinRunes    = 3
	placesMaxRunes    = 120
)

type PlacesHandler struct {
	httpClient *http.Client
	rdb        *redis.Client // optional; nil → in-process cache only
	throttle   *upstreamThrottle
	mem        *placesMemCache
	baseURL    string
}

func NewPlacesHandler() *PlacesHandler {
	return &PlacesHandler{
		httpClient: &http.Client{Timeout: 10 * time.Second},
		throttle:   &upstreamThrottle{interval: time.Second},
		mem:        &placesMemCache{entries: map[string]placesMemEntry{}},
		baseURL:    "https://nominatim.openstreetmap.org/search",
	}
}

// WithRedis shares the results cache across instances and restarts.
// Without it the handler still caches in process.
func (h *PlacesHandler) WithRedis(rdb *redis.Client) *PlacesHandler {
	h.rdb = rdb
	return h
}

type placeSuggestion struct {
	Name      string  `json:"name"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Timezone  string  `json:"timezone"`
}

// cleanPlaceQuery trims and collapses whitespace; this is what goes
// upstream. placesCacheKey additionally case-folds it so "Istanbul" and
// "istanbul" share a cache entry.
func cleanPlaceQuery(q string) string {
	return strings.Join(strings.Fields(q), " ")
}

// Search geocodes a free-text place via Nominatim (OpenStreetMap), with a
// result cache and a global upstream throttle (see constants above).
func (h *PlacesHandler) Search(w http.ResponseWriter, r *http.Request) {
	query := cleanPlaceQuery(r.URL.Query().Get("q"))
	if n := utf8.RuneCountInString(query); n < placesMinRunes {
		respondError(w, http.StatusBadRequest, "invalid_query", "Query must be at least 3 characters")
		return
	} else if n > placesMaxRunes {
		respondError(w, http.StatusBadRequest, "invalid_query", "Query is too long")
		return
	}

	ctx := r.Context()
	if places, ok := h.cacheGet(ctx, query); ok {
		respondSuccess(w, map[string]any{"places": places})
		return
	}

	places, err := h.fetch(ctx, query)
	if err != nil {
		if ctx.Err() != nil {
			return // client went away
		}
		slog.Warn("places: geocoder unavailable", "error", err)
		respondError(w, http.StatusServiceUnavailable, "geocoder_unavailable",
			"Place search is busy right now. Please try again in a moment.")
		return
	}
	h.cacheSet(ctx, query, places)
	respondSuccess(w, map[string]any{"places": places})
}

// fetch performs one throttled upstream lookup.
func (h *PlacesHandler) fetch(ctx context.Context, query string) ([]placeSuggestion, error) {
	if err := h.throttle.wait(ctx, placesMaxQueue); err != nil {
		return nil, err
	}

	reqURL := fmt.Sprintf(
		"%s?q=%s&format=json&limit=5&addressdetails=1&namedetails=1&accept-language=en",
		h.baseURL, url.QueryEscape(query),
	)
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, reqURL, nil)
	if err != nil {
		return nil, err
	}
	req.Header.Set("User-Agent", nominatimUserAgent)
	// Force Nominatim to return English place names regardless of the
	// device's locale (otherwise it returns names in the local language).
	req.Header.Set("Accept-Language", "en")

	resp, err := h.httpClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		// 429 / 403 here means we're being throttled or blocked upstream.
		return nil, fmt.Errorf("nominatim status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return nil, err
	}
	return parseNominatim(body)
}

// parseNominatim turns a Nominatim JSON response into suggestions.
func parseNominatim(body []byte) ([]placeSuggestion, error) {
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
		return nil, fmt.Errorf("parse nominatim response: %w", err)
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

	return places, nil
}

func placesCacheKey(query string) string {
	sum := sha256.Sum256([]byte(strings.ToLower(query)))
	return "places:v1:" + hex.EncodeToString(sum[:])
}

func (h *PlacesHandler) cacheGet(ctx context.Context, query string) ([]placeSuggestion, bool) {
	key := placesCacheKey(query)
	if places, ok := h.mem.get(key); ok {
		return places, true
	}
	if h.rdb == nil {
		return nil, false
	}
	data, err := h.rdb.Get(ctx, key).Bytes()
	if err != nil {
		return nil, false
	}
	var places []placeSuggestion
	if json.Unmarshal(data, &places) != nil {
		return nil, false
	}
	h.mem.set(key, places, placesTTL(places))
	return places, true
}

func (h *PlacesHandler) cacheSet(ctx context.Context, query string, places []placeSuggestion) {
	key, ttl := placesCacheKey(query), placesTTL(places)
	h.mem.set(key, places, ttl)
	if h.rdb == nil {
		return
	}
	if data, err := json.Marshal(places); err == nil {
		h.rdb.Set(ctx, key, data, ttl)
	}
}

func placesTTL(places []placeSuggestion) time.Duration {
	if len(places) == 0 {
		return placesEmptyCacheTTL
	}
	return placesCacheTTL
}

// upstreamThrottle spaces upstream calls at least [interval] apart across
// all requests in this process. It is per instance: with N API replicas
// the combined rate is N req/s, so either run one instance, share the
// Redis cache (WithRedis) to keep upstream traffic low, or move to a
// geocoder without the 1 req/s policy.
type upstreamThrottle struct {
	mu       sync.Mutex
	next     time.Time
	interval time.Duration
}

var errPlacesBusy = errors.New("places: upstream queue full")

// wait blocks until this caller's slot. If the queue is already longer
// than [maxWait] it returns errPlacesBusy immediately without taking a slot.
func (t *upstreamThrottle) wait(ctx context.Context, maxWait time.Duration) error {
	t.mu.Lock()
	now := time.Now()
	slot := t.next
	if slot.Before(now) {
		slot = now
	}
	if slot.Sub(now) > maxWait {
		t.mu.Unlock()
		return errPlacesBusy
	}
	t.next = slot.Add(t.interval)
	t.mu.Unlock()

	d := time.Until(slot)
	if d <= 0 {
		return nil
	}
	timer := time.NewTimer(d)
	defer timer.Stop()
	select {
	case <-ctx.Done():
		return ctx.Err()
	case <-timer.C:
		return nil
	}
}

// placesMemCache is a small bounded in-process cache in front of Redis
// (and the only cache when Redis isn't wired in).
type placesMemCache struct {
	mu      sync.Mutex
	entries map[string]placesMemEntry
}

type placesMemEntry struct {
	places  []placeSuggestion
	expires time.Time
}

func (c *placesMemCache) get(key string) ([]placeSuggestion, bool) {
	c.mu.Lock()
	defer c.mu.Unlock()
	e, ok := c.entries[key]
	if !ok {
		return nil, false
	}
	if time.Now().After(e.expires) {
		delete(c.entries, key)
		return nil, false
	}
	return e.places, true
}

func (c *placesMemCache) set(key string, places []placeSuggestion, ttl time.Duration) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if len(c.entries) >= placesMemCacheMax {
		// Crude but bounded: drop ~10% of entries (map order is random).
		drop := placesMemCacheMax / 10
		for k := range c.entries {
			delete(c.entries, k)
			if drop--; drop <= 0 {
				break
			}
		}
	}
	c.entries[key] = placesMemEntry{places: places, expires: time.Now().Add(ttl)}
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
