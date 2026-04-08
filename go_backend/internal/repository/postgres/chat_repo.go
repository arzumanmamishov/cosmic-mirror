package postgres

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"cosmic-mirror/internal/domain"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type ChatRepository struct {
	db *sqlx.DB
}

func NewChatRepository(db *sqlx.DB) *ChatRepository {
	return &ChatRepository{db: db}
}

func (r *ChatRepository) CreateThread(ctx context.Context, thread *domain.ChatThread) error {
	thread.ID = uuid.New()
	thread.CreatedAt = time.Now()
	thread.UpdatedAt = time.Now()

	_, err := r.db.ExecContext(ctx,
		`INSERT INTO chat_threads (id, user_id, title, created_at, updated_at)
		 VALUES ($1, $2, $3, $4, $5)`,
		thread.ID, thread.UserID, thread.Title, thread.CreatedAt, thread.UpdatedAt,
	)
	return err
}

func (r *ChatRepository) GetThread(ctx context.Context, id uuid.UUID) (*domain.ChatThread, error) {
	var thread domain.ChatThread
	err := r.db.GetContext(ctx, &thread,
		`SELECT id, user_id, title, created_at, updated_at FROM chat_threads WHERE id = $1`, id,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &thread, err
}

func (r *ChatRepository) ListThreads(ctx context.Context, userID uuid.UUID) ([]domain.ChatThread, error) {
	var threads []domain.ChatThread
	err := r.db.SelectContext(ctx, &threads,
		`SELECT t.id, t.user_id, t.title, t.created_at, t.updated_at
		 FROM chat_threads t
		 WHERE t.user_id = $1
		 ORDER BY t.updated_at DESC`, userID,
	)
	if err != nil {
		return nil, err
	}

	// Attach last message to each thread
	for i := range threads {
		var lastMsg sql.NullString
		_ = r.db.GetContext(ctx, &lastMsg,
			`SELECT content FROM chat_messages
			 WHERE thread_id = $1 ORDER BY created_at DESC LIMIT 1`,
			threads[i].ID,
		)
		if lastMsg.Valid {
			threads[i].LastMessage = &lastMsg.String
		}
	}

	return threads, nil
}

func (r *ChatRepository) DeleteThread(ctx context.Context, id uuid.UUID) error {
	tx, err := r.db.BeginTxx(ctx, nil)
	if err != nil {
		return err
	}
	defer tx.Rollback()

	_, err = tx.ExecContext(ctx, `DELETE FROM chat_messages WHERE thread_id = $1`, id)
	if err != nil {
		return err
	}
	_, err = tx.ExecContext(ctx, `DELETE FROM chat_threads WHERE id = $1`, id)
	if err != nil {
		return err
	}
	return tx.Commit()
}

func (r *ChatRepository) CreateMessage(ctx context.Context, msg *domain.ChatMessage) error {
	msg.ID = uuid.New()
	msg.CreatedAt = time.Now()

	_, err := r.db.ExecContext(ctx,
		`INSERT INTO chat_messages (id, thread_id, role, content, created_at)
		 VALUES ($1, $2, $3, $4, $5)`,
		msg.ID, msg.ThreadID, msg.Role, msg.Content, msg.CreatedAt,
	)
	if err != nil {
		return err
	}

	// Update thread timestamp
	_, _ = r.db.ExecContext(ctx,
		`UPDATE chat_threads SET updated_at = $1 WHERE id = $2`,
		time.Now(), msg.ThreadID,
	)
	return nil
}

func (r *ChatRepository) GetMessages(ctx context.Context, threadID uuid.UUID, limit, offset int) ([]domain.ChatMessage, error) {
	var messages []domain.ChatMessage
	err := r.db.SelectContext(ctx, &messages,
		`SELECT id, thread_id, role, content, created_at
		 FROM chat_messages WHERE thread_id = $1
		 ORDER BY created_at ASC LIMIT $2 OFFSET $3`,
		threadID, limit, offset,
	)
	return messages, err
}

func (r *ChatRepository) CountUserMessagesToday(ctx context.Context, userID uuid.UUID) (int, error) {
	var count int
	err := r.db.GetContext(ctx, &count,
		`SELECT COUNT(*) FROM chat_messages m
		 JOIN chat_threads t ON t.id = m.thread_id
		 WHERE t.user_id = $1 AND m.role = 'user'
		 AND m.created_at >= CURRENT_DATE`,
		userID,
	)
	return count, err
}
