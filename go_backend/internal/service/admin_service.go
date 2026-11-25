package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/repository"
	"cosmic-mirror/internal/repository/postgres"

	"github.com/google/uuid"
)

// AdminService powers the web admin panel (/admin): dashboard statistics,
// customer lookup and account actions, the Stripe settings and the audit
// log. Access control (ADMIN_EMAILS) is enforced by the router before any
// of this runs; every state-changing call is written to the audit log.
type AdminService struct {
	repo          *postgres.AdminRepository
	users         *UserService
	refreshTokens repository.RefreshTokenRepository
	settings      *SettingsService
	stripe        *StripeService
	adminEmails   []string
	moderation    AdminModerationInfo
}

// AdminModerationInfo is the (env-configured) moderation setup shown on
// the settings page.
type AdminModerationInfo struct {
	EmailSet          bool `json:"email_set"`
	AutoHideThreshold int  `json:"autohide_threshold"`
}

// AdminActor is the admin performing an action.
type AdminActor struct {
	ID    uuid.UUID
	Email string
}

func NewAdminService(
	repo *postgres.AdminRepository,
	users *UserService,
	refreshTokens repository.RefreshTokenRepository,
	settings *SettingsService,
	stripe *StripeService,
	adminEmails []string,
	moderation AdminModerationInfo,
) *AdminService {
	return &AdminService{
		repo: repo, users: users, refreshTokens: refreshTokens,
		settings: settings, stripe: stripe, adminEmails: adminEmails,
		moderation: moderation,
	}
}

// ErrProtectedAccount: admins can't ban or delete their own account or
// another admin's from the panel (it would lock the team out).
var ErrProtectedAccount = fmt.Errorf("%w: admin accounts can't be banned or deleted from the admin panel", domain.ErrValidation)

func (s *AdminService) isAdminEmail(email string) bool {
	e := strings.ToLower(strings.TrimSpace(email))
	for _, a := range s.adminEmails {
		if e != "" && strings.ToLower(strings.TrimSpace(a)) == e {
			return true
		}
	}
	return false
}

// ===== Dashboard =====

func (s *AdminService) Stats(ctx context.Context) (*domain.AdminStats, error) {
	return s.repo.Stats(ctx)
}

// ===== Customers =====

// ListUsers returns one page of customers and the total matching.
func (s *AdminService) ListUsers(ctx context.Context, q domain.AdminUserQuery) ([]domain.AdminUserSummary, int, error) {
	if q.Filter == "" {
		q.Filter = domain.AdminUserFilterAll
	}
	if !domain.ValidAdminUserFilter(q.Filter) {
		return nil, 0, fmt.Errorf("%w: unknown filter %q", domain.ErrValidation, q.Filter)
	}
	if len(q.Search) > 200 {
		q.Search = q.Search[:200]
	}
	rows, total, err := s.repo.ListUsers(ctx, q)
	if err != nil {
		return nil, 0, err
	}
	out := make([]domain.AdminUserSummary, len(rows))
	for i, r := range rows {
		out[i] = r.Summary()
	}
	return out, total, nil
}

// GetUser returns the customer page, or ErrUserNotFound.
func (s *AdminService) GetUser(ctx context.Context, id uuid.UUID) (*domain.AdminUserDetail, error) {
	row, err := s.repo.GetUser(ctx, id)
	if err != nil {
		return nil, err
	}
	if row == nil {
		return nil, ErrUserNotFound
	}
	activity, err := s.repo.UserActivity(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("user activity: %w", err)
	}
	return &domain.AdminUserDetail{
		AdminUserSummary: row.Summary(),
		EmailVerifiedAt:  row.EmailVerifiedAt,
		IsAdmin:          s.isAdminEmail(row.Email),
		Subscription:     row.SubscriptionDetail(),
		Activity:         *activity,
		StripeMode:       s.stripe.Status(ctx).Mode,
	}, nil
}

// loadTarget loads a user an admin is about to act on, refusing admins.
func (s *AdminService) loadTarget(ctx context.Context, actor AdminActor, id uuid.UUID) (*domain.AdminUserRow, error) {
	if id == actor.ID {
		return nil, ErrProtectedAccount
	}
	row, err := s.repo.GetUser(ctx, id)
	if err != nil {
		return nil, err
	}
	if row == nil {
		return nil, ErrUserNotFound
	}
	if s.isAdminEmail(row.Email) {
		return nil, ErrProtectedAccount
	}
	return row, nil
}

