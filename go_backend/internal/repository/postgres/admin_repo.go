package postgres

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"cosmic-mirror/internal/domain"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

// AdminRepository backs the admin panel: dashboard statistics, the
// customer list, runtime settings and the audit log (migration 016).
type AdminRepository struct {
	db *sqlx.DB
}

func NewAdminRepository(db *sqlx.DB) *AdminRepository {
	return &AdminRepository{db: db}
}

// SQL predicates on a subscriptions row aliased "s" — the SQL form of
// domain.Subscription.StorePremium / StripePremium. NULL (not false) when
// the user has no row, so wrap them in COALESCE where that matters.
const (
	sqlStoreLive  = `(s.rc_status IN ('active', 'trialing') AND (s.rc_expires_at IS NULL OR s.rc_expires_at > NOW()))`
	sqlStripeLive = `(s.status IN ('active', 'trialing') AND (s.expires_at IS NULL OR s.expires_at > NOW()))`
	// sqlYearlyProduct mirrors domain.PlanTypeForProduct.
	sqlYearlyProduct = `(s.rc_product_id ~* '(year|annual|p1y|12m)')`
)

// ===== Dashboard =====

// statsWindowDays is the length of the daily series on the dashboard.
const statsWindowDays = 30

// Stats computes the dashboard numbers. Each block is one round trip.
func (r *AdminRepository) Stats(ctx context.Context) (*domain.AdminStats, error) {
	out := &domain.AdminStats{GeneratedAt: time.Now().UTC()}

	if err := r.db.GetContext(ctx, &out.Users,
		`SELECT u.*, a.* FROM
		   (SELECT COUNT(*) AS total,
		           COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '1 day')   AS new_1d,
		           COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '7 days')  AS new_7d,
		           COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days') AS new_30d,
		           COUNT(*) FILTER (WHERE banned_at IS NOT NULL)                    AS banned,
		           COUNT(*) FILTER (WHERE EXISTS (
		               SELECT 1 FROM birth_profiles bp WHERE bp.user_id = users.id)) AS onboarded
		      FROM users WHERE deleted_at IS NULL) u,
		   (SELECT COUNT(DISTINCT rt.user_id) FILTER (WHERE rt.created_at >= NOW() - INTERVAL '1 day')  AS active_1d,
		           COUNT(DISTINCT rt.user_id) FILTER (WHERE rt.created_at >= NOW() - INTERVAL '7 days') AS active_7d,
		           COUNT(DISTINCT rt.user_id)                                                           AS active_30d
		      FROM refresh_tokens rt
		      JOIN users ru ON ru.id = rt.user_id AND ru.deleted_at IS NULL
		     WHERE rt.created_at >= NOW() - INTERVAL '30 days') a`,
	); err != nil {
		return nil, fmt.Errorf("user stats: %w", err)
	}

	// Each user once, under the source that grants access (store first,
	// like Subscription.Entitlement).
	if err := r.db.GetContext(ctx, &out.Premium,
		`WITH p AS (
		   SELECT s.*,
		          COALESCE(`+sqlStoreLive+`, FALSE)  AS store_live,
		          COALESCE(`+sqlStripeLive+`, FALSE) AS stripe_live,
		          COALESCE(`+sqlYearlyProduct+`, FALSE) AS store_yearly
		     FROM subscriptions s
		     JOIN users u ON u.id = s.user_id AND u.deleted_at IS NULL
		 )
		 SELECT
		   COUNT(*) FILTER (WHERE store_live OR stripe_live)                                   AS total,
		   COUNT(*) FILTER (WHERE stripe_live AND NOT store_live)                              AS stripe,
		   COUNT(*) FILTER (WHERE store_live AND LOWER(rc_store) = 'app_store')                AS app_store,
		   COUNT(*) FILTER (WHERE store_live AND LOWER(rc_store) = 'play_store')               AS play_store,
		   COUNT(*) FILTER (WHERE store_live AND LOWER(rc_store) NOT IN ('app_store', 'play_store')) AS other_store,
		   COUNT(*) FILTER (WHERE (store_live AND store_yearly)
		                       OR (stripe_live AND NOT store_live AND plan_type = 'yearly'))   AS yearly,
		   COUNT(*) FILTER (WHERE (store_live AND (rc_is_trial OR rc_status = 'trialing'))
		                       OR (stripe_live AND NOT store_live AND status = 'trialing'))    AS trialing,
		   COUNT(*) FILTER (WHERE (store_live AND NOT rc_will_renew)
		                       OR (stripe_live AND NOT store_live AND cancel_at_period_end))   AS cancelling,
		   COUNT(*) FILTER (WHERE store_live AND rc_billing_issue)                             AS billing_issues
		 FROM p`,
	); err != nil {
		return nil, fmt.Errorf("premium stats: %w", err)
	}
	out.Premium.Monthly = out.Premium.Total - out.Premium.Yearly

	if err := r.db.GetContext(ctx, &out.Content,
		`SELECT
		   (SELECT COUNT(*) FROM spaces)                                                          AS spaces,
		   (SELECT COUNT(*) FROM posts)                                                           AS posts,
		   (SELECT COUNT(*) FROM posts WHERE created_at >= NOW() - INTERVAL '7 days')             AS posts_7d,
		   (SELECT COUNT(*) FROM comments)                                                        AS comments,
		   (SELECT COUNT(*) FROM comments WHERE created_at >= NOW() - INTERVAL '7 days')          AS comments_7d,
		   (SELECT COUNT(*) FROM chat_messages
		     WHERE role = 'user' AND created_at >= NOW() - INTERVAL '7 days')                     AS ai_messages_7d,
		   (SELECT COUNT(*) FROM journal_entries WHERE created_at >= NOW() - INTERVAL '7 days')   AS journal_entries_7d,
		   (SELECT COUNT(*) FROM compatibility_reports
		     WHERE created_at >= NOW() - INTERVAL '7 days')                                       AS compatibility_reports_7d,
		   (SELECT COUNT(*) FROM content_reports WHERE status = 'open')                           AS open_reports`,
	); err != nil {
		return nil, fmt.Errorf("content stats: %w", err)
	}

	// Daily series over the last statsWindowDays days, oldest first, with
	// zero-filled days. Sign-ups include accounts deleted since (they did
	// sign up that day).
	const days = `WITH days AS (
		   SELECT generate_series((CURRENT_DATE - ($1::int - 1))::timestamptz,
		                          CURRENT_DATE::timestamptz, INTERVAL '1 day') AS day)`
	out.Signups = []domain.DayCount{}
	if err := r.db.SelectContext(ctx, &out.Signups, days+`
		 SELECT to_char(d.day, 'YYYY-MM-DD') AS day, COUNT(u.id)::int AS count
		   FROM days d
		   LEFT JOIN users u ON u.created_at >= d.day AND u.created_at < d.day + INTERVAL '1 day'
		  GROUP BY d.day ORDER BY d.day`, statsWindowDays,
	); err != nil {
		return nil, fmt.Errorf("signups series: %w", err)
	}
	out.ActiveUsers = []domain.DayCount{}
	if err := r.db.SelectContext(ctx, &out.ActiveUsers, days+`
		 SELECT to_char(d.day, 'YYYY-MM-DD') AS day, COUNT(DISTINCT rt.user_id)::int AS count
		   FROM days d
		   LEFT JOIN refresh_tokens rt ON rt.created_at >= d.day AND rt.created_at < d.day + INTERVAL '1 day'
		  GROUP BY d.day ORDER BY d.day`, statsWindowDays,
	); err != nil {
		return nil, fmt.Errorf("active users series: %w", err)
	}
	return out, nil
}

