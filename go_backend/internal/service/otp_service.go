package service

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"errors"
	"fmt"
	"log/slog"
	"math/big"
	"strings"
	"time"

	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/otp"
	"cosmic-mirror/internal/pkg/mailer"
)

// OTP tuning. Short TTL keeps stolen inboxes fresh; max_attempts caps
// online guessing; rate limits stop enumeration abuse.
//
// Per-code and per-10-minute limits alone still allow 5 guesses × 3 codes
// every 10 minutes (~2,000 guesses/day) against one email, from any number
// of IPs. The daily caps bound that: at most 10 codes per email per day,
// and once 10 wrong guesses have been made against an email in 24h, all
// verification for it is refused until the window rolls forward — a 1 in
// 100,000 chance per day for an attacker.
const (
	otpCodeTTL        = 10 * time.Minute
	otpMaxAttempts    = 5
	otpPerEmailWindow = 10 * time.Minute
	otpPerEmailMax    = 3
	otpDailyWindow    = 24 * time.Hour
	otpPerEmailDayMax = 10
	otpMaxFailsPerDay = 10
)

// ErrOTPInvalid is the sentinel returned for any verify failure — bad
// hash, expired, exhausted attempts, unknown row. Callers must map to a
// single generic "invalid or expired code" HTTP error so timing signals
// don't leak the specific case.
var ErrOTPInvalid = errors.New("otp: invalid or expired code")

// ErrOTPRateLimited is returned when the caller has requested too many
// codes for the same email within the sliding window.
var ErrOTPRateLimited = errors.New("otp: too many code requests — try again later")

// ErrOTPLocked is returned when too many wrong codes were entered for an
// email in the trailing 24h; verification (and new codes) for it are
// refused until older failures age out of the window.
var ErrOTPLocked = errors.New("otp: too many failed attempts — try again later")

// OTPService issues + verifies email OTPs and dispatches the email.
type OTPService struct {
	repo *otp.Repository
	mail mailer.Mailer
}

func NewOTPService(repo *otp.Repository, mail mailer.Mailer) *OTPService {
	return &OTPService{repo: repo, mail: mail}
}

// Request issues a new code for (email, purpose), stores its hash, and
// sends the email. Returns the code TTL so the client can render a
// countdown.
func (s *OTPService) Request(ctx context.Context, email string, purpose otp.Purpose, ip string) (time.Duration, error) {
	email = strings.ToLower(strings.TrimSpace(email))
	if !purpose.Valid() {
		return 0, fmt.Errorf("invalid purpose")
	}
	// No point mailing a code that can't be verified.
	if err := s.checkNotLocked(ctx, email); err != nil {
		return 0, err
	}
	// Rate limit per email (DB-backed, so it survives Redis restarts and
	// can't be dodged by rotating IPs).
	n, err := s.repo.RecentCountForEmail(ctx, email, otpPerEmailWindow)
	if err != nil {
		return 0, fmt.Errorf("otp: rate-limit check: %w", err)
	}
	if n >= otpPerEmailMax {
		return 0, ErrOTPRateLimited
	}
	n, err = s.repo.RecentCountForEmail(ctx, email, otpDailyWindow)
	if err != nil {
		return 0, fmt.Errorf("otp: rate-limit check: %w", err)
	}
	if n >= otpPerEmailDayMax {
		return 0, ErrOTPRateLimited
	}
	code, err := generateOTPCode()
	if err != nil {
		return 0, fmt.Errorf("otp: generate code: %w", err)
	}
	if _, err := s.repo.Insert(ctx, otp.InsertParams{
		Email:       email,
		Purpose:     purpose,
		CodeHash:    sha256Hex(code),
		MaxAttempts: otpMaxAttempts,
		ExpiresAt:   time.Now().Add(otpCodeTTL),
		RequestedIP: ip,
	}); err != nil {
		return 0, err
	}
	// Send the email. SMTP failures don't fail the request — the code
	// still lives in the DB and the user can retry. In dev the mailer
	// is a no-op that logs the code so the developer can copy it.
	if err := s.sendEmail(ctx, email, purpose, code); err != nil {
		slog.Error("otp email send failed", "error", err, "email", email, "purpose", string(purpose))
	}
	return otpCodeTTL, nil
}

// VerifyAndConsume finds the active code for (email, purpose),
// constant-time compares its hash, and marks it used on success. On
// mismatch it bumps attempts and locks out at the cap.
func (s *OTPService) VerifyAndConsume(ctx context.Context, email string, purpose otp.Purpose, code, ip string) error {
	email = strings.ToLower(strings.TrimSpace(email))
	if err := s.checkNotLocked(ctx, email); err != nil {
		return err
	}
	row, err := s.repo.FindActive(ctx, email, purpose)
	if errors.Is(err, otp.ErrNotFound) {
		return ErrOTPInvalid
	}
	if err != nil {
		return err
	}
	// Spend a guess atomically BEFORE comparing (see ReserveAttempt).
	codeHash, err := s.repo.ReserveAttempt(ctx, row.ID)
	if errors.Is(err, otp.ErrNotFound) {
		return ErrOTPInvalid
	}
	if err != nil {
		return err
	}
	want, _ := hex.DecodeString(codeHash)
	got, _ := hex.DecodeString(sha256Hex(code))
	if subtle.ConstantTimeCompare(want, got) != 1 {
		return ErrOTPInvalid
	}
	if err := s.repo.Consume(ctx, row.ID, ip); err != nil {
		if errors.Is(err, otp.ErrNotFound) {
			return ErrOTPInvalid
		}
		return err
	}
	return nil
}

// checkNotLocked returns ErrOTPLocked once [email] has collected
// otpMaxFailsPerDay wrong guesses in the trailing 24h.
func (s *OTPService) checkNotLocked(ctx context.Context, email string) error {
	fails, err := s.repo.FailedVerifyCount(ctx, email, otpDailyWindow)
	if err != nil {
		return fmt.Errorf("otp: lockout check: %w", err)
	}
	if fails >= otpMaxFailsPerDay {
		slog.Warn("otp verification locked for email", "email", email, "failures_24h", fails)
		return ErrOTPLocked
	}
	return nil
}

func (s *OTPService) sendEmail(ctx context.Context, email string, purpose otp.Purpose, code string) error {
	if s.mail == nil {
		return errors.New("mailer not configured")
	}
	// The request's Accept-Language (set by middleware.Language) picks
	// the email language, matching the app UI.
	subject, text, html := otp.RenderEmail(purpose, code, middleware.LangFromContext(ctx))
	return s.mail.Send(ctx, mailer.Message{
		To:       email,
		Subject:  subject,
		TextBody: text,
		HTMLBody: html,
	})
}

// generateOTPCode returns a uniformly random 6-digit string zero-padded
// on the left. Uses crypto/rand so an attacker can't bias the distribution.
func generateOTPCode() (string, error) {
	n, err := rand.Int(rand.Reader, big.NewInt(1_000_000))
	if err != nil {
		return "", err
	}
	return fmt.Sprintf("%06d", n.Int64()), nil
}

func sha256Hex(s string) string {
	sum := sha256.Sum256([]byte(s))
	return hex.EncodeToString(sum[:])
}
