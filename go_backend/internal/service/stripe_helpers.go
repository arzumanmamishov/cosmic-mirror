package service

import (
	"encoding/json"
	"fmt"

	"github.com/stripe/stripe-go/v76"
	"github.com/stripe/stripe-go/v76/ephemeralkey"
)

// newEphemeralKey mints a short-lived key the mobile Payment Sheet uses
// to look up a customer's saved payment methods without ever needing
// our secret API key. The API version below MUST match the version your
// flutter_stripe package was built against — keep it pinned.
const stripeMobileAPIVersion = "2024-06-20"

func newEphemeralKey(customerID string) (string, error) {
	params := &stripe.EphemeralKeyParams{
		Customer:      stripe.String(customerID),
		StripeVersion: stripe.String(stripeMobileAPIVersion),
	}
	key, err := ephemeralkey.New(params)
	if err != nil {
		return "", fmt.Errorf("ephemeral key: %w", err)
	}
	return key.Secret, nil
}

// stripeUnmarshalEventData decodes the resource embedded in a Stripe
// webhook event into the given typed struct. Stripe stuffs the resource
// in `event.Data.Raw` — every typed event handler does the same dance.
func stripeUnmarshalEventData(event stripe.Event, out any) error {
	if err := json.Unmarshal(event.Data.Raw, out); err != nil {
		return fmt.Errorf("decode %q event: %w", event.Type, err)
	}
	return nil
}
