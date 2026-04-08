package service

import (
	"context"
	"fmt"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/provider/openai"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
)

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

func (s *AIService) GetMessages(ctx context.Context, threadID uuid.UUID, limit, offset int) ([]domain.ChatMessage, error) {
	return s.chatRepo.GetMessages(ctx, threadID, limit, offset)
}

func (s *AIService) SendMessage(ctx context.Context, userID uuid.UUID, threadID uuid.UUID, content string, isPremium bool) (*domain.ChatMessage, error) {
	// Check rate limit for free users
	if !isPremium {
		count, err := s.chatRepo.CountUserMessagesToday(ctx, userID)
		if err != nil {
			return nil, fmt.Errorf("count messages: %w", err)
		}
		if count >= s.freeChatLimit {
			return nil, fmt.Errorf("daily message limit reached. Upgrade to Premium for unlimited chat")
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
