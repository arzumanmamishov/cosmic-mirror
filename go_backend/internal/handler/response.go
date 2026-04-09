package handler

import (
	"encoding/json"
	"net/http"
)

type Handlers struct {
	Auth          *AuthHandler
	User          *UserHandler
	Chart         *ChartHandler
	DailyReading  *DailyReadingHandler
	AIChat        *AIChatHandler
	Compatibility *CompatibilityHandler
	Subscription  *SubscriptionHandler
	Journal       *JournalHandler
	Places        *PlacesHandler
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

func respondError(w http.ResponseWriter, status int, code, message string) {
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
