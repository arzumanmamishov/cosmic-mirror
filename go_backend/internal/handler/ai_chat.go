package handler

import (
	"net/http"
	"strconv"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/middleware"
	"cosmic-mirror/internal/service"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
)

type AIChatHandler struct {
	aiSvc *service.AIService
}

func NewAIChatHandler(aiSvc *service.AIService) *AIChatHandler {
	return &AIChatHandler{aiSvc: aiSvc}
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

func (h *AIChatHandler) GetMessages(w http.ResponseWriter, r *http.Request) {
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

	messages, err := h.aiSvc.GetMessages(r.Context(), threadID, limit, offset)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "messages_error", err.Error())
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

	// Check premium status (would come from middleware context in production)
	isPremium := false // TODO: read from context

	response, err := h.aiSvc.SendMessage(r.Context(), userID, threadID, input.Content, isPremium)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "send_error", err.Error())
		return
	}
	respondSuccess(w, response)
}
