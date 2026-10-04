package service

import (
	"strings"
	"testing"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/repository/postgres"

	"github.com/google/uuid"
)

func TestCanModerateSpace(t *testing.T) {
	tests := []struct {
		role, status string
		want         bool
	}{
		{"owner", "approved", true},
		{"mod", "approved", true},
		{"member", "approved", false},
		{"owner", "pending", false},
		{"", "", false}, // no membership row
	}
	for _, tt := range tests {
		if got := canModerateSpace(tt.role, tt.status); got != tt.want {
			t.Errorf("canModerateSpace(%q, %q) = %v, want %v", tt.role, tt.status, got, tt.want)
		}
	}
}

func TestBuildReportEmail(t *testing.T) {
	owner := uuid.New()
	details := "keeps posting links"
	rep := domain.ContentReport{
		ID: uuid.New(), ReporterID: uuid.New(), TargetType: "post",
		TargetID: uuid.New(), Reason: "spam", Details: &details,
	}
	target := &postgres.ReportTarget{OwnerID: &owner, Snippet: "buy cheap followers " + strings.Repeat("x", 2000)}
	msg := buildReportEmail("mod@example.com", rep, target, 3, true)

	if msg.To != "mod@example.com" {
		t.Fatalf("To = %q", msg.To)
	}
	if !strings.Contains(msg.Subject, "post") || !strings.Contains(msg.Subject, "spam") {
		t.Errorf("subject missing target/reason: %q", msg.Subject)
	}
	for _, want := range []string{
		rep.ID.String(), rep.TargetID.String(), rep.ReporterID.String(), owner.String(),
		"keeps posting links", "buy cheap followers", "Open reports:  3", "auto-hidden",
		"/api/v1/admin/reports/" + rep.ID.String() + "/resolve",
	} {
		if !strings.Contains(msg.TextBody, want) {
			t.Errorf("body missing %q", want)
		}
	}
	// The snippet is capped so a 5000-char post doesn't become a 5000-char e-mail.
	if strings.Count(msg.TextBody, "x") > 1100 {
		t.Error("snippet not truncated")
	}
}
