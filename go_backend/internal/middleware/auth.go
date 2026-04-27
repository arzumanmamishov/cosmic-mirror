package middleware

import (
	"context"
	"encoding/json"
	"log/slog"
	"net/http"
	"strings"

	"cosmic-mirror/internal/provider/firebase"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
)

type contextKey string

const (
	userIDKey     contextKey = "userID"
	firebaseUIDKey contextKey = "firebaseUID"
	isPremiumKey  contextKey = "isPremium"
)

type Auth struct {
	firebaseAuth *firebase.AuthClient
	userRepo     repository.UserRepository
}

func NewAuth(firebaseAuth *firebase.AuthClient, userRepo repository.UserRepository) *Auth {
	return &Auth{
		firebaseAuth: firebaseAuth,
		userRepo:     userRepo,
	}
}

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

		token, err := a.firebaseAuth.VerifyIDToken(r.Context(), parts[1])
		if err != nil {
			slog.Warn("firebase token verification failed", "error", err)
			respondError(w, http.StatusUnauthorized, "invalid_token", "Invalid or expired token")
			return
		}

		// Look up internal user
		user, err := a.userRepo.GetByFirebaseUID(r.Context(), token.UID)
		if err != nil || user == nil {
			slog.Error("failed to get user by firebase UID", "error", err, "uid", token.UID)
			respondError(w, http.StatusUnauthorized, "user_not_found", "User not found")
			return
		}

		ctx := context.WithValue(r.Context(), userIDKey, user.ID)
		ctx = context.WithValue(ctx, firebaseUIDKey, token.UID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func UserIDFromContext(ctx context.Context) uuid.UUID {
	id, _ := ctx.Value(userIDKey).(uuid.UUID)
	return id
}

func FirebaseUIDFromContext(ctx context.Context) string {
	uid, _ := ctx.Value(firebaseUIDKey).(string)
	return uid
}

func respondError(w http.ResponseWriter, status int, code, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(map[string]any{
		"error": map[string]string{
			"code":    code,
			"message": message,
		},
	})
}
