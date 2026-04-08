package middleware

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/redis/go-redis/v9"
)

type RateLimiter struct {
	rdb          *redis.Client
	freeLimit    int
	premiumLimit int
}

func NewRateLimiter(rdb *redis.Client, freeLimit, premiumLimit int) *RateLimiter {
	return &RateLimiter{
		rdb:          rdb,
		freeLimit:    freeLimit,
		premiumLimit: premiumLimit,
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
		// Check premium status from context if available
		if isPremium, ok := r.Context().Value(isPremiumKey).(bool); ok && isPremium {
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
