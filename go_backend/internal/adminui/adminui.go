// Package adminui serves the web admin panel: a dependency-free static
// single-page app (HTML, CSS and ES modules) embedded in the server
// binary, so it ships and deploys with the API. The page talks to
// /api/v1/auth/* to sign in and /api/v1/admin/* for data, on the same
// origin.
package adminui

import (
	"embed"
	"io/fs"
	"net/http"
	"strings"
)

//go:embed static
var files embed.FS

// contentSecurityPolicy only lets the panel load its own files and call
// its own origin: no inline script or style, no third-party anything.
const contentSecurityPolicy = "default-src 'none'; " +
	"script-src 'self'; style-src 'self'; img-src 'self' data:; " +
	"connect-src 'self'; font-src 'self'; manifest-src 'self'; " +
	"base-uri 'none'; form-action 'none'; frame-ancestors 'none'"

// Handler serves the panel's files for request paths under [prefix]
// (e.g. "/admin/"). The panel routes in the URL fragment (#/customers),
// so the server only ever serves real files; anything else is a 404.
func Handler(prefix string) http.Handler {
	static, err := fs.Sub(files, "static")
	if err != nil {
		panic(err) // the embed pattern guarantees the directory exists
	}
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		name := strings.TrimPrefix(r.URL.Path, prefix)
		if name == "" {
			name = "index.html"
		}
		if !fs.ValidPath(name) {
			http.NotFound(w, r)
			return
		}
		info, err := fs.Stat(static, name)
		if err != nil || info.IsDir() {
			http.NotFound(w, r)
			return
		}
		h := w.Header()
		h.Set("Content-Security-Policy", contentSecurityPolicy)
		// Small files and no build step to fingerprint them: revalidate
		// every time so a deploy is picked up on the next load.
		h.Set("Cache-Control", "no-cache")
		h.Set("X-Robots-Tag", "noindex, nofollow")
		http.ServeFileFS(w, r, static, name)
	})
}