// BanUser suspends an account: every request gets 403 account_banned,
// their sessions are revoked and their community content is hidden.
func (s *AdminService) BanUser(ctx context.Context, actor AdminActor, id uuid.UUID, note string) error {
	row, err := s.loadTarget(ctx, actor, id)
	if err != nil {
		return err
	}
	ok, err := s.repo.SetBanned(ctx, id, true)
	if err != nil {
		return err
	}
	if !ok {
		return ErrUserNotFound
	}
	// Access tokens die at the auth middleware's banned_at check; revoke
	// refresh tokens too so the app can't mint new ones.
	if err := s.refreshTokens.RevokeAllForUser(ctx, id); err != nil {
		slog.Error("admin: revoke sessions of banned user", "error", err, "user_id", id)
	}
	s.Record(ctx, actor, domain.AuditUserBan, "user", id.String(),
		map[string]any{"email": row.Email, "note": strings.TrimSpace(note)})
	return nil
}

// UnbanUser lifts a ban. The user signs in again to get a new session.
func (s *AdminService) UnbanUser(ctx context.Context, actor AdminActor, id uuid.UUID, note string) error {
	row, err := s.repo.GetUser(ctx, id)
	if err != nil {
		return err
	}
	if row == nil {
		return ErrUserNotFound
	}
	if _, err := s.repo.SetBanned(ctx, id, false); err != nil {
		return err
	}
	s.Record(ctx, actor, domain.AuditUserUnban, "user", id.String(),
		map[string]any{"email": row.Email, "note": strings.TrimSpace(note)})
	return nil
}

// DeleteUser deletes an account exactly like the in-app "Delete account":
// cancels a web (Stripe) subscription immediately, signs out every
// session and soft-deletes the user (purged after 30 days).
// [confirmEmail] must match the account's e-mail, so a stray click can't
// delete the wrong customer.
func (s *AdminService) DeleteUser(ctx context.Context, actor AdminActor, id uuid.UUID, confirmEmail, note string) error {
	row, err := s.loadTarget(ctx, actor, id)
	if err != nil {
		return err
	}
	if !strings.EqualFold(strings.TrimSpace(confirmEmail), strings.TrimSpace(row.Email)) {
		return fmt.Errorf("%w: type the customer's e-mail address exactly to confirm", domain.ErrValidation)
	}
	premium := domain.PremiumSummary(row.Subscription())
	if err := s.users.DeleteUser(ctx, id); err != nil {
		return err
	}
	s.Record(ctx, actor, domain.AuditUserDelete, "user", id.String(), map[string]any{
		"email":           row.Email,
		"premium_channel": premium.Channel,
		"note":            strings.TrimSpace(note),
	})
	return nil
}

// ===== Settings =====

// AdminStripeSettings is the Stripe section of the settings page.
type AdminStripeSettings struct {
	Status    StripeStatus                  `json:"status"`
	Effective domain.StripeSettings         `json:"effective"`
	Defaults  domain.StripeSettings         `json:"defaults"`
	Override  domain.StripeSettingsOverride `json:"override"`
	UpdatedAt *time.Time                    `json:"updated_at,omitempty"`
	UpdatedBy string                        `json:"updated_by,omitempty"`
}

// AdminSettings is the settings page payload.
type AdminSettings struct {
	Stripe     AdminStripeSettings `json:"stripe"`
	Admins     []string            `json:"admins"`
	Moderation AdminModerationInfo `json:"moderation"`
}

// Settings returns the settings page.
func (s *AdminService) Settings(ctx context.Context) (*AdminSettings, error) {
	st, err := s.stripeSettings(ctx)
	if err != nil {
		return nil, err
	}
	admins := append([]string{}, s.adminEmails...)
	return &AdminSettings{Stripe: *st, Admins: admins, Moderation: s.moderation}, nil
}

func (s *AdminService) stripeSettings(ctx context.Context) (*AdminStripeSettings, error) {
	override, row, err := s.settings.StripeOverride(ctx)
	if err != nil {
		return nil, err
	}
	defaults := s.settings.StripeDefaults()
	out := &AdminStripeSettings{
		Status:    s.stripe.Status(ctx),
		Effective: override.Apply(defaults),
		Defaults:  defaults,
		Override:  override,
	}
	if row != nil {
		t := row.UpdatedAt
		out.UpdatedAt = &t
		out.UpdatedBy = row.UpdatedBy
	}
	return out, nil
}

