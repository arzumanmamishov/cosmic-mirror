// Package handler HTTP surface for authentication: OTP + local password.
//
// Endpoints (all public):
//
//	POST /auth/otp/request     — issue OTP for {register|login|password_reset}
//	POST /auth/register        — verify OTP + create user + issue session
//	POST /auth/login           — email+password → session (no OTP)
//	POST /auth/login/otp       — verify OTP for passwordless login → session
//	POST /auth/password/reset  — verify OTP + set new password
//	POST /auth/refresh         — rotate refresh token → new session
//	POST /auth/logout          — revoke refresh token
//
// Every "session" response is `{ data: { user, tokens } }`. Tokens are the
// local JWT + opaque refresh — the old Firebase-ID-token flow is gone.
package handler

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"cosmic-mirror/internal/otp"
	"cosmic-mirror/internal/service"
)

type AuthHandler struct {
	auth    *service.AuthService
	userSvc *service.UserService
	subSvc  *service.SubscriptionService
}

func NewAuthHandler(
	auth *service.AuthService,
	userSvc *service.UserService,
	subSvc *service.SubscriptionService,
) *AuthHandler {
	return &AuthHandler{auth: auth, userSvc: userSvc, subSvc: subSvc}
}

// ---------------------------------------------------------------------------
// Request DTOs
// ---------------------------------------------------------------------------

type otpRequestBody struct {
	Email   string `json:"email"`
	Purpose string `json:"purpose"`
}

type registerBody struct {
	Email    string `json:"email"`
	Code     string `json:"code"`
	Name     string `json:"name"`
	Password string `json:"password"`
}

type loginBody struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type loginOTPBody struct {
	Email string `json:"email"`
	Code  string `json:"code"`
}

type resetBody struct {
	Email       string `json:"email"`
	Code        string `json:"code"`
	NewPassword string `json:"new_password"`
}

type refreshBody struct {
	RefreshToken string `json:"refresh_token"`
}

// ---------------------------------------------------------------------------
// Endpoints
// ---------------------------------------------------------------------------

// RequestOTP issues a code for the requested purpose.
func (h *AuthHandler) RequestOTP(w http.ResponseWriter, r *http.Request) {
	var in otpRequestBody
	if err := decodeBody(r, &in); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	if !isEmail(in.Email) {
		respondError(w, http.StatusBadRequest, "invalid_email", "A valid email is required")
		return
	}
	purpose := otp.Purpose(in.Purpose)
	if !purpose.Valid() {
		respondError(w, http.StatusBadRequest, "invalid_purpose",
			"Purpose must be one of: register, login, password_reset")
		return
	}
	ttl, err := h.auth.RequestOTP(r.Context(), in.Email, purpose, clientIP(r))
	if err != nil {
		if errors.Is(err, service.ErrOTPRateLimited) {
			respondError(w, http.StatusTooManyRequests, "rate_limited",
				"Too many code requests for this email. Try again in a few minutes.")
			return
		}
		respondError(w, http.StatusInternalServerError, "otp_request_failed", err.Error())
		return
	}
	respondSuccess(w, map[string]any{
		"message":    "if the email is valid, a code has been sent",
		"expires_in": int(ttl.Seconds()),
	})
}

// Register verifies the OTP and creates the account. Idempotent: an already-
// registered email just logs the user in.
func (h *AuthHandler) Register(w http.ResponseWriter, r *http.Request) {
	var in registerBody
	if err := decodeBody(r, &in); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	if !isEmail(in.Email) || len(in.Code) != 6 {
		respondError(w, http.StatusBadRequest, "invalid_body", "Email and 6-digit code are required")
		return
	}
	if in.Password != "" && len(in.Password) < 8 {
		respondError(w, http.StatusBadRequest, "weak_password",
			"Password must be at least 8 characters")
		return
	}
	sess, err := h.auth.RegisterVerify(r.Context(),
		in.Email, in.Code, strings.TrimSpace(in.Name), in.Password,
		clientIP(r), r.UserAgent(),
	)
	if err != nil {
		h.writeAuthError(w, err)
		return
	}
	h.respondSession(r.Context(), w, http.StatusCreated, sess)
}

