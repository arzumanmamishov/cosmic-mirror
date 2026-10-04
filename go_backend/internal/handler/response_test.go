package handler

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"testing"

	"cosmic-mirror/internal/domain"
)

func TestRespondServiceError(t *testing.T) {
	cases := []struct {
		err      error
		wantCode int
		wantMsg  string
	}{
		{fmt.Errorf("%w: birth_date must be YYYY-MM-DD", domain.ErrValidation), 400, "Birth_date must be YYYY-MM-DD"},
		{fmt.Errorf("create profile: %w", fmt.Errorf("%w: şehir is required", domain.ErrValidation)), 400, "Şehir is required"},
		{domain.ErrValidation, 400, "Invalid input"},
		{errors.New(`pq: duplicate key value violates unique constraint "x"`), 500, "Something went wrong. Please try again."},
	}
	for _, tc := range cases {
		rec := httptest.NewRecorder()
		respondServiceError(rec, http.StatusInternalServerError, "x_error", tc.err)
		if rec.Code != tc.wantCode {
			t.Fatalf("%v: status %d, want %d", tc.err, rec.Code, tc.wantCode)
		}
		var body errorResponse
		_ = json.Unmarshal(rec.Body.Bytes(), &body)
		if body.Error.Message != tc.wantMsg {
			t.Fatalf("%v: message %q, want %q", tc.err, body.Error.Message, tc.wantMsg)
		}
	}
}
