package handler

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"cosmic-mirror/internal/domain"

	"github.com/google/uuid"
)

type fakeJournalRepo struct{ created int }

func (f *fakeJournalRepo) Create(context.Context, *domain.JournalEntry) error {
	f.created++
	return nil
}
func (f *fakeJournalRepo) Update(context.Context, uuid.UUID, uuid.UUID, domain.UpdateJournalInput) error {
	return nil
}
func (f *fakeJournalRepo) List(context.Context, uuid.UUID, int, int) ([]domain.JournalEntry, error) {
	return nil, nil
}
func (f *fakeJournalRepo) GetByID(context.Context, uuid.UUID) (*domain.JournalEntry, error) {
	return nil, nil
}

// The mood column is VARCHAR(10): longer moods must be a 400, not a DB
// error, while emoji moods (several bytes, one or two characters) pass.
func TestJournalCreateMoodLength(t *testing.T) {
	cases := []struct {
		mood string
		want int
	}{
		{"😊", http.StatusCreated},
		{"0123456789", http.StatusCreated},
		{"01234567890", http.StatusBadRequest},
	}
	for _, tc := range cases {
		repo := &fakeJournalRepo{}
		h := NewJournalHandler(repo)
		body := `{"content":"hello","mood":"` + tc.mood + `"}`
		req := httptest.NewRequest(http.MethodPost, "/journal", strings.NewReader(body))
		rec := httptest.NewRecorder()
		h.Create(rec, req)
		if rec.Code != tc.want {
			t.Fatalf("mood %q: status %d, want %d", tc.mood, rec.Code, tc.want)
		}
	}
}