// ===== Customers =====

// adminUserSelect reads a user plus their subscriptions row ("s", LEFT
// JOINed — hence the COALESCEs) into domain.AdminUserRow.
const adminUserSelect = `SELECT
	u.id, u.email::text AS email, u.name, u.avatar_url, u.created_at,
	u.last_login_at, u.email_verified_at, u.banned_at,
	(SELECT MAX(rt.created_at) FROM refresh_tokens rt WHERE rt.user_id = u.id) AS last_seen_at,
	(s.id IS NOT NULL)                          AS has_subscription,
	COALESCE(s.status, '')                      AS status,
	s.expires_at, s.current_period_end,
	COALESCE(s.plan_type, '')                   AS plan_type,
	COALESCE(s.cancel_at_period_end, FALSE)     AS cancel_at_period_end,
	s.trial_end_at, s.stripe_customer_id, s.stripe_subscription_id, s.price_id,
	COALESCE(s.revenuecat_id, '')               AS revenuecat_id,
	COALESCE(s.rc_status, '')                   AS rc_status,
	COALESCE(s.rc_product_id, '')               AS rc_product_id,
	COALESCE(s.rc_store, '')                    AS rc_store,
	s.rc_expires_at,
	COALESCE(s.rc_is_trial, FALSE)              AS rc_is_trial,
	COALESCE(s.rc_will_renew, FALSE)            AS rc_will_renew,
	COALESCE(s.rc_billing_issue, FALSE)         AS rc_billing_issue,
	s.rc_as_of,
	COALESCE(s.trial_consumed, FALSE)           AS trial_consumed
	FROM users u
	LEFT JOIN subscriptions s ON s.user_id = u.id`

