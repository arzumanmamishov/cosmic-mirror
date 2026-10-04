package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/joho/godotenv"
	"github.com/redis/go-redis/v9"
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
	// RevenueCatSecretAPIKey (sk_…) lets webhooks fetch the authoritative
	// subscriber state from the RevenueCat REST API. Optional.
	RevenueCatSecretAPIKey string
	// RevenueCatEntitlementID is the entitlement that grants premium.
	RevenueCatEntitlementID string
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

	// TrustedProxies are the CIDRs of reverse proxies / load balancers
	// whose X-Forwarded-For / X-Real-IP headers we believe. Empty = trust
	// nobody and use the TCP peer address.
	TrustedProxies []string

	// MigrateOnStart applies pending SQL migrations at boot.
	MigrateOnStart bool

	// Community moderation (UGC safety). ModerationEmail receives one
	// e-mail per new report; AdminEmails may use /api/v1/admin/*;
	// ModerationAutoHideThreshold distinct open reports hide a post or
	// comment (< 1 disables auto-hide).
	ModerationEmail             string
	AdminEmails                 []string
	ModerationAutoHideThreshold int
}

func Load() (*Config, error) {
	_ = godotenv.Load()

	cfg := &Config{
		Port: getEnv("PORT", "8080"),
		// Fail safe: a deploy that forgets ENVIRONMENT runs with prod
		// checks, never with dev fallbacks.
		Environment:             getEnv("ENVIRONMENT", "prod"),
		LogLevel:                getEnv("LOG_LEVEL", "info"),
		CORSOrigins:             strings.Split(getEnv("CORS_ORIGINS", "*"), ","),
		DatabaseURL:             getEnv("DATABASE_URL", ""),
		RedisURL:                getEnv("REDIS_URL", "redis://localhost:6379"),
		FirebaseCredentialsPath: getEnv("FIREBASE_CREDENTIALS_PATH", ""),
		OpenAIAPIKey:            getEnv("OPENAI_API_KEY", ""),
		EphemerisPath:           getEnv("EPHEMERIS_PATH", "./ephemeris"),
		UploadsDir:              getEnv("UPLOADS_DIR", "/app/uploads"),
		RevenueCatWebhookSecret: getEnv("REVENUECAT_WEBHOOK_SECRET", ""),
		RevenueCatSecretAPIKey:  getEnv("REVENUECAT_SECRET_API_KEY", ""),
		RevenueCatEntitlementID: getEnv("REVENUECAT_ENTITLEMENT_ID", "premium"),
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
		TrustedProxies:          splitNonEmpty(getEnv("TRUSTED_PROXIES", "")),
		MigrateOnStart:          getEnvBool("MIGRATE_ON_START", true),

		// Community moderation (UGC safety).
		ModerationEmail:             strings.TrimSpace(getEnv("MODERATION_EMAIL", "")),
		AdminEmails:                 splitNonEmpty(strings.ToLower(getEnv("ADMIN_EMAILS", ""))),
		ModerationAutoHideThreshold: getEnvInt("MODERATION_AUTOHIDE_THRESHOLD", 3),
	}

	if cfg.DatabaseURL == "" {
		return nil, fmt.Errorf("DATABASE_URL is required")
	}
	// Parse both URLs up front so a password with URL-reserved characters
	// (an `openssl rand -base64` secret contains / + =) fails at boot with
	// a clear message instead of an opaque driver error. The parse errors
	// are deliberately not echoed: they quote the URL, password included.
	if _, err := pgconn.ParseConfig(cfg.DatabaseURL); err != nil {
		return nil, fmt.Errorf("DATABASE_URL is not a valid connection string. " +
			"If the password contains URL-reserved characters (/ + = @ : ? #), " +
			"percent-encode it or regenerate it with `openssl rand -hex 32`")
	}
	if _, err := redis.ParseURL(cfg.RedisURL); err != nil {
		return nil, fmt.Errorf("REDIS_URL is not a valid redis:// URL. " +
			"If the password contains URL-reserved characters (/ + = @ : ? #), " +
			"percent-encode it or regenerate it with `openssl rand -hex 32`")
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
	if !cfg.IsDev() {
		// Outside dev, refuse to boot with settings an attacker could
		// exploit rather than silently degrading.
		if len(cfg.JWTSecret) < 32 {
			return nil, fmt.Errorf("JWT_SECRET must be at least 32 characters outside dev")
		}
		if strings.TrimSpace(cfg.SMTPHost) == "" {
			return nil, fmt.Errorf("SMTP_HOST is required outside dev (otherwise OTP codes would only go to logs)")
		}
		if cfg.StripeSecretKey != "" && cfg.StripeWebhookSecret == "" {
			return nil, fmt.Errorf("STRIPE_WEBHOOK_SECRET is required when Stripe is configured")
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

func splitNonEmpty(s string) []string {
	var out []string
	for _, part := range strings.Split(s, ",") {
		if p := strings.TrimSpace(part); p != "" {
			out = append(out, p)
		}
	}
	return out
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
