package firebase

import (
	"context"
	"fmt"

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
	// Dev mode: accept token as-is (the token value is treated as the UID)
	if a.client == nil {
		return &Token{
			UID:   idToken,
			Email: "dev@cosmicmirror.app",
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
