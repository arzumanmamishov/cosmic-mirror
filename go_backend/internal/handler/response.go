package handler

import (
	"encoding/json"
	"log/slog"
	"net/http"
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
