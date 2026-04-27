package firebase

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"strings"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"google.golang.org/api/option"
)

type AuthClient struct {
	client *auth.Client
}

type Token struct {
	UID   string
	Email string
}

// NewAuthClient creates a Firebase auth client.
// If credentialsPath is empty or the file doesn't exist, it returns a dev-mode
// client that accepts any token (for local development only).
func NewAuthClient(ctx context.Context, credentialsPath string) (*AuthClient, error) {
	if credentialsPath == "" {
		fmt.Println("⚠ Firebase: no credentials path set, running in DEV mode (auth bypass)")
		return &AuthClient{client: nil}, nil
	}

	opt := option.WithCredentialsFile(credentialsPath)
	app, err := firebase.NewApp(ctx, nil, opt)
	if err != nil {
		fmt.Printf("⚠ Firebase: could not init app (%v), running in DEV mode (auth bypass)\n", err)
		return &AuthClient{client: nil}, nil
	}

	client, err := app.Auth(ctx)
	if err != nil {
		fmt.Printf("⚠ Firebase: could not init auth (%v), running in DEV mode (auth bypass)\n", err)
		return &AuthClient{client: nil}, nil
	}

	return &AuthClient{client: client}, nil
}

func (a *AuthClient) VerifyIDToken(ctx context.Context, idToken string) (*Token, error) {
	// Dev mode: try to decode the Firebase JWT to extract the real UID
	if a.client == nil {
		uid, email := extractFromJWT(idToken)
		return &Token{
			UID:   uid,
			Email: email,
		}, nil
	}

	token, err := a.client.VerifyIDToken(ctx, idToken)
	if err != nil {
		return nil, fmt.Errorf("verify token: %w", err)
	}

	email, _ := token.Claims["email"].(string)

	return &Token{
		UID:   token.UID,
		Email: email,
	}, nil
}

// extractFromJWT decodes a Firebase ID token (JWT) without verification
// to extract the user_id and email claims. Used in dev mode only.
func extractFromJWT(token string) (uid, email string) {
	parts := strings.Split(token, ".")
	if len(parts) != 3 {
		return token, ""
	}
	// Decode the payload (part 2)
	payload := parts[1]
	// Add padding if needed
	switch len(payload) % 4 {
	case 2:
		payload += "=="
	case 3:
		payload += "="
	}
	decoded, err := base64.URLEncoding.DecodeString(payload)
	if err != nil {
		return token, ""
	}
	var claims struct {
		Sub   string `json:"sub"`
		UID   string `json:"user_id"`
		Email string `json:"email"`
	}
	if err := json.Unmarshal(decoded, &claims); err != nil {
		return token, ""
	}
	uid = claims.Sub
	if uid == "" {
		uid = claims.UID
	}
	if uid == "" {
		uid = token
	}
	return uid, claims.Email
}
