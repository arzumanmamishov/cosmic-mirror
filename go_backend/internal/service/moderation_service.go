package service

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"cosmic-mirror/internal/domain"
	"cosmic-mirror/internal/pkg/mailer"
	"cosmic-mirror/internal/repository"
	"cosmic-mirror/internal/repository/postgres"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
)

// ModerationService implements the user-generated-content safety features
// App Store guideline 1.2 / Google Play's UGC policy require: reporting,
// blocking, auto-hiding repeatedly reported content, e-mailing the
// moderation inbox about every new report, and the admin actions that
// resolve reports (dismiss / hide / delete / ban).
type ModerationService struct {
	db            *sqlx.DB
	modRepo       *postgres.ModerationRepository
	postRepo      *postgres.PostRepository
	commentRepo   *postgres.CommentRepository
	spaceRepo     *postgres.SpaceRepository
	hashtagRepo   *postgres.HashtagRepository
	userRepo      repository.UserRepository
	refreshTokens repository.RefreshTokenRepository
	mail          mailer.Mailer
	cfg           ModerationConfig
}

// ModerationConfig carries the env-driven moderation settings.
type ModerationConfig struct {
	// Email receives one message per new report (MODERATION_EMAIL).
	// Empty = no e-mails (reports are still stored and auto-hide works).
	Email string
	// AutoHideThreshold is the number of distinct open reports after
	// which a post/comment is hidden (MODERATION_AUTOHIDE_THRESHOLD).
	// Below 1 disables auto-hide.
	AutoHideThreshold int
}

func NewModerationService(
	db *sqlx.DB,
	modRepo *postgres.ModerationRepository,
	postRepo *postgres.PostRepository,
	commentRepo *postgres.CommentRepository,
	spaceRepo *postgres.SpaceRepository,
	hashtagRepo *postgres.HashtagRepository,
	userRepo repository.UserRepository,
	refreshTokens repository.RefreshTokenRepository,
	mail mailer.Mailer,
	cfg ModerationConfig,
) *ModerationService {
	return &ModerationService{
		db: db, modRepo: modRepo, postRepo: postRepo, commentRepo: commentRepo,
		spaceRepo: spaceRepo, hashtagRepo: hashtagRepo, userRepo: userRepo,
		refreshTokens: refreshTokens, mail: mail, cfg: cfg,
	}
}

var (
	ErrReportTargetNotFound = errors.New("reported content not found")
	ErrReportNotFound       = errors.New("report not found")
)

// moderationEmailTimeout bounds the async moderation-inbox e-mail.
const moderationEmailTimeout = 30 * time.Second

// CreateReport files a report. created=false means the reporter had
// already reported this target (the existing report is returned; the
// call is idempotent).
func (s *ModerationService) CreateReport(ctx context.Context, reporterID uuid.UUID, in domain.CreateReportInput) (*domain.ContentReport, bool, error) {
	in.Normalize()
	if err := in.Validate(); err != nil {
		return nil, false, err
	}
	target, err := s.modRepo.GetReportTarget(ctx, in.TargetType, in.TargetID)
	if err != nil {
		return nil, false, err
	}
	if target == nil {
		return nil, false, ErrReportTargetNotFound
	}
	if target.OwnerID != nil && *target.OwnerID == reporterID {
		return nil, false, fmt.Errorf("%w: you can't report your own content", domain.ErrValidation)
	}

	rep := &domain.ContentReport{
		ReporterID: reporterID,
		TargetType: in.TargetType,
		TargetID:   in.TargetID,
		Reason:     in.Reason,
		Details:    in.Details,
	}
	created, err := s.modRepo.CreateReport(ctx, rep)
	if err != nil {
		return nil, false, err
	}
	if !created {
		return rep, false, nil
	}

	// Auto-hide once enough distinct users have reported it. A failure
	// here must not fail the report itself — it's stored, and the
	// moderator still gets the e-mail.
	openReports, hidden := 0, false
	if n, err := s.modRepo.CountOpenReports(ctx, rep.TargetType, rep.TargetID); err != nil {
		slog.Error("moderation: count open reports", "error", err, "target_type", rep.TargetType, "target_id", rep.TargetID)
	} else {
		openReports = n
		if domain.ShouldAutoHide(rep.TargetType, n, s.cfg.AutoHideThreshold) {
			if err := s.modRepo.SetHidden(ctx, s.db, rep.TargetType, rep.TargetID, true); err != nil {
				slog.Error("moderation: auto-hide", "error", err, "target_type", rep.TargetType, "target_id", rep.TargetID)
			} else {
				hidden = true
				slog.Info("moderation: auto-hid reported content",
					"target_type", rep.TargetType, "target_id", rep.TargetID, "open_reports", n)
			}
		}
	}

	slog.Info("moderation: new report",
		"report_id", rep.ID, "target_type", rep.TargetType, "target_id", rep.TargetID, "reason", rep.Reason)

	// Detach from the request (about to be cancelled) but bound the work.
	go s.emailModerators(context.WithoutCancel(ctx), *rep, target, openReports, hidden)
	return rep, true, nil
}

