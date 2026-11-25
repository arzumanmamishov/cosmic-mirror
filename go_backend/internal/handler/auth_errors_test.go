package handler

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"cosmic-mirror/internal/service"
)

func TestWriteAuthErrorCodes(t *testing.T) {
	tests := []struct {
		err        error
		wantStatus int
		wantCode   string
	}{
		// The app signs a banned user out on this code, the same one the
		// auth middleware sends for an existing session.
		{service.ErrAuthAccountBanned, http.StatusForbidden, "account_banned"},
		{service.ErrAuthEmailInUse, http.StatusConflict, "email_in_use"},
		{service.ErrAuthUserNotFound, http.StatusNotFound, "user_not_found"},
		{service.ErrOTPInvalid, http.StatusBadRequest, "invalid_code"},
	}
	for _, tt := range tests {
		rec := httptest.NewRecorder()
		(&AuthHandler{}).writeAuthError(rec, tt.err)
		if rec.Code != tt.wantStatus {
			t.Errorf("%v: status = %d, want %d", tt.err, rec.Code, tt.wantStatus)
		}
		var body errorResponse
		if err := json.Unmarshal(rec.Body.Bytes(), &body); err != nil {
			t.Fatalf("%v: body isn't JSON: %v", tt.err, err)
		}
		if body.Error.Code != tt.wantCode {
			t.Errorf("%v: code = %q, want %q", tt.err, body.Error.Code, tt.wantCode)
		}
		if body.Error.Message == "" {
			t.Errorf("%v: empty message", tt.err)
		}
	}
}
