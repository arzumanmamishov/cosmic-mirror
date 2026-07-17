package middleware

import (
	"context"
	"net/http"
	"strings"
)

type langCtxKey struct{}

// Language reads Accept-Language, collapses it to a supported code, and
// stashes it in ctx. Handlers read it back via LangFromContext to hand
// off to prompt builders and the chart-summary layer.
//
// Supported today: "en", "tr". Unknown / missing → "en".
func Language(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		lang := pickLang(r.Header.Get("Accept-Language"))
		ctx := context.WithValue(r.Context(), langCtxKey{}, lang)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// LangFromContext returns the caller's language code, defaulting to "en"
// if the middleware did not run or the header was absent.
func LangFromContext(ctx context.Context) string {
	if v, ok := ctx.Value(langCtxKey{}).(string); ok && v != "" {
		return v
	}
	return "en"
}

// pickLang parses the header just far enough to pick the highest-priority
// tag we support. We deliberately ignore q-values — for two supported
// languages the first-match rule is fine and much cheaper.
func pickLang(header string) string {
	if header == "" {
		return "en"
	}
	for _, part := range strings.Split(header, ",") {
		tag := strings.TrimSpace(part)
		if i := strings.Index(tag, ";"); i >= 0 {
			tag = strings.TrimSpace(tag[:i])
		}
		if tag == "" {
			continue
		}
		primary := strings.ToLower(strings.Split(tag, "-")[0])
		switch primary {
		case "tr", "en":
			return primary
		}
	}
	return "en"
}