// adminUserFilterSQL maps a customer-list filter to its WHERE predicate.
var adminUserFilterSQL = map[string]string{
	domain.AdminUserFilterAll:     "",
	domain.AdminUserFilterPremium: `COALESCE(` + sqlStoreLive + ` OR ` + sqlStripeLive + `, FALSE)`,
	domain.AdminUserFilterFree:    `NOT COALESCE(` + sqlStoreLive + ` OR ` + sqlStripeLive + `, FALSE)`,
	domain.AdminUserFilterTrial: `COALESCE((` + sqlStoreLive + ` AND (s.rc_is_trial OR s.rc_status = 'trialing'))
		OR (` + sqlStripeLive + ` AND s.status = 'trialing'), FALSE)`,
	domain.AdminUserFilterWeb:       `COALESCE(` + sqlStripeLive + `, FALSE)`,
	domain.AdminUserFilterAppStore:  `COALESCE(` + sqlStoreLive + ` AND LOWER(s.rc_store) = 'app_store', FALSE)`,
	domain.AdminUserFilterPlayStore: `COALESCE(` + sqlStoreLive + ` AND LOWER(s.rc_store) = 'play_store', FALSE)`,
	domain.AdminUserFilterBanned:    `u.banned_at IS NOT NULL`,
}

// escapeLike escapes the LIKE wildcards in a user-typed search term.
func escapeLike(s string) string {
	return strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`).Replace(s)
}

// ListUsers returns one page of non-deleted users, newest first, and the
// total number matching the query.
func (r *AdminRepository) ListUsers(ctx context.Context, q domain.AdminUserQuery) ([]domain.AdminUserRow, int, error) {
	filter, ok := adminUserFilterSQL[q.Filter]
	if !ok {
		return nil, 0, fmt.Errorf("%w: unknown filter %q", domain.ErrValidation, q.Filter)
	}
	where := []string{"u.deleted_at IS NULL"}
	args := []any{}
	if search := strings.TrimSpace(q.Search); search != "" {
		args = append(args, "%"+escapeLike(search)+"%", search)
		where = append(where, fmt.Sprintf(
			`(u.email::text ILIKE $%[1]d OR u.name ILIKE $%[1]d OR u.id::text = $%[2]d OR s.stripe_customer_id = $%[2]d)`,
			len(args)-1, len(args)))
	}
	if filter != "" {
		where = append(where, filter)
	}
	cond := " WHERE " + strings.Join(where, " AND ")

	var total int
	if err := r.db.GetContext(ctx, &total,
		`SELECT COUNT(*) FROM users u LEFT JOIN subscriptions s ON s.user_id = u.id`+cond, args...,
	); err != nil {
		return nil, 0, fmt.Errorf("count users: %w", err)
	}

	rows := []domain.AdminUserRow{}
	args = append(args, q.Limit, q.Offset)
	if err := r.db.SelectContext(ctx, &rows,
		adminUserSelect+cond+fmt.Sprintf(` ORDER BY u.created_at DESC, u.id LIMIT $%d OFFSET $%d`, len(args)-1, len(args)),
		args...,
	); err != nil {
		return nil, 0, fmt.Errorf("list users: %w", err)
	}
	return rows, total, nil
}

// GetUser loads one non-deleted user with their subscription. Nil when
// there's no such user.
func (r *AdminRepository) GetUser(ctx context.Context, id uuid.UUID) (*domain.AdminUserRow, error) {
	var row domain.AdminUserRow
	err := r.db.GetContext(ctx, &row, adminUserSelect+` WHERE u.id = $1 AND u.deleted_at IS NULL`, id)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &row, nil
}

// UserActivity counts what the user has done in the app.
func (r *AdminRepository) UserActivity(ctx context.Context, id uuid.UUID) (*domain.AdminUserActivity, error) {
	var a domain.AdminUserActivity
	err := r.db.GetContext(ctx, &a,
		`WITH owned AS (
		   SELECT 'post' AS target_type, id FROM posts WHERE author_id = $1
		   UNION ALL
		   SELECT 'comment', id FROM comments WHERE author_id = $1
		   UNION ALL
		   SELECT 'user', $1::uuid
		 )
		 SELECT
		   EXISTS (SELECT 1 FROM birth_profiles WHERE user_id = $1)                AS onboarded,
		   (SELECT COUNT(*) FROM refresh_tokens
		     WHERE user_id = $1 AND revoked_at IS NULL AND expires_at > NOW())     AS active_sessions,
		   (SELECT COUNT(*) FROM chat_threads WHERE user_id = $1)                  AS ai_threads,
		   (SELECT COUNT(*) FROM chat_messages m JOIN chat_threads t ON t.id = m.thread_id
		     WHERE t.user_id = $1 AND m.role = 'user')                             AS ai_messages,
		   (SELECT COUNT(*) FROM journal_entries WHERE user_id = $1)               AS journal_entries,
		   (SELECT COUNT(*) FROM saved_people WHERE user_id = $1)                  AS saved_people,
		   (SELECT COUNT(*) FROM compatibility_reports WHERE user_id = $1)         AS compatibility_reports,
		   (SELECT COUNT(*) FROM posts WHERE author_id = $1)                       AS posts,
		   (SELECT COUNT(*) FROM comments WHERE author_id = $1)                    AS comments,
		   (SELECT COUNT(*) FROM spaces WHERE created_by = $1)                     AS spaces_created,
		   (SELECT COUNT(*) FROM content_reports WHERE reporter_id = $1)           AS reports_filed,
		   (SELECT COUNT(*) FROM content_reports cr
		      JOIN owned o ON o.target_type = cr.target_type AND o.id = cr.target_id) AS reports_against,
		   (SELECT COUNT(*) FROM content_reports cr
		      JOIN owned o ON o.target_type = cr.target_type AND o.id = cr.target_id
		     WHERE cr.status = 'open')                                             AS open_reports_against`,
		id,
	)
	if err != nil {
		return nil, err
	}
	return &a, nil
}

// SetBanned bans (banned=true; keeps the original timestamp when already
// banned) or unbans a non-deleted user. Returns false when there's no
// such user.
func (r *AdminRepository) SetBanned(ctx context.Context, id uuid.UUID, banned bool) (bool, error) {
	res, err := r.db.ExecContext(ctx,
		`UPDATE users
		    SET banned_at = CASE WHEN $2 THEN COALESCE(banned_at, NOW()) ELSE NULL END,
		        updated_at = NOW()
		  WHERE id = $1 AND deleted_at IS NULL`,
		id, banned,
	)
	if err != nil {
		return false, err
	}
	n, err := res.RowsAffected()
	return n > 0, err
}

// ===== Settings =====

// GetSetting returns one app_settings row, nil when it was never saved.
func (r *AdminRepository) GetSetting(ctx context.Context, key string) (*domain.StoredSetting, error) {
	var s domain.StoredSetting
	err := r.db.GetContext(ctx, &s,
		`SELECT st.key, st.value::text AS value, st.updated_at,
		        COALESCE(u.email::text, '') AS updated_by
		   FROM app_settings st
		   LEFT JOIN users u ON u.id = st.updated_by
		  WHERE st.key = $1`, key,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &s, nil
}

// PutSetting saves a JSON document under key.
func (r *AdminRepository) PutSetting(ctx context.Context, key string, value []byte, updatedBy uuid.UUID) error {
	if !json.Valid(value) {
		return fmt.Errorf("setting %q: invalid JSON", key)
	}
	_, err := r.db.ExecContext(ctx,
		`INSERT INTO app_settings (key, value, updated_at, updated_by)
		 VALUES ($1, $2::text::jsonb, NOW(), $3)
		 ON CONFLICT (key) DO UPDATE SET
		   value = EXCLUDED.value,
		   updated_at = EXCLUDED.updated_at,
		   updated_by = EXCLUDED.updated_by`,
		key, string(value), updatedBy,
	)
	return err
}

// ===== Audit log =====

// InsertAudit records an admin action.
func (r *AdminRepository) InsertAudit(ctx context.Context, e *domain.AuditEntry) error {
	details := e.DetailsJSON
	if details == "" {
		details = "{}"
	}
	return r.db.GetContext(ctx, &e.CreatedAt,
		`INSERT INTO admin_audit_log (id, admin_id, admin_email, action, target_type, target_id, details)
		 VALUES ($1, $2, $3, $4, $5, $6, $7::text::jsonb)
		 RETURNING created_at`,
		e.ID, e.AdminID, e.AdminEmail, e.Action, e.TargetType, e.TargetID, details,
	)
}

// ListAudit returns audit entries, newest first; only those about
// [targetID] when it isn't empty.
func (r *AdminRepository) ListAudit(ctx context.Context, targetID string, limit, offset int) ([]domain.AuditEntry, error) {
	out := []domain.AuditEntry{}
	err := r.db.SelectContext(ctx, &out,
		`SELECT id, admin_id, admin_email, action, target_type, target_id,
		        details::text AS details, created_at
		   FROM admin_audit_log
		  WHERE $1 = '' OR target_id = $1
		  ORDER BY created_at DESC
		  LIMIT $2 OFFSET $3`,
		targetID, limit, offset,
	)
	if err != nil {
		return nil, err
	}
	for i := range out {
		out[i].Details = json.RawMessage(out[i].DetailsJSON)
	}
	return out, nil
}
