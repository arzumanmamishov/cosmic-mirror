package service

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/middleware"
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
	chatRepo      repository.ChatRepository
	profileRepo   repository.BirthProfileRepository
	userRepo      repository.UserRepository
	aiClient      *openai.Client
	freeChatLimit int
}

func NewAIService(
	chatRepo repository.ChatRepository,
	profileRepo repository.BirthProfileRepository,
	userRepo repository.UserRepository,
	aiClient *openai.Client,
	freeChatLimit int,
) *AIService {
	return &AIService{
		chatRepo:      chatRepo,
		profileRepo:   profileRepo,
		userRepo:      userRepo,
		aiClient:      aiClient,
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

// assertThreadOwner loads a thread and verifies it belongs to the
// caller. Every per-thread operation must go through this — otherwise
// anyone holding a thread id can read, write, or wipe another user's
// conversation (IDOR).
//
// Returns:
//   - ErrThreadNotFound when no thread exists with that id
//   - ErrThreadForbidden when the caller doesn't own the thread
//   - underlying repo error on actual DB failures
func (s *AIService) assertThreadOwner(ctx context.Context, userID, threadID uuid.UUID) (*domain.ChatThread, error) {
	thread, err := s.chatRepo.GetThread(ctx, threadID)
	if err != nil {
		return nil, fmt.Errorf("get thread: %w", err)
	}
	if thread == nil {
		return nil, ErrThreadNotFound
	}
	if thread.UserID != userID {
		return nil, ErrThreadForbidden
	}
	return thread, nil
}

// DeleteThread removes a thread + all its messages. Owner-only.
func (s *AIService) DeleteThread(ctx context.Context, userID uuid.UUID, threadID uuid.UUID) error {
	if _, err := s.assertThreadOwner(ctx, userID, threadID); err != nil {
		return err
	}
	return s.chatRepo.DeleteThread(ctx, threadID)
}

// Sentinel errors the handler maps to clean HTTP statuses.
var (
	ErrThreadNotFound  = errors.New("thread not found")
	ErrThreadForbidden = errors.New("thread does not belong to this user")
)

func (s *AIService) GetMessages(ctx context.Context, userID uuid.UUID, threadID uuid.UUID, limit, offset int) ([]domain.ChatMessage, error) {
	if _, err := s.assertThreadOwner(ctx, userID, threadID); err != nil {
		return nil, err
	}
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
	// Verify the caller owns this thread before doing anything — without
	// this, anyone could post into another user's conversation (IDOR).
	thread, err := s.assertThreadOwner(ctx, userID, threadID)
	if err != nil {
		return nil, err
	}

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

	// Get birth profile + the user's name so the AI can address them
	// personally. Best-effort — empty name just falls back to a
	// generic friendly tone.
	profile, _ := s.profileRepo.GetByUserID(ctx, userID)
	var firstName string
	if user, _ := s.userRepo.GetByID(ctx, userID); user != nil {
		firstName = firstNameOf(user.Name)
	}

	// Get thread history (most recent 20 messages, chronological)
	history, err := s.chatRepo.GetRecentMessages(ctx, threadID, 20)
	if err != nil {
		return nil, fmt.Errorf("get history: %w", err)
	}

	// Build messages for OpenAI
	systemPrompt := openai.BuildChatSystemPrompt(profile, firstName, middleware.LangFromContext(ctx))
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
	if thread != nil && thread.Title == nil {
		title := truncateRunes(content, 50, "...")
		thread.Title = &title
	}

	return assistantMsg, nil
}

// firstNameOf pulls the first whitespace-separated token from a stored
// name ("Norma Jeane Baker" → "Norma"). Empty / whitespace-only inputs
// return "" so callers know to fall back to a generic salutation.
func firstNameOf(fullName string) string {
	trimmed := strings.TrimSpace(fullName)
	if trimmed == "" {
		return ""
	}
	if i := strings.IndexAny(trimmed, " \t"); i > 0 {
		return trimmed[:i]
	}
	return trimmed
}