// Login authenticates with email + password.
func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var in loginBody
	if err := decodeBody(r, &in); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	if !isEmail(in.Email) || in.Password == "" {
		respondError(w, http.StatusBadRequest, "invalid_body", "Email and password are required")
		return
	}
	sess, err := h.auth.LoginPassword(r.Context(), in.Email, in.Password,
		clientIP(r), r.UserAgent())
	if err != nil {
		if errors.Is(err, service.ErrAuthInvalidCredentials) {
			respondError(w, http.StatusUnauthorized, "invalid_credentials",
				"Email or password is incorrect")
			return
		}
		respondError(w, http.StatusInternalServerError, "login_failed", err.Error())
		return
	}
	h.respondSession(r.Context(), w, http.StatusOK, sess)
}

// LoginOTP verifies a passwordless-login OTP.
func (h *AuthHandler) LoginOTP(w http.ResponseWriter, r *http.Request) {
	var in loginOTPBody
	if err := decodeBody(r, &in); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	if !isEmail(in.Email) || len(in.Code) != 6 {
		respondError(w, http.StatusBadRequest, "invalid_body", "Email and 6-digit code are required")
		return
	}
	sess, err := h.auth.LoginVerify(r.Context(), in.Email, in.Code,
		clientIP(r), r.UserAgent())
	if err != nil {
		h.writeAuthError(w, err)
		return
	}
	h.respondSession(r.Context(), w, http.StatusOK, sess)
}

// PasswordReset verifies the OTP + sets a new password.
func (h *AuthHandler) PasswordReset(w http.ResponseWriter, r *http.Request) {
	var in resetBody
	if err := decodeBody(r, &in); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	if !isEmail(in.Email) || len(in.Code) != 6 || len(in.NewPassword) < 8 {
		respondError(w, http.StatusBadRequest, "invalid_body",
			"Email, 6-digit code, and new password (8+ chars) are required")
		return
	}
	if err := h.auth.PasswordResetVerify(r.Context(), in.Email, in.Code, in.NewPassword, clientIP(r)); err != nil {
		h.writeAuthError(w, err)
		return
	}
	respondSuccess(w, map[string]string{"message": "password updated"})
}

// Refresh rotates the refresh token.
func (h *AuthHandler) Refresh(w http.ResponseWriter, r *http.Request) {
	var in refreshBody
	if err := decodeBody(r, &in); err != nil || in.RefreshToken == "" {
		respondError(w, http.StatusBadRequest, "invalid_body", "refresh_token is required")
		return
	}
	sess, err := h.auth.Refresh(r.Context(), in.RefreshToken, clientIP(r), r.UserAgent())
	if err != nil {
		if errors.Is(err, service.ErrAuthInvalidRefresh) {
			respondError(w, http.StatusUnauthorized, "invalid_refresh", "Refresh token is invalid or expired")
			return
		}
		respondError(w, http.StatusInternalServerError, "refresh_failed", err.Error())
		return
	}
	h.respondSession(r.Context(), w, http.StatusOK, sess)
}

// Logout revokes the supplied refresh token. Idempotent.
func (h *AuthHandler) Logout(w http.ResponseWriter, r *http.Request) {
	var in refreshBody
	if err := decodeBody(r, &in); err != nil || in.RefreshToken == "" {
		respondError(w, http.StatusBadRequest, "invalid_body", "refresh_token is required")
		return
	}
	_ = h.auth.Logout(r.Context(), in.RefreshToken)
	respondSuccess(w, map[string]string{"message": "logged out"})
}

