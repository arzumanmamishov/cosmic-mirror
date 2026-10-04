package handler

import (
	"encoding/json"
	"errors"
	"log/slog"
	"net/http"
	"strings"
	"unicode"
	"unicode/utf8"

	"cosmic-mirror/internal/domain"
)

type Handlers struct {
	Auth          *AuthHandler
	User          *UserHandler
	Chart         *ChartHandler
	Vedic         *VedicHandler
	DailyReading  *DailyReadingHandler
	AIChat        *AIChatHandler
	Compatibility *CompatibilityHandler
	Subscription  *SubscriptionHandler
	Stripe        *StripeHandler
	Journal       *JournalHandler
	Places        *PlacesHandler
	// Community / Spaces forum
	Spaces                 *SpacesHandler
	Posts                  *PostsHandler
	Comments               *CommentsHandler
	CommunityNotifications *CommunityNotificationsHandler
	Discovery              *DiscoveryHandler
	// Reports, blocks and the admin moderation queue (UGC safety)
	Moderation *ModerationHandler
	// Numerology + Human Design
	Numerology    *NumerologyHandler
	HumanDesign   *HumanDesignHandler
	Psychomatrix  *PsychomatrixHandler
	DestinyMatrix *DestinyMatrixHandler
}

type errorResponse struct {
	Error errorBody `json:"error"`
}

type errorBody struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

func respondJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

// respondError writes a JSON error. For 5xx responses the message (which
// callers often fill with err.Error()) is logged server-side and replaced
// with a generic one, so SQL / Stripe / library internals never reach the
// client. The machine-readable code is kept.
func respondError(w http.ResponseWriter, status int, code, message string) {
	if status >= 500 {
		slog.Error("internal error", "code", code, "status", status, "detail", message)
		message = "Something went wrong. Please try again."
	}
	respondJSON(w, status, errorResponse{
		Error: errorBody{Code: code, Message: message},
	})
}

// respondServiceError is respondError for an error coming back from a
// service. Input the service rejected (wrapped with domain.ErrValidation)
// becomes a 400 carrying the service's message; anything else gets
// [status] — for 5xx, respondError logs the detail and sends a generic
// message, so driver / library text never reaches the client.
func respondServiceError(w http.ResponseWriter, status int, code string, err error) {
	if errors.Is(err, domain.ErrValidation) {
		respondError(w, http.StatusBadRequest, "validation_error", validationMessage(err))
		return
	}
	respondError(w, status, code, err.Error())
}

// validationMessage extracts the human part of an ErrValidation-wrapped
// error. Services wrap as fmt.Errorf("%w: msg", domain.ErrValidation), and
// callers may add context in front ("create x: validation failed: msg"),
// so everything up to and including the sentinel text is dropped.
func validationMessage(err error) string {
	msg := err.Error()
	sentinel := domain.ErrValidation.Error()
	if i := strings.LastIndex(msg, sentinel); i >= 0 {
		msg = strings.TrimLeft(msg[i+len(sentinel):], ": ")
	}
	if msg == "" {
		return "Invalid input"
	}
	r, size := utf8.DecodeRuneInString(msg)
	return string(unicode.ToUpper(r)) + msg[size:]
}

func respondSuccess(w http.ResponseWriter, data any) {
	respondJSON(w, http.StatusOK, data)
}

func respondCreated(w http.ResponseWriter, data any) {
	respondJSON(w, http.StatusCreated, data)
}

func respondNoContent(w http.ResponseWriter) {
	w.WriteHeader(http.StatusNoContent)
}

func decodeBody(r *http.Request, v any) error {
	defer r.Body.Close()
	return json.NewDecoder(r.Body).Decode(v)
}
