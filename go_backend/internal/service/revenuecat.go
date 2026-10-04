package service

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"cosmic-mirror/internal/domain"

	"github.com/google/uuid"
)

// RevenueCat integration: App Store / Google Play subscriptions bought in
// the mobile app. The app calls Purchases.logIn(<our user UUID>), so the
// RevenueCat app_user_id IS our user id. Webhooks tell us *that* something
// changed; the authoritative state is then fetched from the REST API
// (GET /v1/subscribers/{app_user_id}) when REVENUECAT_SECRET_API_KEY is
// set, otherwise derived from the event payload.

// DefaultRevenueCatEntitlement is the entitlement identifier configured in
// the RevenueCat dashboard that grants premium (the app checks the same id,
// AppConstants.premiumEntitlement).
const DefaultRevenueCatEntitlement = "premium"

const revenueCatAPIBase = "https://api.revenuecat.com/v1"

// revenueCatHandledEvents are the webhook types that can change premium
// state. Everything else (TEST, SUBSCRIBER_ALIAS, INVOICE_ISSUANCE, …) is
// acknowledged and ignored.
var revenueCatHandledEvents = map[string]bool{
	"INITIAL_PURCHASE":      true,
	"RENEWAL":               true,
	"PRODUCT_CHANGE":        true,
	"UNCANCELLATION":        true,
	"NON_RENEWING_PURCHASE": true,
	"CANCELLATION":          true,
	"EXPIRATION":            true,
	"BILLING_ISSUE":         true,
	"SUBSCRIPTION_PAUSED":   true,
	"TRANSFER":              true,
}

// revenueCatEvent is the `event` object of a RevenueCat webhook (API v1).
type revenueCatEvent struct {
	ID                        string   `json:"id"`
	Type                      string   `json:"type"`
	EventTimestampMs          int64    `json:"event_timestamp_ms"`
	AppUserID                 string   `json:"app_user_id"`
	OriginalAppUserID         string   `json:"original_app_user_id"`
	Aliases                   []string `json:"aliases"`
	TransferredFrom           []string `json:"transferred_from"`
	TransferredTo             []string `json:"transferred_to"`
	ProductID                 string   `json:"product_id"`
	NewProductID              string   `json:"new_product_id"`
	EntitlementIDs            []string `json:"entitlement_ids"`
	EntitlementID             *string  `json:"entitlement_id"`
	PeriodType                string   `json:"period_type"`
	PurchasedAtMs             int64    `json:"purchased_at_ms"`
	ExpirationAtMs            int64    `json:"expiration_at_ms"`
	GracePeriodExpirationAtMs int64    `json:"grace_period_expiration_at_ms"`
	Store                     string   `json:"store"`
	Environment               string   `json:"environment"`
}

type revenueCatWebhook struct {
	Event revenueCatEvent `json:"event"`
}

// isRevenueCatAnonymousID reports whether id is an SDK-generated anonymous
// id (a purchase made before logIn) rather than one of our user ids.
func isRevenueCatAnonymousID(id string) bool {
	return strings.HasPrefix(id, "$RCAnonymousID")
}

// userIDFromAppUserID parses a RevenueCat app_user_id as one of our user
// UUIDs. Anonymous and foreign ids are rejected.
func userIDFromAppUserID(id string) (uuid.UUID, bool) {
	if id == "" || isRevenueCatAnonymousID(id) {
		return uuid.Nil, false
	}
	u, err := uuid.Parse(id)
	if err != nil || u == uuid.Nil {
		return uuid.Nil, false
	}
	return u, true
}

// revenueCatTarget is a user an event must be applied to.
type revenueCatTarget struct {
	UserID    uuid.UUID
	AppUserID string
	// LostAccess marks the source side of a TRANSFER: the purchase moved
	// away from this user.
	LostAccess bool
}

// revenueCatTargets resolves which of our users an event concerns. For
// most events that is the first of app_user_id, original_app_user_id and
// aliases that is a (non-anonymous) user UUID. A TRANSFER moves a purchase
// between users, so both sides are returned.
func revenueCatTargets(ev revenueCatEvent) []revenueCatTarget {
	if ev.Type == "TRANSFER" {
		var out []revenueCatTarget
		seen := map[uuid.UUID]bool{}
		add := func(ids []string, lost bool) {
			for _, id := range ids {
				if u, ok := userIDFromAppUserID(id); ok && !seen[u] {
					seen[u] = true
					out = append(out, revenueCatTarget{UserID: u, AppUserID: id, LostAccess: lost})
				}
			}
		}
		add(ev.TransferredTo, false)
		add(ev.TransferredFrom, true)
		return out
	}
	candidates := append([]string{ev.AppUserID, ev.OriginalAppUserID}, ev.Aliases...)
	for _, id := range candidates {
		if u, ok := userIDFromAppUserID(id); ok {
			return []revenueCatTarget{{UserID: u, AppUserID: id}}
		}
	}
	return nil
}

