// Package middleware — auth verifies the local access-token JWT on every
// protected request. The old Firebase-ID-token path was retired in migration
// 010; consumers should send our first-party HS256 access token instead.
package middleware

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"strings"

	"cosmic-mirror/internal/pkg/tokens"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
)

type contextKey string

const (
	userIDKey contextKey = "userID"
)

type Auth struct {
	signer   *tokens.Signer
	userRepo repository.UserRepository
}

func NewAuth(signer *tokens.Signer, userRepo repository.UserRepository) *Auth {
	return &Auth{signer: signer, userRepo: userRepo}
}

// Verify pulls the bearer token, parses + validates the JWT, and stashes
// the user id on the request context. Rejects with 401 for anything
// unusual (missing header, malformed prefix, bad signature, expired).
func (a *Auth) Verify(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			respondError(w, http.StatusUnauthorized, "missing_token", "Authorization header is required")
			return
		}
		parts := strings.SplitN(authHeader, " ", 2)
		if len(parts) != 2 || !strings.EqualFold(parts[0], "bearer") {
			respondError(w, http.StatusUnauthorized, "invalid_token", "Invalid authorization header format")
			return
		}

		claims, err := a.signer.ParseAccess(parts[1])
		if err != nil {
			slog.Debug("access token verification failed", "error", err)
			respondError(w, http.StatusUnauthorized, "invalid_token", "Invalid or expired token")
			return
		}
		// Belt-and-braces: refuse tokens whose user was soft-deleted
		// between issue and use. This catches the "app open for weeks
		// after account deletion" edge case with one DB hit.
		user, err := a.userRepo.GetByID(r.Context(), claims.UserID)
		if err != nil || user == nil {
			slog.Debug("access token references unknown user", "uid", claims.UserID)
			respondError(w, http.StatusUnauthorized, "user_not_found", "User not found")
			return
		}

		ctx := context.WithValue(r.Context(), userIDKey, user.ID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// UserIDFromContext is what handlers call to identify the caller.
func UserIDFromContext(ctx context.Context) uuid.UUID {
	id, _ := ctx.Value(userIDKey).(uuid.UUID)
	return id
}

// FirebaseUIDFromContext is retained as a no-op for callers that haven't
// been migrated off the legacy accessor yet. New code should not use it.
func FirebaseUIDFromContext(_ context.Context) string { return "" }

func respondError(w http.ResponseWriter, status int, code, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"error": map[string]string{
			"code":    code,
			"message": message,
		},
	})
}
