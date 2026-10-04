package middleware

import (
	"fmt"
	"net/http"
	"strconv"
	"strings"
	"time"
)

// RequireAdmin allows the request only when the authenticated user's
// e-mail is in [emails] (ADMIN_EMAILS, case-insensitive); everyone else
// gets 403. Must run after Verify. An empty list locks the admin API.
func (a *Auth) RequireAdmin(emails []string) func(http.Handler) http.Handler {
	allowed := make(map[string]bool, len(emails))
	for _, e := range emails {
		if e = strings.ToLower(strings.TrimSpace(e)); e != "" {
			allowed[e] = true
		}
	}
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			userID := UserIDFromContext(r.Context())
			user, err := a.userRepo.GetByID(r.Context(), userID)
			if err != nil || user == nil || !IsAdminEmail(allowed, user.Email) {
				respondError(w, http.StatusForbidden, "forbidden", "Admin access required")
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

// IsAdminEmail reports whether email is in the (lower-cased) allow-list.
func IsAdminEmail(allowed map[string]bool, email string) bool {
	e := strings.ToLower(strings.TrimSpace(email))
	return e != "" && allowed[e]
}

// LimitByUser is a fixed-window per-user limiter for one route group
// (e.g. reports), on top of the global per-user Limit. [bucket]
// namespaces the counter. Must run after Verify. Fails open on Redis
// errors like the other limiters.
func (rl *RateLimiter) LimitByUser(bucket string, perMinute int) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			userID := UserIDFromContext(r.Context())
			window := time.Now().Unix() / 60
			key := fmt.Sprintf("ratelimit:user:%s:%s:%d", bucket, userID, window)
			count, err := incrWindow(r.Context(), rl.rdb, key, 60*time.Second)
			if err != nil {
				next.ServeHTTP(w, r)
				return
			}
			if int(count) > perMinute {
				w.Header().Set("Retry-After", strconv.FormatInt((window+1)*60-time.Now().Unix(), 10))
				respondError(w, http.StatusTooManyRequests, "rate_limit_exceeded",
					"Too many requests. Please try again later.")
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}