func (s *ModerationService) emailModerators(parent context.Context, rep domain.ContentReport, target *postgres.ReportTarget, openReports int, hidden bool) {
	to := strings.TrimSpace(s.cfg.Email)
	if to == "" || s.mail == nil {
		return
	}
	ctx, cancel := context.WithTimeout(parent, moderationEmailTimeout)
	defer cancel()
	msg := buildReportEmail(to, rep, target, openReports, hidden)
	if err := s.mail.Send(ctx, msg); err != nil {
		slog.Error("moderation: report e-mail failed", "error", err, "report_id", rep.ID)
	}
}

// buildReportEmail renders the moderation-inbox message for a new report.
func buildReportEmail(to string, rep domain.ContentReport, target *postgres.ReportTarget, openReports int, hidden bool) mailer.Message {
	details := "(none)"
	if rep.Details != nil {
		details = *rep.Details
	}
	owner := "(none)"
	snippet := ""
	if target != nil {
		if target.OwnerID != nil {
			owner = target.OwnerID.String()
		}
		snippet = truncateRunes(target.Snippet, 1000, "…")
	}
	hiddenLine := "no"
	if hidden {
		hiddenLine = "YES — auto-hidden from everyone but its author"
	}
	var b strings.Builder
	b.WriteString("A new community report needs review. Apple and Google expect action within 24 hours.\n\n")
	fmt.Fprintf(&b, "Report ID:     %s\n", rep.ID)
	fmt.Fprintf(&b, "Target:        %s %s\n", rep.TargetType, rep.TargetID)
	if target != nil && target.PostID != nil {
		fmt.Fprintf(&b, "On post:       %s\n", target.PostID)
	}
	fmt.Fprintf(&b, "Reason:        %s\n", rep.Reason)
	fmt.Fprintf(&b, "Details:       %s\n", details)
	fmt.Fprintf(&b, "Reporter ID:   %s\n", rep.ReporterID)
	fmt.Fprintf(&b, "Target owner:  %s\n", owner)
	fmt.Fprintf(&b, "Open reports:  %d\n", openReports)
	fmt.Fprintf(&b, "Hidden:        %s\n\n", hiddenLine)
	b.WriteString("Reported content:\n----------------\n")
	b.WriteString(snippet)
	b.WriteString("\n----------------\n\n")
	b.WriteString("Resolve (admin token required):\n")
	fmt.Fprintf(&b, "  POST /api/v1/admin/reports/%s/resolve\n", rep.ID)
	b.WriteString(`  {"action": "dismiss" | "hide" | "delete" | "ban_user", "note": "..."}` + "\n")
	b.WriteString("Queue: GET /api/v1/admin/reports?status=open\n")
	return mailer.Message{
		To:       to,
		Subject:  fmt.Sprintf("[Lively moderation] New report: %s — %s", rep.TargetType, rep.Reason),
		TextBody: b.String(),
	}
}

// ===== Blocks =====

// Block makes [blockerID] and [blockedID] invisible to each other in the
// community. Idempotent.
func (s *ModerationService) Block(ctx context.Context, blockerID, blockedID uuid.UUID) error {
	if blockerID == blockedID {
		return fmt.Errorf("%w: you can't block yourself", domain.ErrValidation)
	}
	u, err := s.userRepo.GetByID(ctx, blockedID)
	if err != nil {
		return err
	}
	if u == nil {
		return ErrUserNotFound
	}
	return s.modRepo.Block(ctx, blockerID, blockedID)
}

// Unblock is idempotent — unblocking someone not blocked is a no-op.
func (s *ModerationService) Unblock(ctx context.Context, blockerID, blockedID uuid.UUID) error {
	return s.modRepo.Unblock(ctx, blockerID, blockedID)
}

func (s *ModerationService) ListBlocks(ctx context.Context, blockerID uuid.UUID) ([]domain.BlockedUser, error) {
	return s.modRepo.ListBlocks(ctx, blockerID)
}

// ===== Admin =====

func (s *ModerationService) ListReports(ctx context.Context, status string, limit, offset int) ([]domain.AdminReport, error) {
	if status == "" {
		status = domain.ReportStatusOpen
	}
	if !domain.ValidReportStatus(status) {
		return nil, fmt.Errorf("%w: status must be open, dismissed or actioned", domain.ErrValidation)
	}
	return s.modRepo.ListReports(ctx, status, limit, offset)
}

