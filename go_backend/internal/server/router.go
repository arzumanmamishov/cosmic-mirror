package server

import (
	"encoding/json"
	"net/http"

	"cosmic-mirror/internal/config"
	"cosmic-mirror/internal/handler"
	"cosmic-mirror/internal/middleware"

	"github.com/go-chi/chi/v5"
	chimw "github.com/go-chi/chi/v5/middleware"
	"github.com/go-chi/cors"
)

func NewRouter(h *handler.Handlers, auth *middleware.Auth, rl *middleware.RateLimiter, cfg *config.Config) http.Handler {
	r := chi.NewRouter()

	// Global middleware
	r.Use(chimw.RequestID)
	r.Use(chimw.RealIP)
	r.Use(middleware.Logger)
	r.Use(chimw.Recoverer)
	r.Use(cors.Handler(cors.Options{
		AllowedOrigins:   cfg.CORSOrigins,
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"Accept", "Authorization", "Content-Type"},
		ExposedHeaders:   []string{"X-RateLimit-Limit", "X-RateLimit-Remaining", "X-RateLimit-Reset"},
		AllowCredentials: true,
		MaxAge:           300,
	}))

	// Health check
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"status": "ok"})
	})

	// API v1
	r.Route("/api/v1", func(r chi.Router) {
		// Public: auth
		r.Post("/auth/session", h.Auth.CreateSession)

		// Public: subscription webhook
		r.Post("/subscription/webhook", h.Subscription.HandleWebhook)

		// Public: legal
		r.Get("/legal/privacy", h.Auth.PrivacyPolicy)
		r.Get("/legal/terms", h.Auth.TermsOfService)

		// Protected routes
		r.Group(func(r chi.Router) {
			r.Use(auth.Verify)
			r.Use(rl.Limit)

			// Users
			r.Get("/users/me", h.User.GetMe)
			r.Put("/users/me", h.User.UpdateMe)
			r.Delete("/users/me", h.User.DeleteMe)
			r.Post("/users/me/birth-profile", h.User.CreateBirthProfile)
			r.Put("/users/me/birth-profile", h.User.UpdateBirthProfile)
			r.Get("/users/me/preferences", h.User.GetPreferences)
			r.Put("/users/me/preferences", h.User.UpdatePreferences)

			// Chart
			r.Get("/chart", h.Chart.GetChart)
			r.Get("/chart/summary", h.Chart.GetSummary)

			// Daily Reading
			r.Get("/daily-reading", h.DailyReading.GetToday)
			r.Get("/daily-reading/{date}", h.DailyReading.GetByDate)

			// AI Chat
			r.Get("/ai/threads", h.AIChat.ListThreads)
			r.Post("/ai/threads", h.AIChat.CreateThread)
			r.Get("/ai/threads/{threadID}/messages", h.AIChat.GetMessages)
			r.Post("/ai/threads/{threadID}/messages", h.AIChat.SendMessage)

			// People & Compatibility
			r.Get("/people", h.Compatibility.ListPeople)
			r.Post("/people", h.Compatibility.AddPerson)
			r.Delete("/people/{personID}", h.Compatibility.DeletePerson)
			r.Get("/people/{personID}/compatibility", h.Compatibility.GetReport)
			r.Post("/people/{personID}/compatibility", h.Compatibility.GenerateReport)

			// Timeline & Forecast
			r.Get("/timeline", h.Chart.GetTimeline)
			r.Get("/forecast/yearly", h.Chart.GetYearlyForecast)

			// Rituals
			r.Get("/rituals/today", h.User.GetRitualsToday)
			r.Post("/rituals/{type}/complete", h.User.CompleteRitual)

			// Journal
			r.Get("/journal", h.Journal.List)
			r.Post("/journal", h.Journal.Create)
			r.Put("/journal/{entryID}", h.Journal.Update)

			// Notifications
			r.Get("/notifications/preferences", h.User.GetNotificationPrefs)
			r.Put("/notifications/preferences", h.User.UpdateNotificationPrefs)

			// Subscription
			r.Get("/subscription/status", h.Subscription.GetStatus)
		})
	})

	return r
}
