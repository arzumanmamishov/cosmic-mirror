package repository

import (
	"context"
	"time"

	"cosmic-mirror/internal/domain"

	"github.com/google/uuid"
)

type UserRepository interface {
	Create(ctx context.Context, user *domain.User) error
	GetByID(ctx context.Context, id uuid.UUID) (*domain.User, error)
	GetByFirebaseUID(ctx context.Context, uid string) (*domain.User, error)
	Update(ctx context.Context, id uuid.UUID, input domain.UpdateUserInput) error
	SoftDelete(ctx context.Context, id uuid.UUID) error
}

type BirthProfileRepository interface {
	Create(ctx context.Context, profile *domain.BirthProfile) error
	GetByUserID(ctx context.Context, userID uuid.UUID) (*domain.BirthProfile, error)
	Update(ctx context.Context, userID uuid.UUID, input domain.CreateBirthProfileInput) error
}

type PreferencesRepository interface {
	Get(ctx context.Context, userID uuid.UUID) (*domain.UserPreferences, error)
	Upsert(ctx context.Context, prefs *domain.UserPreferences) error
}

type DailyReadingRepository interface {
	GetByUserAndDate(ctx context.Context, userID uuid.UUID, date time.Time) (*domain.DailyReading, error)
	Create(ctx context.Context, reading *domain.DailyReading) error
	ListByUserAndDateRange(ctx context.Context, userID uuid.UUID, start, end time.Time) ([]domain.DailyReading, error)
}

type ChatRepository interface {
	CreateThread(ctx context.Context, thread *domain.ChatThread) error
	GetThread(ctx context.Context, id uuid.UUID) (*domain.ChatThread, error)
	ListThreads(ctx context.Context, userID uuid.UUID) ([]domain.ChatThread, error)
	DeleteThread(ctx context.Context, id uuid.UUID) error
	CreateMessage(ctx context.Context, msg *domain.ChatMessage) error
	GetMessages(ctx context.Context, threadID uuid.UUID, limit, offset int) ([]domain.ChatMessage, error)
	CountUserMessagesToday(ctx context.Context, userID uuid.UUID) (int, error)
}

type SavedPeopleRepository interface {
	Create(ctx context.Context, person *domain.SavedPerson) error
	List(ctx context.Context, userID uuid.UUID) ([]domain.SavedPerson, error)
	GetByID(ctx context.Context, id uuid.UUID) (*domain.SavedPerson, error)
	Delete(ctx context.Context, id uuid.UUID) error
}

type CompatibilityRepository interface {
	Create(ctx context.Context, report *domain.CompatibilityReport) error
	GetByUserAndPerson(ctx context.Context, userID, personID uuid.UUID) (*domain.CompatibilityReport, error)
}

type JournalRepository interface {
	Create(ctx context.Context, entry *domain.JournalEntry) error
	Update(ctx context.Context, id uuid.UUID, input domain.UpdateJournalInput) error
	List(ctx context.Context, userID uuid.UUID, limit, offset int) ([]domain.JournalEntry, error)
	GetByID(ctx context.Context, id uuid.UUID) (*domain.JournalEntry, error)
}

type RitualRepository interface {
	Complete(ctx context.Context, completion *domain.RitualCompletion) error
	GetTodayCompletions(ctx context.Context, userID uuid.UUID) ([]domain.RitualCompletion, error)
	GetStreak(ctx context.Context, userID uuid.UUID) (int, error)
}

type SubscriptionRepository interface {
	GetByUserID(ctx context.Context, userID uuid.UUID) (*domain.Subscription, error)
	Upsert(ctx context.Context, sub *domain.Subscription) error
	UpdateStatus(ctx context.Context, revenueCatID string, status domain.SubscriptionStatus, expiresAt *time.Time) error
}
