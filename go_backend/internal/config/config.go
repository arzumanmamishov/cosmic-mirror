package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/joho/godotenv"
)

type Config struct {
	Port                    string
	Environment             string
	LogLevel                string
	CORSOrigins             []string
	DatabaseURL             string
	RedisURL                string
	FirebaseCredentialsPath string
	OpenAIAPIKey            string
	EphemerisPath           string
	UploadsDir              string
	RevenueCatWebhookSecret string
	StripeSecretKey         string
	StripePublishableKey    string
	StripeWebhookSecret     string
	StripePriceMonthly      string
	StripePriceYearly       string
	FreeTierChatLimit       int
	FreeTierRateLimit       int
	PremiumRateLimit        int

	// SMTP for OTP delivery. When SMTPHost is empty the mailer falls back
	// to a no-op transport that logs the message body — dev machines see
	// the OTP code in the API logs without needing a real SMTP account.
	SMTPHost     string
	SMTPPort     int
	SMTPUsername string
	SMTPPassword string
	SMTPFrom     string
	SMTPFromName string
	SMTPUseTLS   bool

	// JWT signing for local access tokens. Refresh tokens are opaque and
	// stored server-side (see refresh_tokens table).
	JWTSecret           string
	JWTAccessTTLMinutes int
	JWTRefreshTTLDays   int
}

func Load() (*Config, error) {
	_ = godotenv.Load()

	cfg := &Config{
		Port:                    getEnv("PORT", "8080"),
		Environment:             getEnv("ENVIRONMENT", "dev"),
		LogLevel:                getEnv("LOG_LEVEL", "info"),
		CORSOrigins:             strings.Split(getEnv("CORS_ORIGINS", "*"), ","),
		DatabaseURL:             getEnv("DATABASE_URL", ""),
		RedisURL:                getEnv("REDIS_URL", "redis://localhost:6379"),
		FirebaseCredentialsPath: getEnv("FIREBASE_CREDENTIALS_PATH", ""),
		OpenAIAPIKey:            getEnv("OPENAI_API_KEY", ""),
		EphemerisPath:           getEnv("EPHEMERIS_PATH", "./ephemeris"),
		UploadsDir:              getEnv("UPLOADS_DIR", "/app/uploads"),
		RevenueCatWebhookSecret: getEnv("REVENUECAT_WEBHOOK_SECRET", ""),
		StripeSecretKey:         getEnv("STRIPE_SECRET_KEY", ""),
		StripePublishableKey:    getEnv("STRIPE_PUBLISHABLE_KEY", ""),
		StripeWebhookSecret:     getEnv("STRIPE_WEBHOOK_SECRET", ""),
		StripePriceMonthly:      getEnv("STRIPE_PRICE_MONTHLY", ""),
		StripePriceYearly:       getEnv("STRIPE_PRICE_YEARLY", ""),
		FreeTierChatLimit:       getEnvInt("FREE_TIER_CHAT_LIMIT", 5),
		FreeTierRateLimit:       getEnvInt("FREE_TIER_RATE_LIMIT", 60),
		PremiumRateLimit:        getEnvInt("PREMIUM_RATE_LIMIT", 120),
		SMTPHost:                getEnv("SMTP_HOST", ""),
		SMTPPort:                getEnvInt("SMTP_PORT", 587),
		SMTPUsername:            getEnv("SMTP_USERNAME", ""),
		SMTPPassword:            getEnv("SMTP_PASSWORD", ""),
		SMTPFrom:                getEnv("SMTP_FROM_EMAIL", "no-reply@livelyapp.co"),
		SMTPFromName:            getEnv("SMTP_FROM_NAME", "Lively"),
		SMTPUseTLS:              getEnvBool("SMTP_USE_TLS", true),
		JWTSecret:               getEnv("JWT_SECRET", ""),
		JWTAccessTTLMinutes:     getEnvInt("JWT_ACCESS_TTL_MINUTES", 15),
		JWTRefreshTTLDays:       getEnvInt("JWT_REFRESH_TTL_DAYS", 30),
	}

	if cfg.DatabaseURL == "" {
		return nil, fmt.Errorf("DATABASE_URL is required")
	}
	if cfg.JWTSecret == "" {
		// Dev fallback so a fresh clone doesn't refuse to boot — but any
		// non-dev environment should fail loudly if the secret was forgotten.
		if cfg.IsDev() {
			cfg.JWTSecret = "dev-only-jwt-secret-please-override-in-prod"
		} else {
			return nil, fmt.Errorf("JWT_SECRET is required outside dev")
		}
	}

	return cfg, nil
}

func (c *Config) IsDev() bool  { return c.Environment == "dev" }
func (c *Config) IsProd() bool { return c.Environment == "prod" }

func getEnv(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}

func getEnvInt(key string, fallback int) int {
	if val := os.Getenv(key); val != "" {
		if i, err := strconv.Atoi(val); err == nil {
			return i
		}
	}
	return fallback
}

func getEnvBool(key string, fallback bool) bool {
	if val := os.Getenv(key); val != "" {
		if b, err := strconv.ParseBool(val); err == nil {
			return b
		}
	}
	return fallback
}
