package adminui

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func get(t *testing.T, path string) *httptest.ResponseRecorder {
	t.Helper()
	rec := httptest.NewRecorder()
	Handler("/admin/").ServeHTTP(rec, httptest.NewRequest(http.MethodGet, path, nil))
	return rec
}

func TestServesIndexWithCSP(t *testing.T) {
	rec := get(t, "/admin/")
	if rec.Code != http.StatusOK {
		t.Fatalf("GET /admin/ = %d", rec.Code)
	}
	if ct := rec.Header().Get("Content-Type"); !strings.HasPrefix(ct, "text/html") {
		t.Errorf("Content-Type = %q", ct)
	}
	csp := rec.Header().Get("Content-Security-Policy")
	for _, want := range []string{"script-src 'self'", "connect-src 'self'", "frame-ancestors 'none'"} {
		if !strings.Contains(csp, want) {
			t.Errorf("CSP %q missing %q", csp, want)
		}
	}
	if strings.Contains(csp, "unsafe-inline") || strings.Contains(csp, "unsafe-eval") {
		t.Errorf("CSP must not allow inline/eval: %q", csp)
	}
	if !strings.Contains(rec.Body.String(), `src="js/app.js"`) {
		t.Error("index.html doesn't load the app module")
	}
}

func TestServesAssetsWithTypes(t *testing.T) {
	for path, wantType := range map[string]string{
		"/admin/js/app.js":            "javascript",
		"/admin/js/pages/settings.js": "javascript",
		"/admin/admin.css":            "text/css",
		"/admin/favicon.svg":          "image/svg+xml",
	} {
		rec := get(t, path)
		if rec.Code != http.StatusOK {
			t.Errorf("GET %s = %d", path, rec.Code)
			continue
		}
		if ct := rec.Header().Get("Content-Type"); !strings.Contains(ct, wantType) {
			t.Errorf("GET %s Content-Type = %q, want %s", path, ct, wantType)
		}
	}
}

func TestNotFound(t *testing.T) {
	for _, path := range []string{
		"/admin/js/",          // no directory listings
		"/admin/missing.js",   // unknown file
		"/admin/../go.mod",    // traversal
		"/admin/js/../../x",   // traversal
		"/admin/customers/42", // panel routes live in the #fragment, not the path
	} {
		if rec := get(t, path); rec.Code == http.StatusOK {
			t.Errorf("GET %s = 200, want an error", path)
		}
	}
}
