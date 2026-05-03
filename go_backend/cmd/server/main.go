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
	userSvc := service.NewUserService(userRepo, birthProfileRepo)
	chartSvc := service.NewChartService(birthProfileRepo, chartProvider, rdb)
	vedicSvc := service.NewVedicService(birthProfileRepo, chartProvider, rdb)
	readingSvc := service.NewReadingService(readingRepo, birthProfileRepo, openaiClient, rdb)
	aiSvc := service.NewAIService(chatRepo, birthProfileRepo, openaiClient, cfg.FreeTierChatLimit)
	compatibilitySvc := service.NewCompatibilityService(compatibilityRepo, birthProfileRepo, openaiClient)
	subscriptionSvc := service.NewSubscriptionService(subscriptionRepo, cfg.RevenueCatWebhookSecret)
	// Community
	communityNotifSvc := service.NewCommunityNotificationService(communityNotifRepo)
	communitySvc := service.NewCommunityService(db, spaceRepo, spaceMemberRepo, spaceCategoryRepo, communityNotifSvc)
	postSvc := service.NewPostService(db, postRepo, spaceRepo, spaceMemberRepo, hashtagRepo, communityNotifSvc)
	commentSvc := service.NewCommentService(db, commentRepo, postRepo, communityNotifSvc)
	likeSvc := service.NewLikeService(db, likeRepo, postRepo, commentRepo, communityNotifSvc)

	// Middleware
	authMiddleware := middleware.NewAuth(firebaseAuth, userRepo)
	rateLimiter := middleware.NewRateLimiter(rdb, cfg.FreeTierRateLimit, cfg.PremiumRateLimit)

	// Handlers
	handlers := &handler.Handlers{
		Auth:          handler.NewAuthHandler(userSvc, subscriptionSvc),
		User:          handler.NewUserHandler(userSvc),
		Chart:         handler.NewChartHandler(chartSvc),
		Vedic:         handler.NewVedicHandler(vedicSvc),
		DailyReading:  handler.NewDailyReadingHandler(readingSvc),
		AIChat:        handler.NewAIChatHandler(aiSvc),
		Compatibility: handler.NewCompatibilityHandler(compatibilitySvc),
		Subscription:  handler.NewSubscriptionHandler(subscriptionSvc),
		Journal:       handler.NewJournalHandler(journalRepo),
		Places:        handler.NewPlacesHandler(),
		// Community / Spaces forum
		Spaces:                 handler.NewSpacesHandler(communitySvc),
		Posts:                  handler.NewPostsHandler(postSvc, likeSvc),
		Comments:               handler.NewCommentsHandler(commentSvc, likeSvc),
		CommunityNotifications: handler.NewCommunityNotificationsHandler(communityNotifSvc),
		Discovery:              handler.NewDiscoveryHandler(communitySvc, hashtagRepo),
	}

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
