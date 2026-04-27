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
	RevenueCatWebhookSecret string
	FreeTierChatLimit       int
	FreeTierRateLimit       int
	PremiumRateLimit        int
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
		RevenueCatWebhookSecret: getEnv("REVENUECAT_WEBHOOK_SECRET", ""),
		FreeTierChatLimit:       getEnvInt("FREE_TIER_CHAT_LIMIT", 3),
		FreeTierRateLimit:       getEnvInt("FREE_TIER_RATE_LIMIT", 60),
		PremiumRateLimit:        getEnvInt("PREMIUM_RATE_LIMIT", 120),
	}

	if cfg.DatabaseURL == "" {
		return nil, fmt.Errorf("DATABASE_URL is required")
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
