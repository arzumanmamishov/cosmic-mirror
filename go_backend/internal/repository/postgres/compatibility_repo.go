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

type CompatibilityRepository struct {
	db *sqlx.DB
}

func NewCompatibilityRepository(db *sqlx.DB) *CompatibilityRepository {
	return &CompatibilityRepository{db: db}
}

func (r *CompatibilityRepository) Create(ctx context.Context, report *domain.CompatibilityReport) error {
	report.ID = uuid.New()
	report.CreatedAt = time.Now()

	_, err := r.db.ExecContext(ctx,
		`INSERT INTO compatibility_reports (id, user_id, saved_person_id,
		 emotional_score, communication_score, chemistry_score,
		 conflict_patterns, advice, full_report, created_at)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
		report.ID, report.UserID, report.SavedPersonID,
		report.EmotionalScore, report.CommunicationScore, report.ChemistryScore,
		report.ConflictPatterns, report.Advice, report.FullReport, report.CreatedAt,
	)
	return err
}

func (r *CompatibilityRepository) GetByUserAndPerson(ctx context.Context, userID, personID uuid.UUID) (*domain.CompatibilityReport, error) {
	var report domain.CompatibilityReport
	err := r.db.GetContext(ctx, &report,
		`SELECT cr.*, sp.name as person_name
		 FROM compatibility_reports cr
		 JOIN saved_people sp ON sp.id = cr.saved_person_id
		 WHERE cr.user_id = $1 AND cr.saved_person_id = $2
		 ORDER BY cr.created_at DESC LIMIT 1`,
		userID, personID,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	if err == nil {
		report.CalculateOverall()
	}
	return &report, err
}

// SavedPeople methods

type SavedPeopleRepository struct {
	db *sqlx.DB
}

func NewSavedPeopleRepository(db *sqlx.DB) *SavedPeopleRepository {
	return &SavedPeopleRepository{db: db}
}

func (r *SavedPeopleRepository) Create(ctx context.Context, person *domain.SavedPerson) error {
	person.ID = uuid.New()
	person.CreatedAt = time.Now()

	_, err := r.db.ExecContext(ctx,
		`INSERT INTO saved_people (id, user_id, name, birth_date, birth_time,
		 birth_time_known, birth_place, latitude, longitude, timezone, created_at)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
		person.ID, person.UserID, person.Name, person.BirthDate, person.BirthTime,
		person.BirthTimeKnown, person.BirthPlace, person.Latitude,
		person.Longitude, person.Timezone, person.CreatedAt,
	)
	return err
}

func (r *SavedPeopleRepository) List(ctx context.Context, userID uuid.UUID) ([]domain.SavedPerson, error) {
	var people []domain.SavedPerson
	err := r.db.SelectContext(ctx, &people,
		`SELECT * FROM saved_people WHERE user_id = $1 ORDER BY created_at DESC`, userID,
	)
	return people, err
}

func (r *SavedPeopleRepository) GetByID(ctx context.Context, id uuid.UUID) (*domain.SavedPerson, error) {
	var person domain.SavedPerson
	err := r.db.GetContext(ctx, &person, `SELECT * FROM saved_people WHERE id = $1`, id)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &person, err
}

func (r *SavedPeopleRepository) Delete(ctx context.Context, id uuid.UUID) error {
	_, err := r.db.ExecContext(ctx, `DELETE FROM saved_people WHERE id = $1`, id)
	return err
}
