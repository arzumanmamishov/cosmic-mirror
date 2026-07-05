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

	"cosmic-mirror/internal/otp"
	"cosmic-mirror/internal/pkg/mailer"
)

// OTP tuning. Short TTL keeps stolen inboxes fresh; max_attempts caps
// online guessing; rate limits stop enumeration abuse.
const (
	otpCodeTTL         = 10 * time.Minute
	otpMaxAttempts     = 5
	otpPerEmailWindow  = 10 * time.Minute
	otpPerEmailMax     = 3
)

// ErrOTPInvalid is the sentinel returned for any verify failure — bad
// hash, expired, exhausted attempts, unknown row. Callers must map to a
// single generic "invalid or expired code" HTTP error so timing signals
// don't leak the specific case.
var ErrOTPInvalid = errors.New("otp: invalid or expired code")

// ErrOTPRateLimited is returned when the caller has requested too many
// codes for the same email within the sliding window.
var ErrOTPRateLimited = errors.New("otp: too many code requests — try again later")

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
	// Rate limit per email (DB-backed; Redis fast path could be layered
	// later without changing the signature).
	n, err := s.repo.RecentCountForEmail(ctx, email, otpPerEmailWindow)
	if err == nil && n >= otpPerEmailMax {
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
	row, err := s.repo.FindActive(ctx, email, purpose)
	if errors.Is(err, otp.ErrNotFound) {
		return ErrOTPInvalid
	}
	if err != nil {
		return err
	}
	if time.Now().After(row.ExpiresAt) {
		return ErrOTPInvalid
	}
	if row.Attempts >= row.MaxAttempts {
		return ErrOTPInvalid
	}
	want, _ := hex.DecodeString(row.CodeHash)
	got, _ := hex.DecodeString(sha256Hex(code))
	if subtle.ConstantTimeCompare(want, got) != 1 {
		_ = s.repo.IncrementAttempts(ctx, row.ID)
		return ErrOTPInvalid
	}
	return s.repo.Consume(ctx, row.ID, ip)
}

func (s *OTPService) sendEmail(ctx context.Context, email string, purpose otp.Purpose, code string) error {
	if s.mail == nil {
		return errors.New("mailer not configured")
	}
	subject, text, html := otp.RenderEmail(purpose, code)
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