// UpdateStripeSettings checks the new price IDs with Stripe (they must be
// active recurring prices billing monthly / yearly, in this key's mode),
// then saves them. New web checkouts use them right away; existing
// subscribers keep the price they signed up with.
func (s *AdminService) UpdateStripeSettings(ctx context.Context, actor AdminActor, in domain.StripeSettingsOverride) (*AdminStripeSettings, error) {
	in.Normalize()
	if err := in.Validate(); err != nil {
		return nil, err
	}
	before, _, err := s.settings.StripeOverride(ctx)
	if err != nil {
		return nil, err
	}
	for _, p := range []struct {
		plan domain.PlanType
		id   string
	}{{domain.PlanMonthly, in.PriceMonthly}, {domain.PlanYearly, in.PriceYearly}} {
		if err := s.checkStripePrice(ctx, p.plan, p.id); err != nil {
			return nil, err
		}
	}
	if err := s.settings.SaveStripeOverride(ctx, in, actor.ID); err != nil {
		return nil, err
	}
	s.Record(ctx, actor, domain.AuditStripeSettings, "setting", domain.SettingKeyStripe,
		map[string]any{"before": before, "after": in})
	return s.stripeSettings(ctx)
}

// checkStripePrice verifies a price ID with Stripe. Empty = server default.
func (s *AdminService) checkStripePrice(ctx context.Context, plan domain.PlanType, id string) error {
	if id == "" {
		return nil
	}
	p, err := s.stripe.GetPrice(ctx, id)
	if errors.Is(err, ErrStripeNotConfigured) {
		return fmt.Errorf("%w: Stripe isn't connected on this server (STRIPE_SECRET_KEY is empty), so the %s price can't be checked. Set the Stripe keys first", domain.ErrValidation, plan)
	}
	if err != nil {
		slog.Error("admin: check stripe price", "error", err, "price_id", id)
		return fmt.Errorf("%w: couldn't reach Stripe to check the %s price. Try again in a minute", domain.ErrValidation, plan)
	}
	if p == nil {
		mode := s.stripe.Status(ctx).Mode
		return fmt.Errorf("%w: Stripe has no price %s in %s mode. Check that you copied a %s-mode price", domain.ErrValidation, id, mode, mode)
	}
	return p.ValidateForPlan(plan)
}

// ListStripePrices returns the active recurring prices for the picker.
func (s *AdminService) ListStripePrices(ctx context.Context) ([]domain.StripePrice, error) {
	return s.stripe.ListPrices(ctx)
}

// ===== Audit log =====

// ListAudit returns audit entries, newest first; only those about
// [targetID] when it isn't empty.
func (s *AdminService) ListAudit(ctx context.Context, targetID string, limit, offset int) ([]domain.AuditEntry, error) {
	return s.repo.ListAudit(ctx, strings.TrimSpace(targetID), limit, offset)
}

// Record writes an audit entry. The action has already happened, so a
// failure here is logged, not returned.
func (s *AdminService) Record(ctx context.Context, actor AdminActor, action, targetType, targetID string, details map[string]any) {
	body := []byte("{}")
	if len(details) > 0 {
		b, err := json.Marshal(details)
		if err != nil {
			slog.Error("admin audit: encode details", "error", err, "action", action)
		} else {
			body = b
		}
	}
	e := &domain.AuditEntry{
		ID:          uuid.New(),
		AdminEmail:  actor.Email,
		Action:      action,
		TargetType:  targetType,
		TargetID:    targetID,
		DetailsJSON: string(body),
	}
	if actor.ID != uuid.Nil {
		id := actor.ID
		e.AdminID = &id
	}
	// Detach from the request: the action is done even if the client
	// hangs up now.
	wctx, cancel := context.WithTimeout(context.WithoutCancel(ctx), 5*time.Second)
	defer cancel()
	if err := s.repo.InsertAudit(wctx, e); err != nil {
		slog.Error("admin audit: write failed", "error", err, "action", action,
			"admin", actor.Email, "target_type", targetType, "target_id", targetID)
	}
	slog.Info("admin action", "action", action, "admin", actor.Email,
		"target_type", targetType, "target_id", targetID)
}
