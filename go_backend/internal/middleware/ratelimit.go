package middleware

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/redis/go-redis/v9"
)

// PremiumChecker reports whether a user currently has premium access.
// Injected so the limiter can pick the right tier without depending on
// an upstream middleware to stash the flag in the request context.
type PremiumChecker func(ctx context.Context, userID uuid.UUID) bool

type RateLimiter struct {
	rdb          *redis.Client
	freeLimit    int
	premiumLimit int
	isPremium    PremiumChecker
}

func NewRateLimiter(rdb *redis.Client, freeLimit, premiumLimit int, isPremium PremiumChecker) *RateLimiter {
	return &RateLimiter{
		rdb:          rdb,
		freeLimit:    freeLimit,
		premiumLimit: premiumLimit,
		isPremium:    isPremium,
	}
}

func (rl *RateLimiter) Limit(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userID := UserIDFromContext(r.Context())
		if userID.String() == "00000000-0000-0000-0000-000000000000" {
			next.ServeHTTP(w, r)
			return
		}

		limit := rl.freeLimit
		if rl.isPremium != nil && rl.isPremium(r.Context(), userID) {
			limit = rl.premiumLimit
		}

		key := fmt.Sprintf("ratelimit:%s:%d", userID.String(), time.Now().Unix()/60)
		ctx := r.Context()

		count, err := rl.rdb.Incr(ctx, key).Result()
		if err != nil {
			// On Redis failure, allow the request through
			next.ServeHTTP(w, r)
			return
		}

		if count == 1 {
			rl.rdb.Expire(ctx, key, 60*time.Second)
		}

		remaining := limit - int(count)
		if remaining < 0 {
			remaining = 0
		}

		w.Header().Set("X-RateLimit-Limit", strconv.Itoa(limit))
		w.Header().Set("X-RateLimit-Remaining", strconv.Itoa(remaining))
		w.Header().Set("X-RateLimit-Reset", strconv.FormatInt(
			(time.Now().Unix()/60+1)*60, 10,
		))

		if int(count) > limit {
			respondError(w, http.StatusTooManyRequests, "rate_limit_exceeded",
				"Too many requests. Please try again later.")
			return
		}

		next.ServeHTTP(w, r)
	})
}
