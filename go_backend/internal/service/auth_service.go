// AuthService is the local-auth counterpart to the Firebase-based flow that
// used to live in UserService.CreateOrGetUser. It composes:
//
//   - OTPService for issue/verify of email codes
//   - tokens.Signer for access-token JWTs
//   - RefreshTokenRepository for opaque refresh tokens
//   - UserRepository for the user row
//
// Endpoints call the methods here to run the four public flows:
//   RegisterVerify   → verify OTP + create user + issue tokens
//   Login            → email + password → verify → issue tokens
//   LoginVerify      → verify OTP + issue tokens (passwordless login)
//   PasswordResetVerify → verify OTP + set new password
//   Refresh          → rotate refresh token, issue new access
//   Logout           → revoke supplied refresh token
package service

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/otp"
	"cosmic-mirror/internal/pkg/tokens"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

var (
	// ErrAuthInvalidCredentials is the single "either the email or password is
	// wrong" sentinel — the handler maps it to a generic 401 so we don't leak
	// whether the account exists.
	ErrAuthInvalidCredentials = errors.New("auth: invalid credentials")
	// ErrAuthEmailInUse is returned by RegisterVerify when the address is
	// already registered.
	ErrAuthEmailInUse = errors.New("auth: email already registered")
	// ErrAuthUserNotFound is used by the password-reset path when the OTP
	// verified but no user row exists — should never happen in practice
	// because the OTP request would have been silent for unknown emails.
	ErrAuthUserNotFound = errors.New("auth: user not found")
	// ErrAuthInvalidRefresh is the single sentinel for any refresh failure
	// (unknown / revoked / expired / rotated).
	ErrAuthInvalidRefresh = errors.New("auth: invalid refresh token")
)

// AuthService owns the register/login/refresh/reset flows for local auth.
type AuthService struct {
	userRepo repository.UserRepository
	rtRepo   repository.RefreshTokenRepository
	otp      *OTPService
	signer   *tokens.Signer
}

func NewAuthService(
	userRepo repository.UserRepository,
	rtRepo repository.RefreshTokenRepository,
	otpSvc *OTPService,
	signer *tokens.Signer,
) *AuthService {
	return &AuthService{userRepo: userRepo, rtRepo: rtRepo, otp: otpSvc, signer: signer}
}

// Session is the (user, tokens) envelope every successful auth endpoint
// returns. Access is short-lived (~15m); refresh is 30d and opaque.
type Session struct {
	User             *domain.User
	AccessToken      string
	AccessExpiresAt  time.Time
	RefreshToken     string
	RefreshExpiresAt time.Time
}

// RequestOTP issues a code for the requested purpose. For login and
// password_reset the caller MUST already have an account — issuing a code
// to a random address is a UX trap (the user gets a code they can't use)
// and a spam vector, so we refuse up-front with ErrAuthUserNotFound.
//
// The trade-off is a small email-enumeration surface: an attacker can now
// tell "registered" from "unregistered" by watching for a 404 vs 200.
// That's an acceptable price for consumer-app UX; a stricter posture
// would keep the response silent and rely on the rate limit alone.
func (s *AuthService) RequestOTP(ctx context.Context, email string, purpose otp.Purpose, ip string) (time.Duration, error) {
	if purpose == otp.PurposeLogin || purpose == otp.PurposePasswordReset {
		normalized := strings.ToLower(strings.TrimSpace(email))
		user, err := s.userRepo.GetByEmail(ctx, normalized)
		if err != nil {
			return 0, err
		}
		if user == nil {
			return 0, ErrAuthUserNotFound
		}
	}
	return s.otp.Request(ctx, email, purpose, ip)
}

// RegisterVerify verifies the OTP, creates the user if new (or returns the
// existing account as if it was a login — idempotent from the client's
// perspective), and returns a fresh session. Password is optional; when
// omitted the account is passwordless (login only via OTP).
func (s *AuthService) RegisterVerify(
	ctx context.Context,
	email, code, name, password, ip, userAgent string,
) (*Session, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	if err := s.otp.VerifyAndConsume(ctx, email, otp.PurposeRegister, code, ip); err != nil {
		return nil, err
	}
	existing, err := s.userRepo.GetByEmail(ctx, email)
	if err != nil {
		return nil, err
	}
	if existing != nil {
		// Treat as a passwordless sign-in — the OTP verified control of
		// the inbox. This makes the endpoint idempotent so a double-tap
		// on "Verify" doesn't 400.
		_ = s.userRepo.MarkEmailVerified(ctx, existing.ID)
		_ = s.userRepo.TouchLastLogin(ctx, existing.ID)
		return s.issueSession(ctx, existing, ip, userAgent)
	}
	now := time.Now()
	user := &domain.User{
		Email:           email,
		Name:            name,
		EmailVerifiedAt: &now,
	}
	if password != "" {
		hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
		if err != nil {
			return nil, fmt.Errorf("bcrypt: %w", err)
		}
		s := string(hash)
		user.PasswordHash = &s
	}
	if err := s.userRepo.Create(ctx, user); err != nil {
		return nil, err
	}
	_ = s.userRepo.TouchLastLogin(ctx, user.ID)
	return s.issueSession(ctx, user, ip, userAgent)
}

