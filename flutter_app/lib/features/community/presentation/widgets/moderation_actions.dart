import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_tokens.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/core/error/error_message.dart';
import 'package:cosmic_mirror/features/community/data/repositories/community_repository.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Report / block / delete affordances for community content (App Store
// guideline 1.2, Google Play UGC policy). Every post, comment, space and
// profile reaches these through a "more" menu.

/// One row of the "more" bottom sheet.
class ContentAction {
  const ContentAction({
    required this.icon,
    required this.label,
    required this.onSelected,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;
  final bool destructive;
}

/// Small "…" button that opens [showContentActions]. Renders nothing when
/// there are no actions.
class ContentMoreButton extends StatelessWidget {
  const ContentMoreButton({
    required this.actions,
    this.size = 18,
    super.key,
  });

  final List<ContentAction> Function() actions;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IconButton(
      tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      icon: Icon(Icons.more_horiz_rounded, size: size, color: p.textDim),
      onPressed: () => showContentActions(context, actions()),
    );
  }
}

/// Bottom-sheet menu in the same style as the space overflow menu.
Future<void> showContentActions(
  BuildContext context,
  List<ContentAction> actions,
) async {
  if (actions.isEmpty) return;
  final p = context.palette;
  final picked = await showModalBottomSheet<ContentAction>(
    context: context,
    backgroundColor: p.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(LivelyRadius.xl2)),
    ),
    builder: (sheetCtx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final a in actions)
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: (a.destructive ? p.error : p.primary)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(LivelyRadius.md),
                  ),
                  child: Icon(
                    a.icon,
                    color: a.destructive ? p.error : p.primary,
                    size: 19,
                  ),
                ),
                title: Text(
                  a.label,
                  style: LivelyType.body(
                    a.destructive ? p.error : p.textPrimary,
                  ).copyWith(fontWeight: FontWeight.w500),
                ),
                onTap: () => Navigator.pop(sheetCtx, a),
              ),
          ],
        ),
      ),
    ),
  );
  // Run after the sheet is gone so follow-up sheets / dialogs open on
  // the page, not on top of the closing sheet.
  picked?.onSelected();
}

/// Menu entries for someone else's content: report it, and block its
/// author. [onBlocked] runs after a successful block (e.g. to pop a screen
/// that only showed that user's content).
List<ContentAction> reportAndBlockActions(
  BuildContext context, {
  required ReportTarget target,
  required String targetId,
  required String authorId,
  required String authorName,
  VoidCallback? onBlocked,
}) {
  final l = AppLocalizations.of(context);
  final reportLabel = switch (target) {
    ReportTarget.post => l.reportPost,
    ReportTarget.comment => l.reportComment,
    ReportTarget.space => l.reportSpace,
    ReportTarget.user => l.reportUser,
  };
  return [
    ContentAction(
      icon: Icons.flag_outlined,
      label: reportLabel,
      onSelected: () =>
          showReportSheet(context, target: target, targetId: targetId),
    ),
    if (authorId.isNotEmpty)
      ContentAction(
        icon: Icons.block_rounded,
        label: l.blockUserMenu,
        destructive: true,
        onSelected: () async {
          final blocked = await confirmAndBlockUser(
            context,
            userId: authorId,
            name: authorName,
          );
          if (blocked) onBlocked?.call();
        },
      ),
  ];
}

