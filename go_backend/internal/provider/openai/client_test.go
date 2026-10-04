package openai

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"
	"time"
)

// Retries must resend the full request body (a reused *http.Request would
// send an empty, already-drained body on the second attempt).
func TestDoRequestRetriesWithFullBody(t *testing.T) {
	var calls atomic.Int32
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		n := calls.Add(1)
		b, _ := io.ReadAll(r.Body)
		var req chatRequest
		if err := json.Unmarshal(b, &req); err != nil || len(req.Messages) != 1 {
			t.Errorf("attempt %d: bad body %q: %v", n, b, err)
		}
		if n == 1 {
			w.WriteHeader(http.StatusServiceUnavailable)
			return
		}
		_, _ = w.Write([]byte(`{"choices":[{"message":{"content":"ok"}}]}`))
	}))
	defer srv.Close()

	c := NewClient("test-key")
	c.url = srv.URL
	got, err := c.ChatCompletion(context.Background(), []Message{{Role: "user", Content: "hi"}})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != "ok" || calls.Load() != 2 {
		t.Fatalf("got %q after %d calls, want \"ok\" after 2", got, calls.Load())
	}
}

// A cancelled caller must not sit through the retry backoff.
func TestDoRequestRespectsContextDuringBackoff(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusTooManyRequests)
	}))
	defer srv.Close()

	c := NewClient("test-key")
	c.url = srv.URL
	ctx, cancel := context.WithTimeout(context.Background(), 200*time.Millisecond)
	defer cancel()

	start := time.Now()
	if _, err := c.ChatCompletion(ctx, []Message{{Role: "user", Content: "hi"}}); err == nil {
		t.Fatal("expected an error")
	}
	if elapsed := time.Since(start); elapsed > 900*time.Millisecond {
		t.Fatalf("returned after %v; should abort during the 1s backoff", elapsed)
	}
}

func TestNotConfigured(t *testing.T) {
	if _, err := NewClient("").ChatCompletion(context.Background(), nil); err != ErrNotConfigured {
		t.Fatalf("got %v, want ErrNotConfigured", err)
	}
}
