package handler

import (
	"errors"
	"io"
	"net/http"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

// AdminHandler serves /api/v1/admin/* for the web admin panel. Every
// route sits behind auth.Verify + auth.RequireAdmin (ADMIN_EMAILS).
type AdminHandler struct {
	svc *service.AdminService
}

func NewAdminHandler(svc *service.AdminService) *AdminHandler {
	return &AdminHandler{svc: svc}
}

// adminActor identifies the admin making the request (set by RequireAdmin).
func adminActor(r *http.Request) service.AdminActor {
	return service.AdminActor{
		ID:    middleware.UserIDFromContext(r.Context()),
		Email: middleware.AdminEmailFromContext(r.Context()),
	}
}

// Me — GET /admin/me. 200 only for admins (the panel's access check).
func (h *AdminHandler) Me(w http.ResponseWriter, r *http.Request) {
	a := adminActor(r)
	respondSuccess(w, map[string]any{"id": a.ID, "email": a.Email})
}

// Stats — GET /admin/stats.
func (h *AdminHandler) Stats(w http.ResponseWriter, r *http.Request) {
	stats, err := h.svc.Stats(r.Context())
	if err != nil {
		respondAdminError(w, err)
		return
	}
	respondSuccess(w, stats)
}

// ListUsers — GET /admin/users?q=&filter=&limit=&offset=.
func (h *AdminHandler) ListUsers(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	limit := parseLimit(q.Get("limit"), 50, 200)
	offset := parseOffset(q.Get("offset"))
	users, total, err := h.svc.ListUsers(r.Context(), domain.AdminUserQuery{
		Search: q.Get("q"),
		Filter: q.Get("filter"),
		Limit:  limit,
		Offset: offset,
	})
	if err != nil {
		respondAdminError(w, err)
		return
	}
	respondSuccess(w, map[string]any{
		"users": users, "total": total, "limit": limit, "offset": offset,
	})
}

// GetUser — GET /admin/users/{userID}.
func (h *AdminHandler) GetUser(w http.ResponseWriter, r *http.Request) {
	id, ok := userIDParam(w, r)
	if !ok {
		return
	}
	user, err := h.svc.GetUser(r.Context(), id)
	if err != nil {
		respondAdminError(w, err)
		return
	}
	respondSuccess(w, user)
}

type adminNoteBody struct {
	Note string `json:"note"`
}

// decodeOptionalBody decodes a JSON body; an empty body is fine.
func decodeOptionalBody(r *http.Request, v any) error {
	if err := decodeBody(r, v); err != nil && !errors.Is(err, io.EOF) {
		return err
	}
	return nil
}

// BanUser — POST /admin/users/{userID}/ban {note}.
func (h *AdminHandler) BanUser(w http.ResponseWriter, r *http.Request) {
	id, ok := userIDParam(w, r)
	if !ok {
		return
	}
	var in adminNoteBody
	if err := decodeOptionalBody(r, &in); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	if err := h.svc.BanUser(r.Context(), adminActor(r), id, in.Note); err != nil {
		respondAdminError(w, err)
		return
	}
	respondNoContent(w)
}

// UnbanUser — POST /admin/users/{userID}/unban {note}.
func (h *AdminHandler) UnbanUser(w http.ResponseWriter, r *http.Request) {
	id, ok := userIDParam(w, r)
	if !ok {
		return
	}
	var in adminNoteBody
	if err := decodeOptionalBody(r, &in); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	if err := h.svc.UnbanUser(r.Context(), adminActor(r), id, in.Note); err != nil {
		respondAdminError(w, err)
		return
	}
	respondNoContent(w)
}

// DeleteUser — POST /admin/users/{userID}/delete {confirm_email, note}.
// A POST with a typed confirmation rather than a bare DELETE, so the
// request itself proves the admin meant this customer.
func (h *AdminHandler) DeleteUser(w http.ResponseWriter, r *http.Request) {
	id, ok := userIDParam(w, r)
	if !ok {
		return
	}
	var in struct {
		ConfirmEmail string `json:"confirm_email"`
		Note         string `json:"note"`
	}
	if err := decodeBody(r, &in); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	if err := h.svc.DeleteUser(r.Context(), adminActor(r), id, in.ConfirmEmail, in.Note); err != nil {
		respondAdminError(w, err)
		return
	}
	respondNoContent(w)
}

// GetSettings — GET /admin/settings.
func (h *AdminHandler) GetSettings(w http.ResponseWriter, r *http.Request) {
	settings, err := h.svc.Settings(r.Context())
	if err != nil {
		respondAdminError(w, err)
		return
	}
	respondSuccess(w, settings)
}

// UpdateStripeSettings — PUT /admin/settings/stripe
// {price_monthly, price_yearly, yearly_trial_days}. Empty / null = use
// the server default.
func (h *AdminHandler) UpdateStripeSettings(w http.ResponseWriter, r *http.Request) {
	var in domain.StripeSettingsOverride
	if err := decodeBody(r, &in); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}
	out, err := h.svc.UpdateStripeSettings(r.Context(), adminActor(r), in)
	if err != nil {
		respondAdminError(w, err)
		return
	}
	respondSuccess(w, out)
}

// ListStripePrices — GET /admin/stripe/prices.
func (h *AdminHandler) ListStripePrices(w http.ResponseWriter, r *http.Request) {
	prices, err := h.svc.ListStripePrices(r.Context())
	if err != nil {
		respondAdminError(w, err)
		return
	}
	respondSuccess(w, map[string]any{"prices": prices})
}

// ListAudit — GET /admin/audit?target_id=&limit=&offset=.
func (h *AdminHandler) ListAudit(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	entries, err := h.svc.ListAudit(r.Context(), q.Get("target_id"),
		parseLimit(q.Get("limit"), 50, 200), parseOffset(q.Get("offset")))
	if err != nil {
		respondAdminError(w, err)
		return
	}
	respondSuccess(w, map[string]any{"entries": entries})
}

func userIDParam(w http.ResponseWriter, r *http.Request) (uuid.UUID, bool) {
	id, err := uuid.Parse(chi.URLParam(r, "userID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid user ID")
		return uuid.Nil, false
	}
	return id, true
}

func respondAdminError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, service.ErrUserNotFound):
		respondError(w, http.StatusNotFound, "not_found", "Customer not found")
	case errors.Is(err, service.ErrStripeNotConfigured):
		respondError(w, http.StatusConflict, "stripe_unconfigured",
			"Stripe isn't connected on this server: STRIPE_SECRET_KEY is empty.")
	default:
		// ErrValidation → 400 with its message; anything else → 500.
		respondServiceError(w, http.StatusInternalServerError, "admin_error", err)
	}
}
