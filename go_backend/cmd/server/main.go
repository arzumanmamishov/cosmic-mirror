package main

import (
	"context"
	"fmt"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"cosmic-mirror/internal/config"
	"cosmic-mirror/internal/handler"
	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/provider/firebase"
	"cosmic-mirror/internal/provider/openai"
	"cosmic-mirror/internal/provider/swisseph"
	"cosmic-mirror/internal/repository/postgres"
	"cosmic-mirror/internal/server"
	"cosmic-mirror/internal/service"
	"cosmic-mirror/internal/storage"
	"cosmic-mirror/internal/worker"

	"github.com/jmoiron/sqlx"
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/redis/go-redis/v9"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		slog.Error("failed to load config", "error", err)
		os.Exit(1)
	}

	// Logger
	logLevel := slog.LevelInfo
	if cfg.IsDev() {
		logLevel = slog.LevelDebug
	}
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: logLevel}))
	slog.SetDefault(logger)

	// Database
	db, err := sqlx.Connect("pgx", cfg.DatabaseURL)
	if err != nil {
		slog.Error("failed to connect to database", "error", err)
		os.Exit(1)
	}
	defer db.Close()
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(10)
	db.SetConnMaxLifetime(5 * time.Minute)

	// Redis
	redisOpts, err := redis.ParseURL(cfg.RedisURL)
	if err != nil {
		slog.Error("failed to parse redis url", "error", err)
		os.Exit(1)
	}
	rdb := redis.NewClient(redisOpts)
	defer rdb.Close()

	ctx := context.Background()
	if err := rdb.Ping(ctx).Err(); err != nil {
		slog.Error("failed to connect to redis", "error", err)
		os.Exit(1)
	}

	// Firebase
	firebaseAuth, err := firebase.NewAuthClient(ctx, cfg.FirebaseCredentialsPath)
	if err != nil {
		slog.Error("failed to init firebase", "error", err)
		os.Exit(1)
	}

	// Providers
	openaiClient := openai.NewClient(cfg.OpenAIAPIKey)

	// Swiss Ephemeris: local, accurate astronomical calculations.
	// Replaces the previous AstrologyAPI HTTP dependency.
	chartProvider := swisseph.NewClient(cfg.EphemerisPath)
	if err := chartProvider.Init(); err != nil {
		slog.Error("failed to init Swiss Ephemeris", "error", err, "path", cfg.EphemerisPath)
		os.Exit(1)
	}
	defer chartProvider.Close()

	// Repositories
	userRepo := postgres.NewUserRepository(db)
	birthProfileRepo := postgres.NewBirthProfileRepository(db)
	readingRepo := postgres.NewReadingRepository(db)
	chatRepo := postgres.NewChatRepository(db)
	compatibilityRepo := postgres.NewCompatibilityRepository(db)
	journalRepo := postgres.NewJournalRepository(db)
	preferencesRepo := postgres.NewPreferencesRepository(db)
	ritualRepo := postgres.NewRitualRepository(db)
	subscriptionRepo := postgres.NewSubscriptionRepository(db)
	// Community / Spaces forum
	spaceRepo := postgres.NewSpaceRepository(db)
	spaceMemberRepo := postgres.NewSpaceMemberRepository(db)
	spaceCategoryRepo := postgres.NewSpaceCategoryRepository(db)
	postRepo := postgres.NewPostRepository(db)
	commentRepo := postgres.NewCommentRepository(db)
	likeRepo := postgres.NewLikeRepository(db)
	hashtagRepo := postgres.NewHashtagRepository(db)
	communityNotifRepo := postgres.NewCommunityNotificationRepository(db)

	// Services
	avatarStore := storage.NewAvatarStore(cfg.UploadsDir, "/uploads")
	statsRepo := postgres.NewStatsRepository(db)
	userSvc := service.NewUserService(userRepo, birthProfileRepo, statsRepo, avatarStore, rdb)
	chartSvc := service.NewChartService(birthProfileRepo, chartProvider, openaiClient, rdb)
	vedicSvc := service.NewVedicService(birthProfileRepo, chartProvider, rdb)
	readingSvc := service.NewReadingService(readingRepo, birthProfileRepo, openaiClient, rdb)
	aiSvc := service.NewAIService(chatRepo, birthProfileRepo, userRepo, openaiClient, cfg.FreeTierChatLimit)
	compatibilitySvc := service.NewCompatibilityService(compatibilityRepo, birthProfileRepo, openaiClient)
	subscriptionSvc := service.NewSubscriptionService(subscriptionRepo, cfg.RevenueCatWebhookSecret)
	stripeSvc := service.NewStripeService(
		subscriptionRepo,
		userSvc,
		cfg.StripeSecretKey,
		cfg.StripePublishableKey,
		cfg.StripeWebhookSecret,
		cfg.StripePriceMonthly,
		cfg.StripePriceYearly,
	)
	// Community
	communityNotifSvc := service.NewCommunityNotificationService(communityNotifRepo)
	communitySvc := service.NewCommunityService(db, spaceRepo, spaceMemberRepo, spaceCategoryRepo, postRepo, userRepo, communityNotifSvc)
	postSvc := service.NewPostService(db, postRepo, spaceRepo, spaceMemberRepo, hashtagRepo, communityNotifSvc)
	commentSvc := service.NewCommentService(db, commentRepo, postRepo, spaceMemberRepo, communityNotifSvc)
	likeSvc := service.NewLikeService(db, likeRepo, postRepo, commentRepo, spaceMemberRepo, communityNotifSvc)
	// Numerology + Human Design
	numerologySvc := service.NewNumerologyService(userRepo, birthProfileRepo)
	humanDesignSvc := service.NewHumanDesignService(birthProfileRepo, chartProvider, rdb)
	psychomatrixSvc := service.NewPsychomatrixService(birthProfileRepo)

	// Middleware
	authMiddleware := middleware.NewAuth(firebaseAuth, userRepo)
	rateLimiter := middleware.NewRateLimiter(rdb, cfg.FreeTierRateLimit, cfg.PremiumRateLimit, subscriptionSvc.IsPremium)

	// Handlers
	handlers := &handler.Handlers{
		Auth:          handler.NewAuthHandler(userSvc, subscriptionSvc),
		User:          handler.NewUserHandler(userSvc, preferencesRepo, ritualRepo),
		Chart:         handler.NewChartHandler(chartSvc),
		Vedic:         handler.NewVedicHandler(vedicSvc),
		DailyReading:  handler.NewDailyReadingHandler(readingSvc),
		AIChat:        handler.NewAIChatHandler(aiSvc, subscriptionSvc),
		Compatibility: handler.NewCompatibilityHandler(compatibilitySvc),
		Subscription:  handler.NewSubscriptionHandler(subscriptionSvc),
		Stripe:        handler.NewStripeHandler(stripeSvc),
		Journal:       handler.NewJournalHandler(journalRepo),
		Places:        handler.NewPlacesHandler(),
		// Community / Spaces forum
		Spaces:                 handler.NewSpacesHandler(communitySvc),
		Posts:                  handler.NewPostsHandler(postSvc, likeSvc),
		Comments:               handler.NewCommentsHandler(commentSvc, likeSvc),
		CommunityNotifications: handler.NewCommunityNotificationsHandler(communityNotifSvc),
		Discovery:              handler.NewDiscoveryHandler(communitySvc, hashtagRepo),
		// Numerology + Human Design
		Numerology:   handler.NewNumerologyHandler(numerologySvc),
		HumanDesign:  handler.NewHumanDesignHandler(humanDesignSvc),
		Psychomatrix: handler.NewPsychomatrixHandler(psychomatrixSvc),
	}

	// Background workers — scheduled on simple interval tickers, tied to a
	// context cancelled on shutdown. Daily readings are also generated
	// lazily on request, so these are best-effort pre-generation/dispatch.
	workerCtx, stopWorkers := context.WithCancel(context.Background())
	defer stopWorkers()
	dailyReadingsWorker := worker.NewDailyReadingsWorker(db, readingSvc)
	notificationsWorker := worker.NewNotificationsWorker(db)
	cleanupWorker := worker.NewCleanupWorker(db, rdb)
	scheduleWorker(workerCtx, "daily_readings", 24*time.Hour, dailyReadingsWorker.Run)
	scheduleWorker(workerCtx, "notifications", 15*time.Minute, notificationsWorker.Run)
	scheduleWorker(workerCtx, "cleanup", 24*time.Hour, cleanupWorker.Run)

	// Router
	router := server.NewRouter(handlers, authMiddleware, rateLimiter, cfg)

	// Server
	srv := &http.Server{
		Addr:         fmt.Sprintf(":%s", cfg.Port),
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Graceful shutdown
	go func() {
		slog.Info("server starting", "port", cfg.Port, "env", cfg.Environment)
		if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			slog.Error("server failed", "error", err)
			os.Exit(1)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	slog.Info("shutting down server...")
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		slog.Error("server forced to shutdown", "error", err)
	}
	slog.Info("server stopped")
}

// scheduleWorker runs fn on an interval ticker in its own goroutine until ctx
// is cancelled. Errors are logged, not fatal — a failed run shouldn't stop
// future runs or the server.
func scheduleWorker(ctx context.Context, name string, interval time.Duration, fn func(context.Context) error) {
	go func() {
		ticker := time.NewTicker(interval)
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				if err := fn(ctx); err != nil {
					slog.Error("worker run failed", "worker", name, "error", err)
				}
			}
		}
	}()
}
