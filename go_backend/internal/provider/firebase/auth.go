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

func NewAuthClient(ctx context.Context, credentialsPath string) (*AuthClient, error) {
	var app *firebase.App
	var err error

	if credentialsPath != "" {
		opt := option.WithCredentialsFile(credentialsPath)
		app, err = firebase.NewApp(ctx, nil, opt)
	} else {
		// Use default credentials (for GCP environments)
		app, err = firebase.NewApp(ctx, nil)
	}
	if err != nil {
		return nil, fmt.Errorf("init firebase app: %w", err)
	}

	client, err := app.Auth(ctx)
	if err != nil {
		return nil, fmt.Errorf("init firebase auth: %w", err)
	}

	return &AuthClient{client: client}, nil
}

func (a *AuthClient) VerifyIDToken(ctx context.Context, idToken string) (*Token, error) {
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
