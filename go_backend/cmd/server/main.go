package main

import (
	"context"
	"cosmic-mirror/internal/migrate"
	"cosmic-mirror/migrations"
	"fmt"
	"log/slog"
	"math/rand/v2"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"cosmic-mirror/internal/config"
	"cosmic-mirror/internal/handler"
	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/otp"
	"cosmic-mirror/internal/pkg/mailer"
	"cosmic-mirror/internal/pkg/tokens"
	"cosmic-mirror/internal/provider/openai"
	"cosmic-mirror/internal/provider/swisseph"
	"cosmic-mirror/internal/repository/postgres"
	"cosmic-mirror/internal/server"
	"cosmic-mirror/internal/service"
	"cosmic-mirror/internal/storage"
	"cosmic-mirror/internal/worker"

	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/jmoiron/sqlx"
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

	// Schema migrations (embedded in the binary). On by default; set
	// MIGRATE_ON_START=false to run them as a separate deploy step.
	if cfg.MigrateOnStart {
		if err := migrate.Up(context.Background(), db, migrations.FS); err != nil {
			slog.Error("database migration failed", "error", err)
			os.Exit(1)
		}
	}

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

	// Local auth: SMTP mailer + JWT signer + OTP infrastructure. Replaces
	// the Firebase Auth flow (retired in migration 010). When SMTP_HOST is
	// empty the mailer is a no-op that logs the OTP body so devs can copy
	// codes from the API logs without a real SMTP account.
	mail := mailer.New(mailer.Config{
		Host:      cfg.SMTPHost,
		Port:      cfg.SMTPPort,
		Username:  cfg.SMTPUsername,
		Password:  cfg.SMTPPassword,
		FromEmail: cfg.SMTPFrom,
		FromName:  cfg.SMTPFromName,
		UseTLS:    cfg.SMTPUseTLS,
	})
	signer := tokens.NewSigner(cfg.JWTSecret, cfg.JWTAccessTTLMinutes, cfg.JWTRefreshTTLDays)

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
	refreshTokenRepo := postgres.NewRefreshTokenRepository(db)
	otpRepo := otp.NewRepository(db)
	birthProfileRepo := postgres.NewBirthProfileRepository(db)
	readingRepo := postgres.NewReadingRepository(db)
	chatRepo := postgres.NewChatRepository(db)
	compatibilityRepo := postgres.NewCompatibilityRepository(db)
	savedPeopleRepo := postgres.NewSavedPeopleRepository(db)
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
	otpSvc := service.NewOTPService(otpRepo, mail)
	authSvc := service.NewAuthService(userRepo, refreshTokenRepo, otpSvc, signer)
	chartSvc := service.NewChartService(birthProfileRepo, chartProvider, openaiClient, rdb)
	vedicSvc := service.NewVedicService(birthProfileRepo, chartProvider, rdb)
	readingSvc := service.NewReadingService(readingRepo, birthProfileRepo, openaiClient, rdb)
	aiSvc := service.NewAIService(chatRepo, birthProfileRepo, userRepo, openaiClient, cfg.FreeTierChatLimit).
		WithUsageCounter(rdb)
	subscriptionSvc := service.NewSubscriptionService(subscriptionRepo, cfg.RevenueCatWebhookSecret).
		WithRevenueCatAPI(cfg.RevenueCatSecretAPIKey, cfg.RevenueCatEntitlementID)
	compatibilitySvc := service.NewCompatibilityService(compatibilityRepo, savedPeopleRepo, birthProfileRepo, openaiClient).
		WithFreeDailyLimit(rdb, freeCompatibilityDailyLimit, subscriptionSvc.IsPremium)
	stripeSvc := service.NewStripeService(
		subscriptionRepo,
		userSvc,
		cfg.StripeSecretKey,
		cfg.StripePublishableKey,
		cfg.StripeWebhookSecret,
		cfg.StripePriceMonthly,
		cfg.StripePriceYearly,
	)
	// Account deletion cancels the Stripe subscription and revokes every
	// session (wired after the fact: StripeService depends on UserService).
	userSvc.WithAccountDeletion(refreshTokenRepo, stripeSvc)
	// Community
	communityNotifSvc := service.NewCommunityNotificationService(communityNotifRepo)
	communitySvc := service.NewCommunityService(db, spaceRepo, spaceMemberRepo, spaceCategoryRepo, postRepo, userRepo, communityNotifSvc)
	postSvc := service.NewPostService(db, postRepo, spaceRepo, spaceMemberRepo, hashtagRepo, communityNotifRepo)
	commentSvc := service.NewCommentService(db, commentRepo, postRepo, spaceMemberRepo, communityNotifSvc)
	likeSvc := service.NewLikeService(db, likeRepo, postRepo, commentRepo, spaceMemberRepo, communityNotifSvc)
	// Community safety: reports, blocks, auto-hide, admin moderation.
	moderationSvc := service.NewModerationService(db, postgres.NewModerationRepository(db),
		postRepo, commentRepo, spaceRepo, hashtagRepo, userRepo, refreshTokenRepo, mail,
		service.ModerationConfig{
			Email:             cfg.ModerationEmail,
			AutoHideThreshold: cfg.ModerationAutoHideThreshold,
		})
	if cfg.ModerationEmail == "" && !cfg.IsDev() {
		slog.Warn("MODERATION_EMAIL is empty — new content reports will not be e-mailed to anyone")
	}
	// Numerology + Human Design
	numerologySvc := service.NewNumerologyService(userRepo, birthProfileRepo)
	humanDesignSvc := service.NewHumanDesignService(birthProfileRepo, chartProvider, rdb)
	psychomatrixSvc := service.NewPsychomatrixService(birthProfileRepo)
	destinyMatrixSvc := service.NewDestinyMatrixService(birthProfileRepo)

	// Middleware
	authMiddleware := middleware.NewAuth(signer, userRepo)
	rateLimiter := middleware.NewRateLimiter(rdb, cfg.FreeTierRateLimit, cfg.PremiumRateLimit, subscriptionSvc.IsPremium)

	// Handlers
	handlers := &handler.Handlers{
		Auth:          handler.NewAuthHandler(authSvc, userSvc, subscriptionSvc),
		User:          handler.NewUserHandler(userSvc, preferencesRepo, ritualRepo),
		Chart:         handler.NewChartHandler(chartSvc),
		Vedic:         handler.NewVedicHandler(vedicSvc),
		DailyReading:  handler.NewDailyReadingHandler(readingSvc),
		AIChat:        handler.NewAIChatHandler(aiSvc, subscriptionSvc),
		Compatibility: handler.NewCompatibilityHandler(compatibilitySvc),
		Subscription:  handler.NewSubscriptionHandler(subscriptionSvc),
		Stripe:        handler.NewStripeHandler(stripeSvc),
		Journal:       handler.NewJournalHandler(journalRepo),
		Places:        handler.NewPlacesHandler().WithRedis(rdb),
		// Community / Spaces forum
		Spaces:                 handler.NewSpacesHandler(communitySvc),
		Posts:                  handler.NewPostsHandler(postSvc, likeSvc),
		Comments:               handler.NewCommentsHandler(commentSvc, likeSvc),
		CommunityNotifications: handler.NewCommunityNotificationsHandler(communityNotifSvc),
		Discovery:              handler.NewDiscoveryHandler(communitySvc, hashtagRepo),
		Moderation:             handler.NewModerationHandler(moderationSvc),
		// Numerology + Human Design
		Numerology:    handler.NewNumerologyHandler(numerologySvc),
		HumanDesign:   handler.NewHumanDesignHandler(humanDesignSvc),
		Psychomatrix:  handler.NewPsychomatrixHandler(psychomatrixSvc),
		DestinyMatrix: handler.NewDestinyMatrixHandler(destinyMatrixSvc),
	}

	// Background workers — each runs once shortly after startup (so a
	// deploy/restart doesn't postpone daily jobs by a full interval), then
	// on an interval ticker, tied to a context cancelled on shutdown. The
	// start delays are staggered + jittered so the jobs don't all hit the
	// DB at boot, nor in lockstep across replicas. Daily readings are also
	// generated lazily on request, so these are best-effort.
	workerCtx, stopWorkers := context.WithCancel(context.Background())
	defer stopWorkers()
	dailyReadingsWorker := worker.NewDailyReadingsWorker(db, readingSvc)
	notificationsWorker := worker.NewNotificationsWorker(db)
	cleanupWorker := worker.NewCleanupWorker(db, rdb, avatarStore)
	scheduleWorker(workerCtx, "notifications", 30*time.Second, 15*time.Minute, notificationsWorker.Run)
	scheduleWorker(workerCtx, "cleanup", 2*time.Minute, 24*time.Hour, cleanupWorker.Run)
	scheduleWorker(workerCtx, "daily_readings", 5*time.Minute, 24*time.Hour, dailyReadingsWorker.Run)

	// Router
	router := server.NewRouter(handlers, authMiddleware, rateLimiter, cfg,
		func(ctx context.Context) error {
			if err := db.PingContext(ctx); err != nil {
				return fmt.Errorf("postgres: %w", err)
			}
			if err := rdb.Ping(ctx).Err(); err != nil {
				return fmt.Errorf("redis: %w", err)
			}
			return nil
		})

	// Server. Timeout budget (keep these consistent):
	//   - an LLM call is capped at openai.RequestBudget (75s total; 40s per
	//     attempt, retries + backoff only while budget remains);
	//   - WriteTimeout (90s) leaves ~15s on top of that for the handler's
	//     DB work and writing the response — at 30s the server used to cut
	//     the connection while gpt-4o was still answering;
	//   - shutdownGrace (90s) ≥ WriteTimeout, so a deploy lets every
	//     in-flight request (including a slow LLM call) finish. The
	//     container's stop grace period (docker stop_grace_period /
	//     k8s terminationGracePeriodSeconds) must be ≥ ~95s for this to
	//     take effect.
	srv := &http.Server{
		Addr:              fmt.Sprintf(":%s", cfg.Port),
		Handler:           router,
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       15 * time.Second,
		WriteTimeout:      openai.RequestBudget + 15*time.Second,
		IdleTimeout:       60 * time.Second,
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
	// Stop background workers first so they don't start new work (e.g.
	// another LLM call in the daily-readings batch) while draining.
	stopWorkers()
	shutdownCtx, cancel := context.WithTimeout(context.Background(), srv.WriteTimeout)
	defer cancel()

	if err := srv.Shutdown(shutdownCtx); err != nil {
		slog.Error("server forced to shutdown", "error", err)
	}
	slog.Info("server stopped")
}

// freeCompatibilityDailyLimit caps gpt-4o compatibility reports per UTC day
// for non-premium users (reusing a report from the last hour is free).
const freeCompatibilityDailyLimit = 3

// scheduleWorker runs fn once after [initialDelay] (plus up to 30s of
// random jitter), then every [interval], in its own goroutine until ctx is
// cancelled. Errors are logged, not fatal — a failed run shouldn't stop
// future runs or the server.
func scheduleWorker(ctx context.Context, name string, initialDelay, interval time.Duration, fn func(context.Context) error) {
	run := func() {
		start := time.Now()
		if err := fn(ctx); err != nil {
			if ctx.Err() != nil {
				return // shutting down
			}
			slog.Error("worker run failed", "worker", name, "error", err,
				"duration", time.Since(start).String())
		}
	}
	go func() {
		delay := initialDelay + time.Duration(rand.Int64N(int64(30*time.Second)))
		timer := time.NewTimer(delay)
		select {
		case <-ctx.Done():
			timer.Stop()
			return
		case <-timer.C:
		}
		run()

		ticker := time.NewTicker(interval)
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				run()
			}
		}
	}()
}