// ---------------------------------------------------------------------------
// Legacy: kept while the app finishes migrating off Firebase.
// ---------------------------------------------------------------------------

// CreateSession — the legacy Firebase-ID-token bootstrap endpoint. Kept as
// a hard-gone stub so an in-flight app doesn't silently misbehave; new
// builds should call POST /auth/register or POST /auth/login.
func (h *AuthHandler) CreateSession(w http.ResponseWriter, r *http.Request) {
	respondError(w, http.StatusGone, "legacy_endpoint",
		"This endpoint has moved. Use POST /auth/register or POST /auth/login.")
}

func (h *AuthHandler) PrivacyPolicy(w http.ResponseWriter, r *http.Request) {
	respondSuccess(w, map[string]string{
		"content":   privacyPolicyText,
		"version":   legalVersion,
		"effective": legalEffectiveDate,
		"web_url":   "https://livelyapp.co/privacy",
	})
}

func (h *AuthHandler) TermsOfService(w http.ResponseWriter, r *http.Request) {
	respondSuccess(w, map[string]string{
		"content":   termsOfServiceText,
		"version":   legalVersion,
		"effective": legalEffectiveDate,
		"web_url":   "https://livelyapp.co/terms",
	})
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// respondSession serializes the (user, tokens) envelope every successful
// auth endpoint returns. One place to change if the response schema evolves.
func (h *AuthHandler) respondSession(ctx context.Context, w http.ResponseWriter, status int, s *service.Session) {
	hasOnboarding := h.userSvc.HasCompletedOnboarding(ctx, s.User.ID)
	payload := map[string]any{
		"user": map[string]any{
			"id":                       s.User.ID,
			"email":                    s.User.Email,
			"name":                     s.User.Name,
			"avatar_url":               s.User.AvatarURL,
			"has_completed_onboarding": hasOnboarding,
		},
		"tokens": map[string]any{
			"access_token":       s.AccessToken,
			"access_expires_at":  s.AccessExpiresAt,
			"refresh_token":      s.RefreshToken,
			"refresh_expires_at": s.RefreshExpiresAt,
		},
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(map[string]any{"data": payload})
}

// writeAuthError normalises AuthService errors to a single HTTP surface.
func (h *AuthHandler) writeAuthError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, service.ErrOTPInvalid),
		errors.Is(err, service.ErrAuthInvalidCredentials):
		respondError(w, http.StatusBadRequest, "invalid_code", "Invalid or expired code")
	case errors.Is(err, service.ErrAuthEmailInUse):
		respondError(w, http.StatusConflict, "email_in_use", "That email is already registered")
	case errors.Is(err, service.ErrAuthUserNotFound):
		respondError(w, http.StatusNotFound, "user_not_found", "No account for that email")
	default:
		respondError(w, http.StatusInternalServerError, "auth_error", err.Error())
	}
}

// clientIP walks X-Forwarded-For / X-Real-IP then falls back to RemoteAddr.
func clientIP(r *http.Request) string {
	if v := r.Header.Get("X-Forwarded-For"); v != "" {
		if i := strings.IndexByte(v, ','); i >= 0 {
			return strings.TrimSpace(v[:i])
		}
		return strings.TrimSpace(v)
	}
	if v := r.Header.Get("X-Real-IP"); v != "" {
		return strings.TrimSpace(v)
	}
	if i := strings.LastIndexByte(r.RemoteAddr, ':'); i >= 0 {
		return r.RemoteAddr[:i]
	}
	return r.RemoteAddr
}

// isEmail is a deliberately lenient shape check — real deliverability is
// only known after we try to send. Rejects the obvious "abc" and empty.
func isEmail(s string) bool {
	s = strings.TrimSpace(s)
	if len(s) < 5 || len(s) > 254 {
		return false
	}
	at := strings.IndexByte(s, '@')
	if at <= 0 || at == len(s)-1 {
		return false
	}
	return strings.Contains(s[at+1:], ".")
}