// ResolveReport applies a moderator decision to the report's target and
// closes every open report on that target:
//
//   - dismiss:  no violation; un-hides an auto-hidden post/comment.
//   - hide:     hides a post/comment (kept for the author / audit).
//   - delete:   deletes the post / comment / space.
//   - ban_user: bans the target's owner (author, space creator, or the
//     reported user), revokes their sessions, and hides all of their
//     content via the banned_at filter.
func (s *ModerationService) ResolveReport(ctx context.Context, reportID uuid.UUID, in domain.ResolveReportInput) (*domain.ContentReport, error) {
	in.Action = strings.ToLower(strings.TrimSpace(in.Action))
	if err := in.Validate(); err != nil {
		return nil, err
	}
	rep, err := s.modRepo.GetReport(ctx, reportID)
	if err != nil {
		return nil, err
	}
	if rep == nil {
		return nil, ErrReportNotFound
	}

	status := domain.ReportStatusActioned
	switch in.Action {
	case domain.ReportActionDismiss:
		status = domain.ReportStatusDismissed
		if isHideable(rep.TargetType) {
			if err := s.modRepo.SetHidden(ctx, s.db, rep.TargetType, rep.TargetID, false); err != nil {
				return nil, err
			}
		}
	case domain.ReportActionHide:
		if !isHideable(rep.TargetType) {
			return nil, fmt.Errorf("%w: hide applies to posts and comments; use delete or ban_user", domain.ErrValidation)
		}
		if err := s.modRepo.SetHidden(ctx, s.db, rep.TargetType, rep.TargetID, true); err != nil {
			return nil, err
		}
	case domain.ReportActionDelete:
		if err := s.deleteTarget(ctx, rep); err != nil {
			return nil, err
		}
	case domain.ReportActionBanUser:
		if err := s.banTargetOwner(ctx, rep); err != nil {
			return nil, err
		}
	}

	if err := s.modRepo.ResolveReports(ctx, s.db, rep, status, in.Note); err != nil {
		return nil, err
	}
	slog.Info("moderation: report resolved",
		"report_id", rep.ID, "action", in.Action, "target_type", rep.TargetType, "target_id", rep.TargetID)
	return s.modRepo.GetReport(ctx, reportID)
}

func isHideable(targetType string) bool {
	return targetType == domain.ReportTargetPost || targetType == domain.ReportTargetComment
}

// deleteTarget removes the reported content. Already-deleted content is
// not an error (the report is still closed).
func (s *ModerationService) deleteTarget(ctx context.Context, rep *domain.ContentReport) error {
	switch rep.TargetType {
	case domain.ReportTargetPost:
		return postgres.WithTx(ctx, s.db, func(tx *sqlx.Tx) error {
			if err := s.hashtagRepo.UnlinkPost(ctx, tx, rep.TargetID); err != nil {
				return err
			}
			// Same tx as UnlinkPost — see PostService.Delete.
			return s.postRepo.DeleteTx(ctx, tx, rep.TargetID)
		})
	case domain.ReportTargetComment:
		c, err := s.commentRepo.GetBareByID(ctx, rep.TargetID)
		if err != nil || c == nil {
			return err
		}
		if err := s.commentRepo.Delete(ctx, rep.TargetID); err != nil {
			return err
		}
		return s.postRepo.RecountComments(ctx, s.db, c.PostID)
	case domain.ReportTargetSpace:
		return s.spaceRepo.Delete(ctx, rep.TargetID)
	default:
		return fmt.Errorf("%w: a user can't be deleted from here; use ban_user", domain.ErrValidation)
	}
}

func (s *ModerationService) banTargetOwner(ctx context.Context, rep *domain.ContentReport) error {
	target, err := s.modRepo.GetReportTarget(ctx, rep.TargetType, rep.TargetID)
	if err != nil {
		return err
	}
	if target == nil || target.OwnerID == nil {
		return ErrReportTargetNotFound
	}
	userID := *target.OwnerID
	if err := s.modRepo.BanUser(ctx, s.db, userID); err != nil {
		return err
	}
	// Access tokens die at the auth middleware's banned_at check; also
	// revoke refresh tokens so the app can't keep minting new ones.
	if s.refreshTokens != nil {
		if err := s.refreshTokens.RevokeAllForUser(ctx, userID); err != nil {
			slog.Error("moderation: revoke sessions of banned user", "error", err, "user_id", userID)
		}
	}
	slog.Warn("moderation: user banned", "user_id", userID, "report_id", rep.ID)
	return nil
}
