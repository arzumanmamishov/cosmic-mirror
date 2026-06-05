package handler

import (
	"errors"
	"net/http"
	"strconv"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type AIChatHandler struct {
	aiSvc  *service.AIService
	subSvc *service.SubscriptionService
}

func NewAIChatHandler(aiSvc *service.AIService, subSvc *service.SubscriptionService) *AIChatHandler {
	return &AIChatHandler{aiSvc: aiSvc, subSvc: subSvc}
}

func (h *AIChatHandler) ListThreads(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	threads, err := h.aiSvc.ListThreads(r.Context(), userID)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "list_error", err.Error())
		return
	}
	if threads == nil {
		threads = []domain.ChatThread{}
	}
	respondSuccess(w, map[string]any{"threads": threads})
}

func (h *AIChatHandler) CreateThread(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	thread, err := h.aiSvc.CreateThread(r.Context(), userID)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "create_error", err.Error())
		return
	}
	respondCreated(w, thread)
}

// DeleteThread removes a chat thread + all its messages. Owner-only.
//   404 → no thread with that id
//   403 → thread belongs to a different user
//   500 → DB failure
func (h *AIChatHandler) DeleteThread(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	threadID, err := uuid.Parse(chi.URLParam(r, "threadID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid thread ID")
		return
	}

	if err := h.aiSvc.DeleteThread(r.Context(), userID, threadID); err != nil {
		switch {
		case errors.Is(err, service.ErrThreadNotFound):
			respondError(w, http.StatusNotFound, "not_found", "Thread not found")
		case errors.Is(err, service.ErrThreadForbidden):
			respondError(w, http.StatusForbidden, "forbidden",
				"You can't delete someone else's conversation")
		default:
			respondError(w, http.StatusInternalServerError, "delete_error", err.Error())
		}
		return
	}
	respondNoContent(w)
}

func (h *AIChatHandler) GetMessages(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	threadID, err := uuid.Parse(chi.URLParam(r, "threadID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid thread ID")
		return
	}

	limit := 50
	offset := 0
	if l := r.URL.Query().Get("limit"); l != "" {
		if v, err := strconv.Atoi(l); err == nil && v > 0 && v <= 100 {
			limit = v
		}
	}
	if o := r.URL.Query().Get("offset"); o != "" {
		if v, err := strconv.Atoi(o); err == nil && v >= 0 {
			offset = v
		}
	}

	messages, err := h.aiSvc.GetMessages(r.Context(), userID, threadID, limit, offset)
	if err != nil {
		switch {
		case errors.Is(err, service.ErrThreadNotFound):
			respondError(w, http.StatusNotFound, "not_found", "Thread not found")
		case errors.Is(err, service.ErrThreadForbidden):
			respondError(w, http.StatusForbidden, "forbidden",
				"You can't read someone else's conversation")
		default:
			respondError(w, http.StatusInternalServerError, "messages_error", err.Error())
		}
		return
	}
	if messages == nil {
		messages = []domain.ChatMessage{}
	}
	respondSuccess(w, map[string]any{"messages": messages})
}

func (h *AIChatHandler) SendMessage(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	threadID, err := uuid.Parse(chi.URLParam(r, "threadID"))
	if err != nil {
		respondError(w, http.StatusBadRequest, "invalid_id", "Invalid thread ID")
		return
	}

	var input domain.SendMessageInput
	if err := decodeBody(r, &input); err != nil {
		respondError(w, http.StatusBadRequest, "invalid_body", "Invalid request body")
		return
	}

	if input.Content == "" {
		respondError(w, http.StatusBadRequest, "empty_message", "Message content is required")
		return
	}

	isPremium := h.subSvc.IsPremium(r.Context(), userID)

	response, err := h.aiSvc.SendMessage(r.Context(), userID, threadID, input.Content, isPremium)
	if err != nil {
		// Surface the daily-cap error as a structured 429 so the client
		// can show a paywall + counter rather than a generic failure.
		var limitErr *service.ChatLimitError
		if errors.As(err, &limitErr) {
			respondJSON(w, http.StatusTooManyRequests, map[string]any{
				"error": map[string]any{
					"code":     "chat_limit_reached",
					"message":  limitErr.Error(),
					"used":     limitErr.Used,
					"limit":    limitErr.Limit,
					"reset_at": limitErr.ResetAt,
				},
			})
			return
		}
		switch {
		case errors.Is(err, service.ErrThreadNotFound):
			respondError(w, http.StatusNotFound, "not_found", "Thread not found")
		case errors.Is(err, service.ErrThreadForbidden):
			respondError(w, http.StatusForbidden, "forbidden",
				"You can't post into someone else's conversation")
		default:
			respondError(w, http.StatusInternalServerError, "send_error", err.Error())
		}
		return
	}
	respondSuccess(w, response)
}

// GetUsage returns the user's current AI-chat consumption for the day.
// Used by the client to render the "X of Y messages today" counter and
// to disable the input proactively when the cap is reached.
func (h *AIChatHandler) GetUsage(w http.ResponseWriter, r *http.Request) {
	userID := middleware.UserIDFromContext(r.Context())
	isPremium := h.subSvc.IsPremium(r.Context(), userID)
	usage, err := h.aiSvc.GetUsage(r.Context(), userID, isPremium)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "usage_error", err.Error())
		return
	}
	respondSuccess(w, usage)
}
