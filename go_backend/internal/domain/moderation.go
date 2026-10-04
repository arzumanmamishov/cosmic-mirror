package domain

import (
	"fmt"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/google/uuid"
)

// ===== Reports =====

// Report target types. Posts and comments can be auto-hidden; spaces and
// users can only be reported (a moderator then acts on them).
const (
	ReportTargetPost    = "post"
	ReportTargetComment = "comment"
	ReportTargetSpace   = "space"
	ReportTargetUser    = "user"
)

// Report statuses.
const (
	ReportStatusOpen      = "open"
	ReportStatusDismissed = "dismissed"
	ReportStatusActioned  = "actioned"
)

// Admin resolve actions.
const (
	ReportActionDismiss = "dismiss"
	ReportActionHide    = "hide"
	ReportActionDelete  = "delete"
	ReportActionBanUser = "ban_user"
)

// MaxReportDetailsRunes caps the free-text "details" of a report (the
// column also has a CHECK on it).
const MaxReportDetailsRunes = 1000

var reportTargetTypes = map[string]bool{
	ReportTargetPost: true, ReportTargetComment: true,
	ReportTargetSpace: true, ReportTargetUser: true,
}

var reportReasons = map[string]bool{
	"spam": true, "harassment": true, "hate": true, "sexual": true,
	"violence": true, "self_harm": true, "misinformation": true, "other": true,
}

var reportActions = map[string]bool{
	ReportActionDismiss: true, ReportActionHide: true,
	ReportActionDelete: true, ReportActionBanUser: true,
}

// ContentReport is one row of content_reports.
type ContentReport struct {
	ID           uuid.UUID  `db:"id"            json:"id"`
	ReporterID   uuid.UUID  `db:"reporter_id"   json:"reporter_id"`
	TargetType   string     `db:"target_type"   json:"target_type"`
	TargetID     uuid.UUID  `db:"target_id"     json:"target_id"`
	Reason       string     `db:"reason"        json:"reason"`
	Details      *string    `db:"details"       json:"details,omitempty"`
	Status       string     `db:"status"        json:"status"`
	CreatedAt    time.Time  `db:"created_at"    json:"created_at"`
	ReviewedAt   *time.Time `db:"reviewed_at"   json:"reviewed_at,omitempty"`
	ReviewedNote *string    `db:"reviewed_note" json:"reviewed_note,omitempty"`
}

// AdminReport is the moderation-queue shape: the report plus who filed
// it, a snippet of the reported content, and how many open reports the
// same target has collected.
type AdminReport struct {
	ContentReport
	ReporterEmail   string  `db:"reporter_email"    json:"reporter_email"`
	TargetSnippet   *string `db:"target_snippet"    json:"target_snippet,omitempty"`
	TargetOwnerID   *string `db:"target_owner_id"   json:"target_owner_id,omitempty"`
	TargetHidden    bool    `db:"target_hidden"     json:"target_hidden"`
	OpenReportCount int     `db:"open_report_count" json:"open_report_count"`
}

// CreateReportInput is the body of POST /reports.
type CreateReportInput struct {
	TargetType string    `json:"target_type"`
	TargetID   uuid.UUID `json:"target_id"`
	Reason     string    `json:"reason"`
	Details    *string   `json:"details"`
}

// Normalize trims the free-text fields and turns a blank details into nil.
func (in *CreateReportInput) Normalize() {
	in.TargetType = strings.ToLower(strings.TrimSpace(in.TargetType))
	in.Reason = strings.ToLower(strings.TrimSpace(in.Reason))
	if in.Details != nil {
		d := strings.TrimSpace(*in.Details)
		if d == "" {
			in.Details = nil
		} else {
			in.Details = &d
		}
	}
}

// Validate checks a (normalized) report. Errors wrap ErrValidation → 400.
func (in CreateReportInput) Validate() error {
	if !reportTargetTypes[in.TargetType] {
		return fmt.Errorf("%w: target_type must be one of post, comment, space, user", ErrValidation)
	}
	if in.TargetID == uuid.Nil {
		return fmt.Errorf("%w: target_id is required", ErrValidation)
	}
	if !reportReasons[in.Reason] {
		return fmt.Errorf("%w: reason must be one of spam, harassment, hate, sexual, violence, self_harm, misinformation, other", ErrValidation)
	}
	if in.Details != nil && utf8.RuneCountInString(*in.Details) > MaxReportDetailsRunes {
		return fmt.Errorf("%w: details must be at most %d characters", ErrValidation, MaxReportDetailsRunes)
	}
	return nil
}

// ResolveReportInput is the body of POST /admin/reports/{id}/resolve.
type ResolveReportInput struct {
	Action string  `json:"action"`
	Note   *string `json:"note"`
}

// Validate checks the action. Errors wrap ErrValidation → 400.
func (in ResolveReportInput) Validate() error {
	if !reportActions[in.Action] {
		return fmt.Errorf("%w: action must be one of dismiss, hide, delete, ban_user", ErrValidation)
	}
	if in.Note != nil && utf8.RuneCountInString(*in.Note) > MaxReportDetailsRunes {
		return fmt.Errorf("%w: note must be at most %d characters", ErrValidation, MaxReportDetailsRunes)
	}
	return nil
}

// ValidReportStatus reports whether s is a known report status (used to
// validate the admin list filter).
func ValidReportStatus(s string) bool {
	return s == ReportStatusOpen || s == ReportStatusDismissed || s == ReportStatusActioned
}

// ShouldAutoHide reports whether a post/comment with [openReports]
// distinct open reports must be hidden. A threshold below 1 disables
// auto-hide; only posts and comments can be hidden.
func ShouldAutoHide(targetType string, openReports, threshold int) bool {
	if threshold < 1 {
		return false
	}
	if targetType != ReportTargetPost && targetType != ReportTargetComment {
		return false
	}
	return openReports >= threshold
}

// ===== Blocks =====

// BlockedUser is one entry of GET /users/me/blocks.
type BlockedUser struct {
	UserID    uuid.UUID `db:"user_id"    json:"user_id"`
	Name      string    `db:"name"       json:"name"`
	AvatarURL *string   `db:"avatar_url" json:"avatar_url,omitempty"`
	BlockedAt time.Time `db:"blocked_at" json:"blocked_at"`
}
