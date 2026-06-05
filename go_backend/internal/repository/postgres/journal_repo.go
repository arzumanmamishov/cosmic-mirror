package postgres

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/repository"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

type JournalRepository struct {
	db *sqlx.DB
}

func NewJournalRepository(db *sqlx.DB) *JournalRepository {
	return &JournalRepository{db: db}
}

func (r *JournalRepository) Create(ctx context.Context, entry *domain.JournalEntry) error {
	entry.ID = uuid.New()
	entry.CreatedAt = time.Now()
	entry.UpdatedAt = time.Now()

	_, err := r.db.ExecContext(ctx,
		`INSERT INTO journal_entries (id, user_id, entry_date, prompt, content, mood, created_at, updated_at)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
		entry.ID, entry.UserID, entry.EntryDate, entry.Prompt,
		entry.Content, entry.Mood, entry.CreatedAt, entry.UpdatedAt,
	)
	return err
}

func (r *JournalRepository) Update(ctx context.Context, id, userID uuid.UUID, input domain.UpdateJournalInput) error {
	// Scope by user_id as well as id — otherwise any authenticated user
	// could overwrite another user's entry by guessing its id (IDOR).
	res, err := r.db.ExecContext(ctx,
		`UPDATE journal_entries SET
		 content = COALESCE($1, content),
		 mood = COALESCE($2, mood),
		 updated_at = $3
		 WHERE id = $4 AND user_id = $5`,
		input.Content, input.Mood, time.Now(), id, userID,
	)
	if err != nil {
		return err
	}
	n, err := res.RowsAffected()
	if err != nil {
		return err
	}
	if n == 0 {
		return repository.ErrJournalEntryNotFound
	}
	return nil
}

func (r *JournalRepository) List(ctx context.Context, userID uuid.UUID, limit, offset int) ([]domain.JournalEntry, error) {
	var entries []domain.JournalEntry
	err := r.db.SelectContext(ctx, &entries,
		`SELECT * FROM journal_entries WHERE user_id = $1
		 ORDER BY entry_date DESC LIMIT $2 OFFSET $3`,
		userID, limit, offset,
	)
	return entries, err
}

func (r *JournalRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.JournalEntry, error) {
	var entry domain.JournalEntry
	err := r.db.GetContext(ctx, &entry,
		`SELECT * FROM journal_entries WHERE id = $1`, id,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &entry, err
}