func msToTimePtr(ms int64) *time.Time {
	if ms <= 0 {
		return nil
	}
	t := time.UnixMilli(ms).UTC()
	return &t
}

// grantsEntitlement reports whether the event concerns entitlementID. Old
// payloads without entitlement data are assumed to.
func (ev revenueCatEvent) grantsEntitlement(entitlementID string) bool {
	if len(ev.EntitlementIDs) > 0 {
		for _, id := range ev.EntitlementIDs {
			if id == entitlementID {
				return true
			}
		}
		return false
	}
	if ev.EntitlementID != nil && *ev.EntitlementID != "" {
		return *ev.EntitlementID == entitlementID
	}
	return true
}

// storeStateFromEvent derives the store entitlement from a webhook payload
// alone. It is the fallback used when no REST API key is configured.
// ok=false means the event carries nothing to apply (unhandled type, a
// product that doesn't grant the entitlement, or a TRANSFER recipient —
// whose expiry the payload doesn't include).
func storeStateFromEvent(ev revenueCatEvent, target revenueCatTarget, entitlementID string, now time.Time) (domain.StoreSubscriptionState, bool) {
	asOf := now
	if ev.EventTimestampMs > 0 {
		asOf = time.UnixMilli(ev.EventTimestampMs).UTC()
	}
	st := domain.StoreSubscriptionState{
		AppUserID: target.AppUserID,
		ProductID: ev.ProductID,
		Store:     strings.ToLower(ev.Store),
		AsOf:      asOf,
		Status:    domain.StatusExpired,
	}

	if ev.Type == "TRANSFER" {
		if !target.LostAccess {
			return st, false
		}
		return st, true // purchase moved away: no entitlement left here
	}
	if !revenueCatHandledEvents[ev.Type] || !ev.grantsEntitlement(entitlementID) {
		return st, false
	}

	st.ExpiresAt = msToTimePtr(ev.ExpirationAtMs)
	st.IsTrial = strings.EqualFold(ev.PeriodType, "TRIAL")

	switch ev.Type {
	case "INITIAL_PURCHASE", "RENEWAL", "PRODUCT_CHANGE", "UNCANCELLATION":
		st.WillRenew = true
	case "NON_RENEWING_PURCHASE", "CANCELLATION", "SUBSCRIPTION_PAUSED":
		// Access continues until expiration_at_ms; it just won't renew.
	case "BILLING_ISSUE":
		st.BillingIssue = true
		st.WillRenew = true // the store keeps retrying the charge
		// Access continues through the store's grace period, if any.
		if g := msToTimePtr(ev.GracePeriodExpirationAtMs); g != nil &&
			(st.ExpiresAt == nil || g.After(*st.ExpiresAt)) {
			st.ExpiresAt = g
		}
	case "EXPIRATION":
		st.IsTrial = false
		if st.ExpiresAt == nil || st.ExpiresAt.After(now) {
			// An expired subscription has no future access, whatever the
			// payload says.
			st.ExpiresAt = &now
		}
		return st, true
	}

	if st.ExpiresAt == nil && ev.Type != "NON_RENEWING_PURCHASE" {
		// A subscription event without an expiry is malformed; treating
		// it as lifetime access would be wrong.
		return st, false
	}
	st.Status = storeStatus(st.ExpiresAt, st.IsTrial, now)
	return st, true
}

// storeStatus is active/trialing while the entitlement hasn't expired.
func storeStatus(expiresAt *time.Time, isTrial bool, now time.Time) domain.SubscriptionStatus {
	if expiresAt != nil && !now.Before(*expiresAt) {
		return domain.StatusExpired
	}
	if isTrial {
		return domain.StatusTrialing
	}
	return domain.StatusActive
}

