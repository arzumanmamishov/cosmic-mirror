package middleware

import "testing"

func TestIsAdminEmail(t *testing.T) {
	allowed := map[string]bool{"owner@livelyapp.co": true}
	tests := map[string]bool{
		"owner@livelyapp.co":     true,
		"  Owner@LivelyApp.co  ": true, // case/space-insensitive
		"someone@livelyapp.co":   false,
		"":                       false,
	}
	for email, want := range tests {
		if got := IsAdminEmail(allowed, email); got != want {
			t.Errorf("IsAdminEmail(%q) = %v, want %v", email, got, want)
		}
	}
	if IsAdminEmail(map[string]bool{}, "owner@livelyapp.co") {
		t.Error("empty allow-list must deny everyone")
	}
}
