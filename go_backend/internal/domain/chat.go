package domain

import (
	"time"

	"github.com/google/uuid"
)

type ChatThread struct {
	ID          uuid.UUID  `db:"id" json:"id"`
	UserID      uuid.UUID  `db:"user_id" json:"user_id"`
	Title       *string    `db:"title" json:"title"`
	LastMessage *string    `db:"-" json:"last_message,omitempty"`
	CreatedAt   time.Time  `db:"created_at" json:"created_at"`
	UpdatedAt   time.Time  `db:"updated_at" json:"updated_at"`
}

type ChatMessage struct {
	ID        uuid.UUID `db:"id" json:"id"`
	ThreadID  uuid.UUID `db:"thread_id" json:"thread_id"`
	Role      string    `db:"role" json:"role"` // "user" or "assistant"
	Content   string    `db:"content" json:"content"`
	CreatedAt time.Time `db:"created_at" json:"created_at"`
}

type SendMessageInput struct {
	Content string `json:"content" validate:"required,max=500"`
}
