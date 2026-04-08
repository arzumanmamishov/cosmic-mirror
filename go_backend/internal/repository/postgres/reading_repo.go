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

type ReadingRepository struct {
	db *sqlx.DB
}

func NewReadingRepository(db *sqlx.DB) *ReadingRepository {
	return &ReadingRepository{db: db}
}

func (r *ReadingRepository) GetByUserAndDate(ctx context.Context, userID uuid.UUID, date time.Time) (*domain.DailyReading, error) {
	var reading domain.DailyReading
	err := r.db.GetContext(ctx, &reading,
		`SELECT * FROM daily_readings WHERE user_id = $1 AND reading_date = $2`,
		userID, date.Format("2006-01-02"),
	)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, nil
	}
	return &reading, err
}

func (r *ReadingRepository) Create(ctx context.Context, reading *domain.DailyReading) error {
	reading.ID = uuid.New()
	reading.CreatedAt = time.Now()

	_, err := r.db.ExecContext(ctx,
		`INSERT INTO daily_readings (id, user_id, reading_date, sun_sign, moon_sign,
		 rising_sign, energy_level, emotional, love, career, health, caution,
		 action, affirmation, lucky_color, lucky_number, created_at)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17)`,
		reading.ID, reading.UserID, reading.ReadingDate, reading.SunSign,
		reading.MoonSign, reading.RisingSign, reading.EnergyLevel,
		reading.Emotional, reading.Love, reading.Career, reading.Health,
		reading.Caution, reading.Action, reading.Affirmation,
		reading.LuckyColor, reading.LuckyNumber, reading.CreatedAt,
	)
	return err
}

func (r *ReadingRepository) ListByUserAndDateRange(ctx context.Context, userID uuid.UUID, start, end time.Time) ([]domain.DailyReading, error) {
	var readings []domain.DailyReading
	err := r.db.SelectContext(ctx, &readings,
		`SELECT * FROM daily_readings
		 WHERE user_id = $1 AND reading_date BETWEEN $2 AND $3
		 ORDER BY reading_date DESC`,
		userID, start.Format("2006-01-02"), end.Format("2006-01-02"),
	)
	return readings, err
}
