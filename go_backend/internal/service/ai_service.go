package service

import (
	"context"
	"errors"
	"fmt"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/provider/openai"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
)

// ChatLimitError is returned by SendMessage when a free user has hit
// the daily message cap. Handlers can type-assert to map it to a 429.
type ChatLimitError struct {
	Used    int
	Limit   int
	ResetAt time.Time
}

func (e *ChatLimitError) Error() string {
	return fmt.Sprintf("daily chat limit reached (%d/%d)", e.Used, e.Limit)
}

// ChatUsage describes a user's current AI-chat consumption for the day.
type ChatUsage struct {
	Used      int       `json:"used"`
	Limit     int       `json:"limit"`
	IsPremium bool      `json:"is_premium"`
	ResetAt   time.Time `json:"reset_at"`
}

type AIService struct {
	chatRepo    repository.ChatRepository
	profileRepo repository.BirthProfileRepository
	aiClient    *openai.Client
	freeChatLimit int
}

func NewAIService(
	chatRepo repository.ChatRepository,
	profileRepo repository.BirthProfileRepository,
	aiClient *openai.Client,
	freeChatLimit int,
) *AIService {
	return &AIService{
		chatRepo:    chatRepo,
		profileRepo: profileRepo,
		aiClient:    aiClient,
		freeChatLimit: freeChatLimit,
	}
}

func (s *AIService) CreateThread(ctx context.Context, userID uuid.UUID) (*domain.ChatThread, error) {
	thread := &domain.ChatThread{UserID: userID}
	if err := s.chatRepo.CreateThread(ctx, thread); err != nil {
		return nil, fmt.Errorf("create thread: %w", err)
	}
	return thread, nil
}

func (s *AIService) ListThreads(ctx context.Context, userID uuid.UUID) ([]domain.ChatThread, error) {
	return s.chatRepo.ListThreads(ctx, userID)
}

// DeleteThread removes a thread + all its messages. Verifies the
// thread belongs to the caller first — without this, anyone with a
// thread id could wipe anyone else's conversation.
//
// Returns:
//   - ErrThreadNotFound when no thread exists with that id
//   - ErrThreadForbidden when the caller doesn't own the thread
//   - underlying repo error on actual DB failures
func (s *AIService) DeleteThread(ctx context.Context, userID uuid.UUID, threadID uuid.UUID) error {
	thread, err := s.chatRepo.GetThread(ctx, threadID)
	if err != nil {
		return fmt.Errorf("get thread: %w", err)
	}
	if thread == nil {
		return ErrThreadNotFound
	}
	if thread.UserID != userID {
		return ErrThreadForbidden
	}
	return s.chatRepo.DeleteThread(ctx, threadID)
}

// Sentinel errors the handler maps to clean HTTP statuses.
var (
	ErrThreadNotFound  = errors.New("thread not found")
	ErrThreadForbidden = errors.New("thread does not belong to this user")
)

func (s *AIService) GetMessages(ctx context.Context, threadID uuid.UUID, limit, offset int) ([]domain.ChatMessage, error) {
	return s.chatRepo.GetMessages(ctx, threadID, limit, offset)
}

// GetUsage reports a user's current AI-chat consumption for the day so
// the client can render a counter and disable the input proactively
// instead of finding out at send-time.
func (s *AIService) GetUsage(ctx context.Context, userID uuid.UUID, isPremium bool) (*ChatUsage, error) {
	used, err := s.chatRepo.CountUserMessagesToday(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("count messages: %w", err)
	}
	return &ChatUsage{
		Used:      used,
		Limit:     s.freeChatLimit,
		IsPremium: isPremium,
		ResetAt:   nextResetAt(),
	}, nil
}

// nextResetAt returns the next UTC midnight — the moment a free user's
// per-day count resets to zero. Always in the future.
func nextResetAt() time.Time {
	now := time.Now().UTC()
	return time.Date(now.Year(), now.Month(), now.Day()+1, 0, 0, 0, 0, time.UTC)
}

func (s *AIService) SendMessage(ctx context.Context, userID uuid.UUID, threadID uuid.UUID, content string, isPremium bool) (*domain.ChatMessage, error) {
	// Daily cap for free users — premium bypasses entirely.
	if !isPremium {
		count, err := s.chatRepo.CountUserMessagesToday(ctx, userID)
		if err != nil {
			return nil, fmt.Errorf("count messages: %w", err)
		}
		if count >= s.freeChatLimit {
			return nil, &ChatLimitError{
				Used:    count,
				Limit:   s.freeChatLimit,
				ResetAt: nextResetAt(),
			}
		}
	}

	// Validate input
	if len(content) > 500 {
		return nil, fmt.Errorf("message too long (max 500 characters)")
	}

	// Save user message
	userMsg := &domain.ChatMessage{
		ThreadID: threadID,
		Role:     "user",
		Content:  content,
	}
	if err := s.chatRepo.CreateMessage(ctx, userMsg); err != nil {
		return nil, fmt.Errorf("save user message: %w", err)
	}

	// Get birth profile for context
	profile, _ := s.profileRepo.GetByUserID(ctx, userID)

	// Get thread history (last 20 messages)
	history, err := s.chatRepo.GetMessages(ctx, threadID, 20, 0)
	if err != nil {
		return nil, fmt.Errorf("get history: %w", err)
	}

	// Build messages for OpenAI
	systemPrompt := openai.BuildChatSystemPrompt(profile)
	messages := []openai.Message{{Role: "system", Content: systemPrompt}}
	for _, msg := range history {
		messages = append(messages, openai.Message{Role: msg.Role, Content: msg.Content})
	}

	// Call OpenAI
	response, err := s.aiClient.ChatCompletion(ctx, messages)
	if err != nil {
		return nil, fmt.Errorf("AI response failed: %w", err)
	}

	// Save assistant response
	assistantMsg := &domain.ChatMessage{
		ThreadID: threadID,
		Role:     "assistant",
		Content:  response,
	}
	if err := s.chatRepo.CreateMessage(ctx, assistantMsg); err != nil {
		return nil, fmt.Errorf("save assistant message: %w", err)
	}

	// Auto-title the thread from first exchange
	thread, _ := s.chatRepo.GetThread(ctx, threadID)
	if thread != nil && thread.Title == nil {
		title := content
		if len(title) > 50 {
			title = title[:50] + "..."
		}
		thread.Title = &title
	}

	return assistantMsg, nil
}
