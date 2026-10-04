package middleware

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log/slog"
	"net"
	"net/http"
	"net/netip"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/redis/go-redis/v9"
)

// RealIP replaces r.RemoteAddr with the client's address, but only
// believes X-Forwarded-For / X-Real-IP when the TCP peer is one of the
// [trusted] proxy CIDRs. Otherwise anyone could spoof their IP (and dodge
// per-IP rate limits) just by sending the header. From XFF it takes the
// right-most hop that isn't itself a trusted proxy.
func RealIP(trusted []string) func(http.Handler) http.Handler {
	var prefixes []netip.Prefix
	for _, c := range trusted {
		p, err := netip.ParsePrefix(c)
		if err != nil {
			if a, err2 := netip.ParseAddr(c); err2 == nil {
				p = netip.PrefixFrom(a, a.BitLen())
			} else {
				slog.Warn("ignoring invalid TRUSTED_PROXIES entry", "value", c)
				continue
			}
		}
		prefixes = append(prefixes, p)
	}
	isTrusted := func(ip string) bool {
		a, err := netip.ParseAddr(strings.TrimSpace(ip))
		if err != nil {
			return false
		}
		a = a.Unmap()
		for _, p := range prefixes {
			if p.Contains(a) {
				return true
			}
		}
		return false
	}

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			peer := hostOnly(r.RemoteAddr)
			client := peer
			if len(prefixes) > 0 && isTrusted(peer) {
				if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
					hops := strings.Split(xff, ",")
					for i := len(hops) - 1; i >= 0; i-- {
						h := strings.TrimSpace(hops[i])
						if _, err := netip.ParseAddr(h); err != nil {
							break
						}
						client = h
						if !isTrusted(h) {
							break
						}
					}
				} else if xr := strings.TrimSpace(r.Header.Get("X-Real-IP")); xr != "" {
					if _, err := netip.ParseAddr(xr); err == nil {
						client = xr
					}
				}
			}
			r.RemoteAddr = client
			next.ServeHTTP(w, r)
		})
	}
}

// ClientIP returns the client address resolved by RealIP.
func ClientIP(r *http.Request) string { return hostOnly(r.RemoteAddr) }

func hostOnly(addr string) string {
	if h, _, err := net.SplitHostPort(addr); err == nil {
		return h
	}
	return addr
}

// SecurityHeaders sets conservative response headers. The API only
// serves JSON and uploaded images, so nothing needs framing or scripts.
func SecurityHeaders(hsts bool) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			h := w.Header()
			h.Set("X-Content-Type-Options", "nosniff")
			h.Set("X-Frame-Options", "DENY")
			h.Set("Referrer-Policy", "no-referrer")
			h.Set("Content-Security-Policy", "default-src 'none'; img-src 'self'; frame-ancestors 'none'")
			h.Set("Cross-Origin-Resource-Policy", "same-site")
			if hsts {
				h.Set("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
			}
			next.ServeHTTP(w, r)
		})
	}
}

// MaxBody caps request bodies at [n] bytes so a client can't exhaust
// memory with a huge JSON payload. [uploads] maps the exact path of each
// upload route to its own, larger cap; only those routes get it — a
// multipart Content-Type on any other route is still capped at [n].
// Upload handlers may apply a tighter MaxBytesReader of their own.
func MaxBody(n int64, uploads map[string]int64) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			limit := n
			if c, ok := uploads[r.URL.Path]; ok && r.Method == http.MethodPost {
				limit = c
			}
			r.Body = http.MaxBytesReader(w, r.Body, limit)
			next.ServeHTTP(w, r)
		})
	}
}

// incrWindow bumps a counter and makes sure it carries a TTL, in one round
// trip. EXPIRE ... NX only sets the TTL when the key has none, so a lost
// EXPIRE (or a crash between the two commands) can't leave an immortal
// counter behind. Requires Redis >= 7.0.
func incrWindow(ctx context.Context, rdb *redis.Client, key string, ttl time.Duration) (int64, error) {
	pipe := rdb.Pipeline()
	incr := pipe.Incr(ctx, key)
	pipe.ExpireNX(ctx, key, ttl)
	if _, err := pipe.Exec(ctx); err != nil {
		return 0, err
	}
	return incr.Val(), nil
}

// LimitByIP is a fixed-window per-IP limiter for unauthenticated routes
// (login, OTP, register, places). [bucket] namespaces the counter so each
// route group gets its own budget.
func (rl *RateLimiter) LimitByIP(bucket string, perMinute int) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			window := time.Now().Unix() / 60
			key := fmt.Sprintf("ratelimit:ip:%s:%s:%d", bucket, ClientIP(r), window)
			ctx := r.Context()
			count, err := incrWindow(ctx, rl.rdb, key, 60*time.Second)
			if err != nil {
				// Redis down: fail open rather than lock everyone out.
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

// NoDirFS wraps a FileSystem so directories 404 instead of being listed
// (a listing of /uploads/avatars/ would enumerate every user id).
type NoDirFS struct{ FS http.FileSystem }

func (n NoDirFS) Open(name string) (http.File, error) {
	f, err := n.FS.Open(name)
	if err != nil {
		return nil, err
	}
	st, err := f.Stat()
	if err != nil {
		f.Close()
		return nil, err
	}
	if st.IsDir() {
		f.Close()
		return nil, os.ErrNotExist
	}
	return f, nil
}

// RequirePremium rejects non-premium users with 403. Premium screens are
// also gated in the app, but the paywall has to hold server-side too —
// otherwise the endpoints can simply be called directly.
func (rl *RateLimiter) RequirePremium(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userID := UserIDFromContext(r.Context())
		if rl.isPremium == nil || !rl.isPremium(r.Context(), userID) {
			respondError(w, http.StatusForbidden, "premium_required",
				"This feature requires a premium subscription.")
			return
		}
		next.ServeHTTP(w, r)
	})
}

// LoginLockout stops password guessing against a single account from many
// IPs (which per-IP limits alone can't): after [maxFailures] failed logins
// for an email within [window], that email is locked for the rest of the
// window. A successful login clears the counter.
func (rl *RateLimiter) LoginLockout(maxFailures int, window time.Duration) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			body, err := io.ReadAll(r.Body)
			if err != nil {
				respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
				return
			}
			r.Body = io.NopCloser(bytes.NewReader(body))
			var in struct {
				Email string `json:"email"`
			}
			_ = json.Unmarshal(body, &in)
			email := strings.ToLower(strings.TrimSpace(in.Email))
			if email == "" {
				next.ServeHTTP(w, r)
				return
			}
			key := "loginfail:" + email
			ctx := r.Context()
			if n, err := rl.rdb.Get(ctx, key).Int(); err == nil && n >= maxFailures {
				respondError(w, http.StatusTooManyRequests, "account_locked",
					"Too many failed attempts. Try again later or sign in with a code.")
				return
			}
			rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
			next.ServeHTTP(rec, r)
			switch {
			case rec.status == http.StatusUnauthorized:
				_, _ = incrWindow(ctx, rl.rdb, key, window)
			case rec.status < 300:
				rl.rdb.Del(ctx, key)
			}
		})
	}
}

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (s *statusRecorder) WriteHeader(code int) {
	s.status = code
	s.ResponseWriter.WriteHeader(code)
}
