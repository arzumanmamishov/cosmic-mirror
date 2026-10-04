package domain

import (
	"errors"
	"strings"
	"testing"

	"github.com/google/uuid"
)

func strPtr(s string) *string { return &s }

func TestCreateReportInputValidate(t *testing.T) {
	id := uuid.New()
	tests := []struct {
		name    string
		in      CreateReportInput
		wantErr bool
	}{
		{"valid post", CreateReportInput{TargetType: "post", TargetID: id, Reason: "spam"}, false},
		{"valid user with details", CreateReportInput{TargetType: "user", TargetID: id, Reason: "harassment", Details: strPtr("rude")}, false},
		{"mixed case + spaces normalized", CreateReportInput{TargetType: " Comment ", TargetID: id, Reason: "SELF_HARM"}, false},
		{"unknown target type", CreateReportInput{TargetType: "journal", TargetID: id, Reason: "spam"}, true},
		{"missing target id", CreateReportInput{TargetType: "post", Reason: "spam"}, true},
		{"unknown reason", CreateReportInput{TargetType: "space", TargetID: id, Reason: "boring"}, true},
		{"details too long", CreateReportInput{TargetType: "post", TargetID: id, Reason: "other", Details: strPtr(strings.Repeat("ş", MaxReportDetailsRunes+1))}, true},
		{"details at limit (runes, not bytes)", CreateReportInput{TargetType: "post", TargetID: id, Reason: "other", Details: strPtr(strings.Repeat("ş", MaxReportDetailsRunes))}, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			in := tt.in
			in.Normalize()
			err := in.Validate()
			if (err != nil) != tt.wantErr {
				t.Fatalf("Validate() error = %v, wantErr %v", err, tt.wantErr)
			}
			if err != nil && !errors.Is(err, ErrValidation) {
				t.Fatalf("error %v does not wrap ErrValidation", err)
			}
		})
	}
}

func TestCreateReportInputNormalizeBlankDetails(t *testing.T) {
	in := CreateReportInput{Details: strPtr("   ")}
	in.Normalize()
	if in.Details != nil {
		t.Fatalf("blank details should become nil, got %q", *in.Details)
	}
	in = CreateReportInput{Details: strPtr("  spam link  ")}
	in.Normalize()
	if in.Details == nil || *in.Details != "spam link" {
		t.Fatalf("details not trimmed: %v", in.Details)
	}
}

func TestResolveReportInputValidate(t *testing.T) {
	for _, a := range []string{"dismiss", "hide", "delete", "ban_user"} {
		if err := (ResolveReportInput{Action: a}).Validate(); err != nil {
			t.Errorf("action %q rejected: %v", a, err)
		}
	}
	for _, a := range []string{"", "ban", "DELETE!", "approve"} {
		err := (ResolveReportInput{Action: a}).Validate()
		if err == nil || !errors.Is(err, ErrValidation) {
			t.Errorf("action %q: want ErrValidation, got %v", a, err)
		}
	}
	long := strings.Repeat("x", MaxReportDetailsRunes+1)
	if err := (ResolveReportInput{Action: "hide", Note: &long}).Validate(); err == nil {
		t.Error("over-long note accepted")
	}
}

func TestShouldAutoHide(t *testing.T) {
	tests := []struct {
		targetType string
		reports    int
		threshold  int
		want       bool
	}{
		{"post", 2, 3, false},
		{"post", 3, 3, true},
		{"comment", 4, 3, true},
		{"comment", 1, 1, true},
		{"space", 10, 3, false}, // spaces are never auto-hidden
		{"user", 10, 3, false},
		{"post", 100, 0, false}, // threshold < 1 disables auto-hide
		{"post", 100, -1, false},
	}
	for _, tt := range tests {
		if got := ShouldAutoHide(tt.targetType, tt.reports, tt.threshold); got != tt.want {
			t.Errorf("ShouldAutoHide(%q, %d, %d) = %v, want %v", tt.targetType, tt.reports, tt.threshold, got, tt.want)
		}
	}
}

func TestValidReportStatus(t *testing.T) {
	for _, s := range []string{"open", "dismissed", "actioned"} {
		if !ValidReportStatus(s) {
			t.Errorf("%q should be valid", s)
		}
	}
	for _, s := range []string{"", "closed", "OPEN"} {
		if ValidReportStatus(s) {
			t.Errorf("%q should be invalid", s)
		}
	}
}