// revenueCatSubscriber is the part of GET /v1/subscribers/{id} we use.
type revenueCatSubscriber struct {
	RequestDateMs int64 `json:"request_date_ms"`
	Subscriber    struct {
		Entitlements map[string]struct {
			ExpiresDate            *time.Time `json:"expires_date"`
			GracePeriodExpiresDate *time.Time `json:"grace_period_expires_date"`
			ProductIdentifier      string     `json:"product_identifier"`
		} `json:"entitlements"`
		Subscriptions map[string]struct {
			ExpiresDate             *time.Time `json:"expires_date"`
			PeriodType              string     `json:"period_type"`
			Store                   string     `json:"store"`
			UnsubscribeDetectedAt   *time.Time `json:"unsubscribe_detected_at"`
			BillingIssuesDetectedAt *time.Time `json:"billing_issues_detected_at"`
			GracePeriodExpiresDate  *time.Time `json:"grace_period_expires_date"`
		} `json:"subscriptions"`
		NonSubscriptions map[string][]struct {
			Store string `json:"store"`
		} `json:"non_subscriptions"`
	} `json:"subscriber"`
}

// storeStateFromSubscriber maps RevenueCat's authoritative subscriber
// record to the store entitlement state.
func storeStateFromSubscriber(resp revenueCatSubscriber, appUserID, entitlementID string, now time.Time) domain.StoreSubscriptionState {
	asOf := now
	if resp.RequestDateMs > 0 {
		asOf = time.UnixMilli(resp.RequestDateMs).UTC()
	}
	st := domain.StoreSubscriptionState{
		AppUserID: appUserID,
		Status:    domain.StatusExpired,
		AsOf:      asOf,
	}

	ent, ok := resp.Subscriber.Entitlements[entitlementID]
	if !ok {
		// Never had the entitlement (or it was revoked, e.g. transferred
		// away). Keep a product id if there is any purchase history so the
		// row records that the user has used the store before.
		for pid := range resp.Subscriber.Subscriptions {
			st.ProductID = pid
			break
		}
		return st
	}

	st.ProductID = ent.ProductIdentifier
	st.ExpiresAt = ent.ExpiresDate
	if g := ent.GracePeriodExpiresDate; g != nil && st.ExpiresAt != nil && g.After(*st.ExpiresAt) {
		st.ExpiresAt = g
	}
	if st.ExpiresAt != nil {
		t := st.ExpiresAt.UTC()
		st.ExpiresAt = &t
	}

	if sub, ok := resp.Subscriber.Subscriptions[ent.ProductIdentifier]; ok {
		st.Store = sub.Store
		st.IsTrial = strings.EqualFold(sub.PeriodType, "trial")
		st.BillingIssue = sub.BillingIssuesDetectedAt != nil
		st.WillRenew = sub.UnsubscribeDetectedAt == nil
		if g := sub.GracePeriodExpiresDate; g != nil && st.ExpiresAt != nil && g.After(*st.ExpiresAt) {
			t := g.UTC()
			st.ExpiresAt = &t
		}
	} else if purchases := resp.Subscriber.NonSubscriptions[ent.ProductIdentifier]; len(purchases) > 0 {
		st.Store = purchases[len(purchases)-1].Store
	}

	st.Status = storeStatus(st.ExpiresAt, st.IsTrial, now)
	if st.Status == domain.StatusExpired {
		st.IsTrial = false
		st.WillRenew = false
	}
	return st
}

// revenueCatClient calls the RevenueCat REST API with the secret key.
type revenueCatClient struct {
	apiKey  string
	baseURL string
	http    *http.Client
}

func newRevenueCatClient(apiKey string) *revenueCatClient {
	return &revenueCatClient{
		apiKey:  apiKey,
		baseURL: revenueCatAPIBase,
		http:    &http.Client{Timeout: 10 * time.Second},
	}
}

// subscriber fetches GET /v1/subscribers/{appUserID}.
func (c *revenueCatClient) subscriber(ctx context.Context, appUserID string) (revenueCatSubscriber, error) {
	var out revenueCatSubscriber
	req, err := http.NewRequestWithContext(ctx, http.MethodGet,
		c.baseURL+"/subscribers/"+url.PathEscape(appUserID), nil)
	if err != nil {
		return out, err
	}
	req.Header.Set("Authorization", "Bearer "+c.apiKey)
	req.Header.Set("Accept", "application/json")
	resp, err := c.http.Do(req)
	if err != nil {
		return out, fmt.Errorf("revenuecat: get subscriber: %w", err)
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return out, fmt.Errorf("revenuecat: read subscriber: %w", err)
	}
	if resp.StatusCode != http.StatusOK {
		return out, fmt.Errorf("revenuecat: get subscriber: HTTP %d", resp.StatusCode)
	}
	if err := json.Unmarshal(body, &out); err != nil {
		return out, fmt.Errorf("revenuecat: decode subscriber: %w", err)
	}
	return out, nil
}
