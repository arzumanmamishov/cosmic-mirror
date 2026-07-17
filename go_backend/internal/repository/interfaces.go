package repository

import (
	"context"
	"errors"
	"time"

	"cosmic-mirror/internal/domain"

	"github.com/google/uuid"
)

// ErrJournalEntryNotFound is returned by JournalRepository.Update when no
// entry matches the given id for the given user — either it doesn't exist
// or it belongs to someone else. Handlers map this to a 404.
var ErrJournalEntryNotFound = errors.New("journal entry not found")

// ErrSubscriptionNotFound is returned by SubscriptionRepository.UpdateFromStripe
// when no row matches the Stripe subscription id — typically because a
// `subscription.created` webhook arrived before the Subscribe flow persisted
// the row. Callers use it to self-heal instead of silently dropping the event.
var ErrSubscriptionNotFound = errors.New("subscription not found")

type UserRepository interface {
	Create(ctx context.Context, user *domain.User) error
	GetByID(ctx context.Context, id uuid.UUID) (*domain.User, error)
	GetByFirebaseUID(ctx context.Context, uid string) (*domain.User, error)
	GetByEmail(ctx context.Context, email string) (*domain.User, error)
	Update(ctx context.Context, id uuid.UUID, input domain.UpdateUserInput) error
	UpdatePasswordHash(ctx context.Context, id uuid.UUID, hash string) error
	MarkEmailVerified(ctx context.Context, id uuid.UUID) error
	TouchLastLogin(ctx context.Context, id uuid.UUID) error
	SetAvatarURL(ctx context.Context, id uuid.UUID, url *string) error
	SoftDelete(ctx context.Context, id uuid.UUID) error
}

// RefreshTokenRepository backs the local-auth refresh flow. Tokens are
// opaque and stored server-side (their sha256 hash) so they can be
// revoked on logout / rotation replay.
type RefreshTokenRepository interface {
	Insert(ctx context.Context, userID uuid.UUID, tokenHash string, expiresAt time.Time, ip, userAgent string) (uuid.UUID, error)
	FindActiveByHash(ctx context.Context, tokenHash string) (*domain.RefreshToken, error)
	Rotate(ctx context.Context, oldID uuid.UUID, newTokenHash string, expiresAt time.Time, ip, userAgent string) (uuid.UUID, error)
	Revoke(ctx context.Context, id uuid.UUID) error
	RevokeByHash(ctx context.Context, tokenHash string) error
	RevokeAllForUser(ctx context.Context, userID uuid.UUID) error
}

type StatsRepository interface {
	GetStats(ctx context.Context, userID uuid.UUID) (*domain.UserStats, error)
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
	GetByUserAndDate(ctx context.Context, userID uuid.UUID, date time.Time, lang string) (*domain.DailyReading, error)
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
	GetRecentMessages(ctx context.Context, threadID uuid.UUID, limit int) ([]domain.ChatMessage, error)
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
	Update(ctx context.Context, id, userID uuid.UUID, input domain.UpdateJournalInput) error
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
	GetByStripeCustomer(ctx context.Context, stripeCustomerID string) (*domain.Subscription, error)
	Upsert(ctx context.Context, sub *domain.Subscription) error
	UpdateStatus(ctx context.Context, revenueCatID string, status domain.SubscriptionStatus, expiresAt *time.Time) error
	UpdateFromStripe(ctx context.Context, stripeSubscriptionID string, status domain.SubscriptionStatus, priceID string, planType domain.PlanType, currentPeriodEnd *time.Time, cancelAtPeriodEnd bool) error
}