// LoginPassword authenticates with email + password. Returns
// ErrAuthInvalidCredentials for any failure — wrong email, wrong password,
// missing hash (passwordless account).
func (s *AuthService) LoginPassword(
	ctx context.Context,
	email, password, ip, userAgent string,
) (*Session, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	user, err := s.userRepo.GetByEmail(ctx, email)
	if err != nil {
		return nil, err
	}
	if user == nil || user.PasswordHash == nil || *user.PasswordHash == "" {
		return nil, ErrAuthInvalidCredentials
	}
	if err := bcrypt.CompareHashAndPassword([]byte(*user.PasswordHash), []byte(password)); err != nil {
		return nil, ErrAuthInvalidCredentials
	}
	_ = s.userRepo.MarkEmailVerified(ctx, user.ID)
	_ = s.userRepo.TouchLastLogin(ctx, user.ID)
	return s.issueSession(ctx, user, ip, userAgent)
}

// LoginVerify verifies a passwordless-login OTP and returns a session. The
// caller must have previously requested a code with purpose=login. Refuses
// for unknown emails — dining-os makes the same call so the "no account"
// UX is honest.
func (s *AuthService) LoginVerify(
	ctx context.Context,
	email, code, ip, userAgent string,
) (*Session, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	if err := s.otp.VerifyAndConsume(ctx, email, otp.PurposeLogin, code, ip); err != nil {
		return nil, err
	}
	user, err := s.userRepo.GetByEmail(ctx, email)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, ErrAuthUserNotFound
	}
	_ = s.userRepo.MarkEmailVerified(ctx, user.ID)
	_ = s.userRepo.TouchLastLogin(ctx, user.ID)
	return s.issueSession(ctx, user, ip, userAgent)
}

// PasswordResetVerify verifies the OTP + sets a new password. It also
// revokes every active refresh token for the user so any stolen session
// can't survive the password change.
func (s *AuthService) PasswordResetVerify(ctx context.Context, email, code, newPassword, ip string) error {
	email = strings.ToLower(strings.TrimSpace(email))
	if err := s.otp.VerifyAndConsume(ctx, email, otp.PurposePasswordReset, code, ip); err != nil {
		return err
	}
	user, err := s.userRepo.GetByEmail(ctx, email)
	if err != nil {
		return err
	}
	if user == nil {
		return ErrAuthUserNotFound
	}
	hash, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("bcrypt: %w", err)
	}
	if err := s.userRepo.UpdatePasswordHash(ctx, user.ID, string(hash)); err != nil {
		return err
	}
	_ = s.rtRepo.RevokeAllForUser(ctx, user.ID)
	return nil
}

// Refresh rotates the supplied refresh token: the old one is revoked, a
// new one is issued, and a fresh access token is returned. Presenting an
// already-rotated (or unknown) token returns ErrAuthInvalidRefresh.
func (s *AuthService) Refresh(ctx context.Context, plainRefresh, ip, userAgent string) (*Session, error) {
	row, err := s.rtRepo.FindActiveByHash(ctx, tokens.HashRefresh(plainRefresh))
	if err != nil {
		return nil, err
	}
	if row == nil {
		return nil, ErrAuthInvalidRefresh
	}
	user, err := s.userRepo.GetByID(ctx, row.UserID)
	if err != nil {
		return nil, err
	}
	if user == nil {
		return nil, ErrAuthInvalidRefresh
	}

	access, accessExp, err := s.signer.IssueAccess(user.ID)
	if err != nil {
		return nil, err
	}
	newRefresh, refreshExp, err := s.signer.GenerateRefresh()
	if err != nil {
		return nil, err
	}
	if _, err := s.rtRepo.Rotate(ctx, row.ID, tokens.HashRefresh(newRefresh), refreshExp, ip, userAgent); err != nil {
		return nil, err
	}
	return &Session{
		User:             user,
		AccessToken:      access,
		AccessExpiresAt:  accessExp,
		RefreshToken:     newRefresh,
		RefreshExpiresAt: refreshExp,
	}, nil
}

// Logout revokes the supplied refresh token. Idempotent — an unknown
// token returns nil so a client with a stale token can still "log out".
func (s *AuthService) Logout(ctx context.Context, plainRefresh string) error {
	return s.rtRepo.RevokeByHash(ctx, tokens.HashRefresh(plainRefresh))
}

// issueSession is the common tail: mint access + refresh, persist the
// refresh hash, return the envelope.
func (s *AuthService) issueSession(ctx context.Context, user *domain.User, ip, userAgent string) (*Session, error) {
	access, accessExp, err := s.signer.IssueAccess(user.ID)
	if err != nil {
		return nil, err
	}
	refresh, refreshExp, err := s.signer.GenerateRefresh()
	if err != nil {
		return nil, err
	}
	if _, err := s.rtRepo.Insert(ctx, user.ID, tokens.HashRefresh(refresh), refreshExp, ip, userAgent); err != nil {
		return nil, err
	}
	return &Session{
		User:             user,
		AccessToken:      access,
		AccessExpiresAt:  accessExp,
		RefreshToken:     refresh,
		RefreshExpiresAt: refreshExp,
	}, nil
}

// Suppress unused-import warning when uuid isn't referenced from the file body.
var _ = uuid.Nil
