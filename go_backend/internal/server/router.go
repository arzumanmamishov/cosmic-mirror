package server

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"time"

	"cosmic-mirror/internal/config"
	"cosmic-mirror/internal/handler"
	"cosmic-mirror/internal/middleware"

	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
)

// ReadyCheck reports whether the API's dependencies (DB, Redis) are up.
type ReadyCheck func(ctx context.Context) error

func NewRouter(h *handler.Handlers, auth *middleware.Auth, rl *middleware.RateLimiter, cfg *config.Config, ready ReadyCheck) http.Handler {
	r := chi.NewRouter()

	// Premium-only routes. Dev builds of the app unlock everything for
	// testing, so dev servers skip the check to match; every other
	// environment enforces it.
	premium := rl.RequirePremium
	if cfg.IsDev() {
		premium = func(next http.Handler) http.Handler { return next }
	}

	// Global middleware
	r.Use(chimw.RequestID)
	// Only trusts X-Forwarded-For from TRUSTED_PROXIES (see RealIP).
	r.Use(middleware.RealIP(cfg.TrustedProxies))
	r.Use(middleware.Logger)
	r.Use(chimw.Recoverer)
	r.Use(middleware.SecurityHeaders(cfg.IsProd()))
	// 1 MB for every JSON route; only the avatar upload gets a larger cap.
	r.Use(middleware.MaxBody(1<<20, map[string]int64{
		"/api/v1/users/me/avatar": handler.AvatarMaxBytes,
	}))
	r.Use(middleware.Language)
	// Auth is a Bearer header, never a cookie, so CORS needs no
	// credentials. Origins come from CORS_ORIGINS.
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   cfg.CORSOrigins,
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Accept-Language", "Authorization", "Content-Type"},
		ExposedHeaders:   []string{"X-RateLimit-Limit", "X-RateLimit-Remaining", "X-RateLimit-Reset"},
		AllowCredentials: false,
		MaxAge:           300,
	}))

	// Health check
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
	})

	// Readiness: 503 until Postgres and Redis both answer. /health stays a
	// pure liveness probe so a DB blip doesn't get the container killed.
	r.Get("/ready", func(w http.ResponseWriter, r *http.Request) {
		ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
		defer cancel()
		w.Header().Set("Content-Type", "application/json")
		if ready != nil {
			if err := ready(ctx); err != nil {
				slog.Warn("readiness check failed", "error", err)
				w.WriteHeader(http.StatusServiceUnavailable)
				json.NewEncoder(w).Encode(map[string]string{"status": "unavailable"})
				return
			}
		}
		json.NewEncoder(w).Encode(map[string]string{"status": "ready"})
	})

	// Public static-file serve for user-uploaded assets (avatars, etc.).
	// Files live under cfg.UploadsDir; the URL prefix is /uploads.
	uploadsServer := http.StripPrefix(
		"/uploads/",
		http.FileServer(middleware.NoDirFS{FS: http.Dir(cfg.UploadsDir)}),
	)
	r.Get("/uploads/*", uploadsServer.ServeHTTP)

	// API v1
	r.Route("/api/v1", func(r chi.Router) {
		// Public: auth. The old Firebase /auth/session is kept as a 410
		// stub — new clients hit /auth/register or /auth/login instead.
		// Every public auth route is rate-limited per client IP — these
		// are the password / OTP brute-force and mail-bombing targets.
		// The per-IP budget is deliberately loose (30/min): mobile
		// carriers put thousands of users behind one carrier-grade-NAT
		// address, and a tight per-IP cap locks them all out at launch.
		// The real brute-force defences are per account/email and can't
		// be dodged by rotating IPs: LoginLockout below (10 bad passwords
		// / 15 min), and in OTPService 5 guesses per code, 3 codes / 10
		// min and 10 / day per email, and an OTP lock after 10 failed
		// verifications per email in 24h.
		r.Group(func(r chi.Router) {
			r.Use(rl.LimitByIP("auth", 30))
			r.Post("/auth/session", h.Auth.CreateSession)
			r.Post("/auth/otp/request", h.Auth.RequestOTP)
			r.Post("/auth/register", h.Auth.Register)
			r.With(rl.LoginLockout(10, 15*time.Minute)).Post("/auth/login", h.Auth.Login)
			r.Post("/auth/login/otp", h.Auth.LoginOTP)
			r.Post("/auth/password/reset", h.Auth.PasswordReset)
		})
		r.Group(func(r chi.Router) {
			r.Use(rl.LimitByIP("refresh", 30))
			r.Post("/auth/refresh", h.Auth.Refresh)
			r.Post("/auth/logout", h.Auth.Logout)
		})

		// Public: subscription webhooks — RevenueCat (App Store / Google
		// Play purchases from the mobile app) + Stripe (web checkout).
		// Both must stay outside the auth-protected group because the
		// webhook senders authenticate via signature, not a user token.
		r.Post("/subscription/webhook", h.Subscription.HandleWebhook)
		r.Post("/stripe/webhook", h.Stripe.HandleWebhook)

		// Public: legal
		r.Get("/legal/privacy", h.Auth.PrivacyPolicy)
		r.Get("/legal/terms", h.Auth.TermsOfService)

		// Public: places search (geocoding). Public because the app calls
		// it without a bearer token (see flutter_app api_client.dart
		// _isAuthEndpoint). Per-IP limited here; the handler adds a Redis
		// result cache and a global 1 req/s throttle toward Nominatim.
		r.With(rl.LimitByIP("places", 30)).Get("/places/search", h.Places.Search)

		// Protected routes
		r.Group(func(r chi.Router) {
			r.Use(auth.Verify)
			r.Use(rl.Limit)

			// Users
			r.Get("/users/me", h.User.GetMe)
			r.Put("/users/me", h.User.UpdateMe)
			r.Delete("/users/me", h.User.DeleteMe)
			r.Post("/users/me/avatar", h.User.UploadAvatar)
			r.Delete("/users/me/avatar", h.User.DeleteAvatar)
			r.Get("/users/me/stats", h.User.GetStats)
			r.Get("/users/me/birth-profile", h.User.GetBirthProfile)
			r.Post("/users/me/birth-profile", h.User.CreateBirthProfile)
			r.Put("/users/me/birth-profile", h.User.UpdateBirthProfile)
			r.Get("/users/me/preferences", h.User.GetPreferences)
			r.Put("/users/me/preferences", h.User.UpdatePreferences)

			// Chart (Western tropical)
			r.Get("/chart", h.Chart.GetChart)
			r.Get("/chart/summary", h.Chart.GetSummary)

			// Vedic / Jyotish (sidereal)
			r.Get("/vedic/chart", h.Vedic.GetChart)
			r.Get("/vedic/chart/divisional/{divisor}", h.Vedic.GetDivisionalChart)
			r.Get("/vedic/dasha", h.Vedic.GetDasha)
			r.Get("/vedic/yogas", h.Vedic.GetYogas)
			r.Get("/vedic/shadbala", h.Vedic.GetShadbala)
			r.Get("/vedic/ashtakavarga", h.Vedic.GetAshtakavarga)

			// Daily Reading
			r.Get("/daily-reading", h.DailyReading.GetToday)
			r.Get("/daily-reading/{date}", h.DailyReading.GetByDate)

			// AI Chat
			r.Get("/ai/threads", h.AIChat.ListThreads)
			r.Post("/ai/threads", h.AIChat.CreateThread)
			r.Delete("/ai/threads/{threadID}", h.AIChat.DeleteThread)
			r.Get("/ai/threads/{threadID}/messages", h.AIChat.GetMessages)
			r.Post("/ai/threads/{threadID}/messages", h.AIChat.SendMessage)
			r.Get("/ai/usage", h.AIChat.GetUsage)

			// People & Compatibility
			r.Get("/people", h.Compatibility.ListPeople)
			r.Post("/people", h.Compatibility.AddPerson)
			r.Delete("/people/{personID}", h.Compatibility.DeletePerson)
			r.Get("/people/{personID}/compatibility", h.Compatibility.GetReport)
			r.Post("/people/{personID}/compatibility", h.Compatibility.GenerateReport)

			// Timeline & Forecast
			// Premium-only (enforced here, not just in the app).
			r.With(premium).Get("/timeline", h.Chart.GetTimeline)
			r.With(premium).Get("/forecast/yearly", h.Chart.GetYearlyForecast)

			// Rituals
			r.With(premium).Get("/rituals/today", h.User.GetRitualsToday)
			r.With(premium).Post("/rituals/{type}/complete", h.User.CompleteRitual)

			// Journal
			r.Get("/journal", h.Journal.List)
			r.Post("/journal", h.Journal.Create)
			r.Put("/journal/{entryID}", h.Journal.Update)

			// Notifications
			r.Get("/notifications/preferences", h.User.GetNotificationPrefs)
			r.Put("/notifications/preferences", h.User.UpdateNotificationPrefs)

			// Subscription
			r.Get("/subscription/status", h.Subscription.GetStatus)

			// Stripe — web checkout only (the mobile apps must sell through
			// App Store / Google Play). POST creates a Customer + incomplete
			// Sub, returning the params the client needs to complete payment.
			r.Post("/stripe/payment-sheet", h.Stripe.PaymentSheet)
			r.Post("/stripe/cancel", h.Stripe.Cancel)

			// Community: spaces
			r.Get("/spaces", h.Spaces.List)
			r.Post("/spaces", h.Spaces.Create)
			r.Get("/spaces/{spaceID}", h.Spaces.Get)
			r.Put("/spaces/{spaceID}", h.Spaces.Update)
			r.Delete("/spaces/{spaceID}", h.Spaces.Delete)
			r.Post("/spaces/{spaceID}/join", h.Spaces.Join)
			r.Delete("/spaces/{spaceID}/join", h.Spaces.Leave)
			r.Get("/spaces/{spaceID}/members", h.Spaces.Members)

			// Community: join-request inbox for space owners. Approve
			// flips the pending row to approved + bumps member_count;
			// decline drops it (the user can re-request later).
			r.Get("/spaces/{spaceID}/join-requests", h.Spaces.ListJoinRequests)
			r.Post("/spaces/{spaceID}/join-requests/{userID}/approve", h.Spaces.ApproveJoinRequest)
			r.Post("/spaces/{spaceID}/join-requests/{userID}/decline", h.Spaces.DeclineJoinRequest)

			// Community: posts (nested under space for create/list, flat for the rest)
			r.Get("/spaces/{spaceID}/posts", h.Posts.ListBySpace)
			r.Post("/spaces/{spaceID}/posts", h.Posts.Create)
			r.Get("/posts/{postID}", h.Posts.Get)
			r.Put("/posts/{postID}", h.Posts.Update)
			r.Delete("/posts/{postID}", h.Posts.Delete)
			r.Post("/posts/{postID}/like", h.Posts.Like)
			r.Delete("/posts/{postID}/like", h.Posts.Unlike)

			// Community: comments
			r.Get("/posts/{postID}/comments", h.Comments.ListByPost)
			r.Post("/posts/{postID}/comments", h.Comments.Create)
			r.Put("/comments/{commentID}", h.Comments.Update)
			r.Delete("/comments/{commentID}", h.Comments.Delete)
			r.Post("/comments/{commentID}/like", h.Comments.Like)
			r.Delete("/comments/{commentID}/like", h.Comments.Unlike)

			// Community: notifications (in-app activity feed)
			r.Get("/community/notifications", h.CommunityNotifications.List)
			r.Get("/community/notifications/unread-count", h.CommunityNotifications.UnreadCount)
			r.Post("/community/notifications/{notificationID}/read", h.CommunityNotifications.MarkRead)
			r.Post("/community/notifications/read-all", h.CommunityNotifications.MarkAllRead)

			// Community: user profile (joined spaces + recent posts).
			// Path param accepts a UUID or the literal "me".
			r.Get("/community/users/{userID}", h.Spaces.GetUserProfile)

			// Community: discovery (categories + popular hashtags)
			r.Get("/space-categories", h.Discovery.ListCategories)
			r.Get("/hashtags/popular", h.Discovery.ListPopularHashtags)

			// Community safety (App Store 1.2 / Play UGC): reports and
			// blocks. Reports get their own per-user budget on top of
			// the global limiter so one account can't flood the
			// moderation inbox.
			r.With(rl.LimitByUser("reports", 10)).Post("/reports", h.Moderation.CreateReport)
			r.Get("/users/me/blocks", h.Moderation.ListBlocks)
			r.Post("/users/{userID}/block", h.Moderation.Block)
			r.Delete("/users/{userID}/block", h.Moderation.Unblock)

			// Admin moderation queue — allow-listed by ADMIN_EMAILS
			// (403 for everyone else, and for everyone when unset).
			r.Group(func(r chi.Router) {
				r.Use(auth.RequireAdmin(cfg.AdminEmails))
				r.Get("/admin/reports", h.Moderation.AdminListReports)
				r.Post("/admin/reports/{reportID}/resolve", h.Moderation.AdminResolveReport)
			})

			// Numerology
			r.Get("/numerology", h.Numerology.GetReading)
			r.Post("/numerology/compatibility", h.Numerology.Compare)
			r.Post("/numerology/name", h.Numerology.AnalyzeName)

			// Pythagoras Square (Psychomatrix)
			r.Get("/psychomatrix", h.Psychomatrix.GetReading)

			// Matrix of Destiny (22-arcana octagram)
			r.Get("/destiny-matrix", h.DestinyMatrix.GetReading)

			// Human Design
			r.Get("/human-design", h.HumanDesign.GetChart)
		})
	})

	return r
}
