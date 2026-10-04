package middleware

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestMaxBodyOnlyExemptsUploadRoute(t *testing.T) {
	h := MaxBody(10, map[string]int64{"/upload": 100})(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if _, err := io.ReadAll(r.Body); err != nil {
			w.WriteHeader(http.StatusRequestEntityTooLarge)
		}
	}))
	cases := []struct {
		method, path string
		size         int
		want         int
	}{
		{http.MethodPost, "/other", 50, http.StatusRequestEntityTooLarge}, // multipart elsewhere is capped
		{http.MethodPost, "/upload", 50, http.StatusOK},
		{http.MethodPost, "/upload", 150, http.StatusRequestEntityTooLarge},
		{http.MethodPut, "/upload", 50, http.StatusRequestEntityTooLarge}, // only POST gets the upload cap
	}
	for _, tc := range cases {
		req := httptest.NewRequest(tc.method, tc.path, strings.NewReader(strings.Repeat("x", tc.size)))
		req.Header.Set("Content-Type", "multipart/form-data; boundary=x")
		rec := httptest.NewRecorder()
		h.ServeHTTP(rec, req)
		if rec.Code != tc.want {
			t.Errorf("%s %s (%d bytes): got %d, want %d", tc.method, tc.path, tc.size, rec.Code, tc.want)
		}
	}
}
