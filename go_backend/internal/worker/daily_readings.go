package worker

import (
	"context"
	"log/slog"
	"net/http"
	"time"

	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

const (
	// dailyReadingsBatch caps how many readings one run pre-generates.
	dailyReadingsBatch = 1000
	// perReadingTimeout bounds one generation (an LLM call is capped at
	// openai.RequestBudget = 75s; this adds headroom for DB/Redis).
	perReadingTimeout = 90 * time.Second
	// readingPacing spaces out LLM calls so the batch doesn't hit
	// provider rate limits.
	readingPacing = 200 * time.Millisecond
)

type DailyReadingsWorker struct {
	db         *sqlx.DB
	readingSvc *service.ReadingService
}

func NewDailyReadingsWorker(db *sqlx.DB, readingSvc *service.ReadingService) *DailyReadingsWorker {
	return &DailyReadingsWorker{db: db, readingSvc: readingSvc}
}

type readingTarget struct {
	UserID uuid.UUID `db:"id"`
	Lang   string    `db:"lang"`
}

// Run pre-generates today's daily reading for recently active users so it
// is ready when they open the app. Readings are also generated lazily on
// request, so this is purely a latency optimisation.
//
// Targets:
//   - only users active in the last 7 days. The activity signal is a
//     refresh token issued in that window (the app rotates its refresh
//     token whenever the 15-minute access token expires, so any session
//     produces one) or a recent last_login_at. daily_readings itself is
//     NOT used as a signal — this worker writes it, which would keep
//     every user "active" forever;
//   - in the user's language. There is no stored language preference, so
//     the language of the user's most recent reading (generated on
//     request with their Accept-Language) is used, defaulting to "en".
func (w *DailyReadingsWorker) Run(ctx context.Context) error {
	slog.Info("starting daily readings generation")
	today := time.Now().Truncate(24 * time.Hour)

	// Collect the work list first and release the connection: holding a
	// cursor open across up to 1000 sequential LLM calls would pin a DB
	// connection (and an open snapshot) for the whole run.
	var targets []readingTarget
	err := w.db.SelectContext(ctx, &targets,
		`SELECT u.id, COALESCE(latest.lang, 'en') AS lang
		 FROM users u
		 JOIN birth_profiles bp ON bp.user_id = u.id
		 LEFT JOIN LATERAL (
		     SELECT dr.lang FROM daily_readings dr
		     WHERE dr.user_id = u.id
		     ORDER BY dr.created_at DESC
		     LIMIT 1
		 ) latest ON TRUE
		 WHERE u.deleted_at IS NULL
		   AND (u.last_login_at > NOW() - INTERVAL '7 days'
		        OR EXISTS (SELECT 1 FROM refresh_tokens rt
		                   WHERE rt.user_id = u.id
		                     AND rt.created_at > NOW() - INTERVAL '7 days'))
		   AND NOT EXISTS (SELECT 1 FROM daily_readings t
		                   WHERE t.user_id = u.id
		                     AND t.reading_date = $1
		                     AND t.lang = COALESCE(latest.lang, 'en'))
		 ORDER BY u.id
		 LIMIT $2`, today.Format("2006-01-02"), dailyReadingsBatch)
	if err != nil {
		return err
	}

	var generated, failed int
	for i, t := range targets {
		if i > 0 {
			select {
			case <-ctx.Done():
				slog.Info("daily readings generation interrupted",
					"generated", generated, "failed", failed, "remaining", len(targets)-i)
				return ctx.Err()
			case <-time.After(readingPacing):
			}
		}

		rctx, cancel := context.WithTimeout(withLang(ctx, t.Lang), perReadingTimeout)
		_, err := w.readingSvc.GetDailyReading(rctx, t.UserID, today)
		cancel()
		if err != nil {
			slog.Error("failed to generate reading", "user_id", t.UserID, "lang", t.Lang, "error", err)
			failed++
		} else {
			generated++
		}
	}

	slog.Info("daily readings generation complete",
		"candidates", len(targets), "generated", generated, "failed", failed)
	return nil
}

// withLang returns ctx carrying [lang] the way the HTTP Language
// middleware stores it, so ReadingService (which reads the language via
// middleware.LangFromContext) generates in that language. The middleware
// package exposes no setter, so the value is produced by running the
// middleware itself against a synthetic request.
func withLang(ctx context.Context, lang string) context.Context {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "/", nil)
	if err != nil {
		return ctx
	}
	req.Header.Set("Accept-Language", lang)
	out := ctx
	middleware.Language(http.HandlerFunc(func(_ http.ResponseWriter, r *http.Request) {
		out = r.Context()
	})).ServeHTTP(nil, req)
	return out
}
