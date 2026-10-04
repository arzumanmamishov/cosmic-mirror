package config

import (
	"strings"
	"testing"
)

func TestLoadRejectsUnparseableURLs(t *testing.T) {
	cases := []struct {
		name, db, redis, wantErr string
	}{
		{"ok", "postgres://cosmic:0123abcdef@postgres:5432/cosmic_mirror?sslmode=disable", "redis://:0123abcdef@redis:6379", ""},
		{"base64 slash in db password", "postgres://cosmic:ab/cd+ef=@postgres:5432/cosmic_mirror", "redis://:x@redis:6379", "DATABASE_URL"},
		{"base64 slash in redis password", "postgres://cosmic:x@postgres:5432/cosmic_mirror", "redis://:ab/cd+ef=@redis:6379", "REDIS_URL"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("ENVIRONMENT", "dev")
			t.Setenv("DATABASE_URL", tc.db)
			t.Setenv("REDIS_URL", tc.redis)
			_, err := Load()
			if tc.wantErr == "" {
				if err != nil {
					t.Fatalf("unexpected error: %v", err)
				}
				return
			}
			if err == nil || !strings.Contains(err.Error(), tc.wantErr) {
				t.Fatalf("want %s error, got %v", tc.wantErr, err)
			}
			if strings.Contains(err.Error(), "cd+ef") {
				t.Fatalf("error leaks the password: %v", err)
			}
		})
	}
}
