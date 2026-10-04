package handler

import (
	"context"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"
	"time"
)

const nominatimFixture = `[{"display_name":"Istanbul, Marmara Region, Türkiye","lat":"41.0","lon":"28.9",
 "namedetails":{"name:en":"Istanbul"},"address":{"city":"İstanbul","state":"Marmara Region","country":"Türkiye"}}]`

func newTestPlaces(t *testing.T, status int) (*PlacesHandler, *int32) {
	t.Helper()
	var calls int32
	up := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		atomic.AddInt32(&calls, 1)
		if ua := r.Header.Get("User-Agent"); ua != nominatimUserAgent {
			t.Errorf("unexpected User-Agent %q", ua)
		}
		w.WriteHeader(status)
		_, _ = w.Write([]byte(nominatimFixture))
	}))
	t.Cleanup(up.Close)
	h := NewPlacesHandler()
	h.baseURL = up.URL
	return h, &calls
}

func search(h *PlacesHandler, q string) *httptest.ResponseRecorder {
	rec := httptest.NewRecorder()
	h.Search(rec, httptest.NewRequest(http.MethodGet, "/api/v1/places/search?q="+q, nil))
	return rec
}

func TestPlacesSearchCachesNormalizedQuery(t *testing.T) {
	h, calls := newTestPlaces(t, http.StatusOK)
	if rec := search(h, "Istanbul"); rec.Code != http.StatusOK {
		t.Fatalf("status %d: %s", rec.Code, rec.Body)
	}
	if rec := search(h, "%20%20istanbul%20"); rec.Code != http.StatusOK {
		t.Fatalf("status %d", rec.Code)
	}
	if got := atomic.LoadInt32(calls); got != 1 {
		t.Fatalf("upstream called %d times, want 1 (second query should hit the cache)", got)
	}
}

func TestPlacesSearchValidationAndUpstreamErrors(t *testing.T) {
	h, _ := newTestPlaces(t, http.StatusTooManyRequests)
	if rec := search(h, "ab"); rec.Code != http.StatusBadRequest {
		t.Fatalf("short query: status %d", rec.Code)
	}
	if rec := search(h, "Ankara"); rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("upstream 429: status %d, want 503", rec.Code)
	}
}

func TestUpstreamThrottleSpacesCalls(t *testing.T) {
	th := &upstreamThrottle{interval: 100 * time.Millisecond}
	ctx := context.Background()
	start := time.Now()
	for i := 0; i < 3; i++ {
		if err := th.wait(ctx, time.Second); err != nil {
			t.Fatal(err)
		}
	}
	if el := time.Since(start); el < 190*time.Millisecond {
		t.Fatalf("3 calls took %v, want >= ~200ms", el)
	}
	// Queue longer than maxWait → rejected immediately.
	for i := 0; i < 5; i++ {
		_ = th.wait(ctx, 0)
	}
	if err := th.wait(ctx, 10*time.Millisecond); err != errPlacesBusy {
		t.Fatalf("want errPlacesBusy, got %v", err)
	}
}
