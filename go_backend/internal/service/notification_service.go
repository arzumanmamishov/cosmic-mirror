package service

import (
	"context"
	"log/slog"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/repository/postgres"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

// CommunityNotificationService is the single fan-in for emitting in-app
// activity-feed notifications. Other services call Emit / EmitMany rather
// than touching the notification repo directly so behaviour stays consistent
// (self-actor suppression, transaction reuse, future batching/dedup).
type CommunityNotificationService struct {
	notifRepo *postgres.CommunityNotificationRepository
}

func NewCommunityNotificationService(notifRepo *postgres.CommunityNotificationRepository) *CommunityNotificationService {
	return &CommunityNotificationService{notifRepo: notifRepo}
}

// EmitParams describes one notification to create.
type EmitParams struct {
	RecipientID uuid.UUID
	ActorID     *uuid.UUID
	Type        string
	TargetType  string
	TargetID    uuid.UUID
	Snippet     *string
}

// Emit writes one notification. If the actor is the recipient, suppress (we
// don't tell users about their own actions). `tx` is optional — pass nil to
// run on the bare connection.
func (s *CommunityNotificationService) Emit(ctx context.Context, tx *sqlx.Tx, p EmitParams) error {
	// Self-suppress.
	if p.ActorID != nil && *p.ActorID == p.RecipientID {
		return nil
	}
	n := &domain.CommunityNotification{
		RecipientID: p.RecipientID,
		ActorID:     p.ActorID,
		Type:        p.Type,
		TargetType:  p.TargetType,
		TargetID:    p.TargetID,
		Snippet:     p.Snippet,
	}
	if err := s.notifRepo.Create(ctx, tx, n); err != nil {
		// Logged but not fatal — failing to emit a notification should not
		// break the user-facing action that triggered it.
		slog.Error("failed to emit community notification",
			"error", err,
			"type", p.Type,
			"recipient", p.RecipientID,
		)
		return err
	}
	return nil
}

// EmitMany fans out the same notification to multiple recipients. Self-actor
// suppression is applied per-recipient.
func (s *CommunityNotificationService) EmitMany(ctx context.Context, tx *sqlx.Tx, recipients []uuid.UUID, p EmitParams) {
	for _, r := range recipients {
		params := p
		params.RecipientID = r
		if err := s.Emit(ctx, tx, params); err != nil {
			// Continue fanning out — one failure shouldn't break the rest.
			continue
		}
	}
}

func (s *CommunityNotificationService) List(ctx context.Context, recipientID uuid.UUID, unreadOnly bool, limit, offset int) ([]domain.NotificationWithMeta, error) {
	return s.notifRepo.ListByUser(ctx, recipientID, unreadOnly, limit, offset)
}

func (s *CommunityNotificationService) MarkRead(ctx context.Context, id, recipientID uuid.UUID) error {
	return s.notifRepo.MarkRead(ctx, id, recipientID)
}

func (s *CommunityNotificationService) MarkAllRead(ctx context.Context, recipientID uuid.UUID) error {
	return s.notifRepo.MarkAllRead(ctx, recipientID)
}

func (s *CommunityNotificationService) UnreadCount(ctx context.Context, recipientID uuid.UUID) (int, error) {
	return s.notifRepo.UnreadCount(ctx, recipientID)
}
