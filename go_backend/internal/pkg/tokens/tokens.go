// Package tokens signs and verifies the local-auth access + refresh tokens.
//
//   - Access: short-lived HS256 JWT, verified stateless in middleware.
//   - Refresh: opaque base64 string; its sha256 lives in refresh_tokens.
//
// The stateless access token skips a DB roundtrip on every request; the
// stateful refresh token lets us revoke sessions.
package tokens

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v4"
	"github.com/google/uuid"
)

// Claims is what the app can trust on every request. Keep this deliberately
// narrow — anything richer (subscription status, avatar, name) belongs in the
// DB row and is looked up by UserID.
type Claims struct {
	UserID uuid.UUID `json:"uid"`
	jwt.RegisteredClaims
}

// Signer wraps the HS256 secret + TTL config.
type Signer struct {
	secret     []byte
	accessTTL  time.Duration
	refreshTTL time.Duration
	issuer     string
}

// NewSigner constructs a Signer. Panics if secret is empty — the caller
// (config.Load) is expected to have already validated it.
func NewSigner(secret string, accessTTLMinutes, refreshTTLDays int) *Signer {
	if secret == "" {
		panic("tokens.NewSigner: empty secret")
	}
	return &Signer{
		secret:     []byte(secret),
		accessTTL:  time.Duration(accessTTLMinutes) * time.Minute,
		refreshTTL: time.Duration(refreshTTLDays) * 24 * time.Hour,
		issuer:     "cosmic-mirror",
	}
}

// IssueAccess builds and signs a JWT for the given user. Returns the signed
// string and its exact expiry so the client can decide when to refresh.
func (s *Signer) IssueAccess(userID uuid.UUID) (string, time.Time, error) {
	now := time.Now().UTC()
	exp := now.Add(s.accessTTL)
	claims := Claims{
		UserID: userID,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    s.issuer,
			Subject:   userID.String(),
			IssuedAt:  jwt.NewNumericDate(now),
			NotBefore: jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(exp),
			ID:        uuid.NewString(),
		},
	}
	tok := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, err := tok.SignedString(s.secret)
	if err != nil {
		return "", time.Time{}, fmt.Errorf("tokens: sign access: %w", err)
	}
	return signed, exp, nil
}

// ErrInvalidToken is what verify returns for any parse / signature / claims
// failure — deliberately one sentinel so the middleware can't accidentally
// leak the specific reason.
var ErrInvalidToken = errors.New("tokens: invalid token")

// ParseAccess verifies the signature + exp/nbf and returns the claims. iss
// is checked explicitly since jwt/v4 doesn't expose an issuer parse option.
func (s *Signer) ParseAccess(raw string) (*Claims, error) {
	claims := &Claims{}
	tok, err := jwt.ParseWithClaims(raw, claims, func(t *jwt.Token) (any, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, ErrInvalidToken
		}
		return s.secret, nil
	}, jwt.WithValidMethods([]string{"HS256"}))
	if err != nil || !tok.Valid {
		return nil, ErrInvalidToken
	}
	if claims.Issuer != s.issuer {
		return nil, ErrInvalidToken
	}
	return claims, nil
}

// GenerateRefresh returns a new opaque refresh token (URL-safe base64 of 32
// random bytes) and its expiry. The caller is responsible for storing its
// sha256 in refresh_tokens.
func (s *Signer) GenerateRefresh() (plain string, expiresAt time.Time, err error) {
	b := make([]byte, 32)
	if _, err = rand.Read(b); err != nil {
		return "", time.Time{}, fmt.Errorf("tokens: random: %w", err)
	}
	return base64.RawURLEncoding.EncodeToString(b), time.Now().UTC().Add(s.refreshTTL), nil
}

// HashRefresh returns the sha256 hex of a plaintext refresh token, ready to
// be stored / compared against `refresh_tokens.token_hash`.
func HashRefresh(plain string) string {
	sum := sha256.Sum256([]byte(plain))
	return hex.EncodeToString(sum[:])
}

// AccessTTL / RefreshTTL expose the configured durations for callers that
// need them (e.g. rate-limit windows, telemetry).
func (s *Signer) AccessTTL() time.Duration  { return s.accessTTL }
func (s *Signer) RefreshTTL() time.Duration { return s.refreshTTL }