/// Opens the report sheet; on success shows the "we'll review within 24
/// hours" confirmation.
Future<void> showReportSheet(
  BuildContext context, {
  required ReportTarget target,
  required String targetId,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final thanks = AppLocalizations.of(context).reportThanks;
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ReportSheet(target: target, targetId: targetId),
  );
  if (sent ?? false) {
    messenger.showSnackBar(SnackBar(content: Text(thanks)));
  }
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.target, required this.targetId});

  final ReportTarget target;
  final String targetId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  final _details = TextEditingController();
  ReportReason? _reason;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  String _reasonLabel(AppLocalizations l, ReportReason r) => switch (r) {
        ReportReason.spam => l.reportReasonSpam,
        ReportReason.harassment => l.reportReasonHarassment,
        ReportReason.hate => l.reportReasonHate,
        ReportReason.sexual => l.reportReasonSexual,
        ReportReason.violence => l.reportReasonViolence,
        ReportReason.selfHarm => l.reportReasonSelfHarm,
        ReportReason.misinformation => l.reportReasonMisinformation,
        ReportReason.other => l.reportReasonOther,
      };

  Future<void> _submit() async {
    final reason = _reason;
    if (reason == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(communityRepositoryProvider).report(
            target: widget.target,
            targetId: widget.targetId,
            reason: reason,
            details: _details.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = FriendlyError.from(context, e).body;
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final title = switch (widget.target) {
      ReportTarget.post => l.reportPost,
      ReportTarget.comment => l.reportComment,
      ReportTarget.space => l.reportSpace,
      ReportTarget.user => l.reportUser,
    };
    final canSubmit = _reason != null && !_busy;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.fromLTRB(20, 18, 20, 18 + bottomInset),
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: p.glassBorder),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: LivelyType.h1(p.textPrimary)),
              const SizedBox(height: 6),
              Text(
                l.reportSheetSubtitle,
                style: LivelyType.small(p.textMuted),
              ),
              const SizedBox(height: 12),
              for (final r in ReportReason.values)
                _ReasonRow(
                  label: _reasonLabel(l, r),
                  selected: _reason == r,
                  onTap: _busy
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          setState(() => _reason = r);
                        },
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: p.surfaceElevated,
                  borderRadius: BorderRadius.circular(LivelyRadius.md),
                ),
                child: TextField(
                  controller: _details,
                  enabled: !_busy,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 1000,
                  style: LivelyType.body(p.textPrimary),
                  decoration: InputDecoration(
                    hintText: l.reportDetailsHint,
                    hintStyle: LivelyType.body(p.textTertiary),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: p.error, fontSize: 12)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canSubmit ? _submit : null,
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(l.reportSubmit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LivelyRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 20,
              color: selected ? p.primary : p.textDim,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: LivelyType.body(p.textPrimary).copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Explains what blocking does, then blocks [userId]. Returns true when
/// the user was blocked; community lists are refetched so the blocked
/// user's content disappears right away.
Future<bool> confirmAndBlockUser(
  BuildContext context, {
  required String userId,
  required String name,
}) async {
  final l = AppLocalizations.of(context);
  // Captured up front: blocking removes the content this menu was opened
  // from, which may dispose the calling widget mid-request.
  final container = ProviderScope.containerOf(context, listen: false);
  final displayName = name.isEmpty ? l.communityUnknownUser : name;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) {
      final dl = AppLocalizations.of(dialogCtx);
      return AlertDialog(
        title: Text(dl.blockUserConfirmTitle(displayName)),
        content: Text(dl.blockUserConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(dl.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              dl.blockUserAction,
              style: TextStyle(color: dialogCtx.palette.error),
            ),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) return false;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await container.read(communityRepositoryProvider).blockUser(userId);
  } catch (e) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(FriendlyError.from(context, e).body)),
      );
    }
    return false;
  }
  invalidateAfterBlockChange(container.invalidate);
  messenger.showSnackBar(SnackBar(content: Text(l.blockUserDone(displayName))));
  return true;
}

/// Unblocks [userId] (no confirmation — it's the safe direction).
Future<bool> unblockUser(
  BuildContext context, {
  required String userId,
  required String name,
}) async {
  final l = AppLocalizations.of(context);
  final displayName = name.isEmpty ? l.communityUnknownUser : name;
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.of(context);
  try {
    await container.read(communityRepositoryProvider).unblockUser(userId);
  } catch (e) {
    if (context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(FriendlyError.from(context, e).body)),
      );
    }
    return false;
  }
  invalidateAfterBlockChange(container.invalidate);
  messenger
      .showSnackBar(SnackBar(content: Text(l.blockUnblockDone(displayName))));
  return true;
}

/// "Delete this …? This can't be undone." Returns true on confirm.
Future<bool> confirmDelete(BuildContext context, String title) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) {
      final dl = AppLocalizations.of(dialogCtx);
      return AlertDialog(
        title: Text(title),
        content: Text(dl.moderationDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: Text(dl.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: Text(
              dl.settingsDelete,
              style: TextStyle(color: dialogCtx.palette.error),
            ),
          ),
        ],
      );
    },
  );
  return confirmed ?? false;
}

/// Small "hidden while under review" banner shown to the author of
/// content moderation hid (nobody else receives it from the server).
class HiddenContentNotice extends StatelessWidget {
  const HiddenContentNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: p.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(LivelyRadius.md),
      ),
      child: Row(
        children: [
          Icon(Icons.visibility_off_outlined, size: 15, color: p.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).moderationHiddenNotice,
              style: LivelyType.caption(p.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
