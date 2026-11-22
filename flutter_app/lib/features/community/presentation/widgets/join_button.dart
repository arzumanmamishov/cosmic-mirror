import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/core/error/error_message.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tri-state join button: Join → Pending → Joined.
///
/// - **Join** (gradient): tapping sends a join REQUEST. Optimistically
///   flips to Pending until the request completes.
/// - **Pending** (muted, non-interactive): the owner hasn't approved
///   yet. Tapping is a no-op; we don't auto-leave because that would
///   silently cancel the request without confirmation.
/// - **Joined** (outlined): the user is an approved member. Tapping
///   leaves the space.
class JoinButton extends ConsumerStatefulWidget {
  const JoinButton({
    required this.spaceId,
    required this.initialJoined,
    required this.initialPending,
    this.ownerId,
    this.onChanged,
    this.compact = true,
    super.key,
  });

  final String spaceId;

  /// The space creator. When it is the current user the pill is shown as
  /// "Joined" but is not tappable — owners must not leave their own space.
  final String? ownerId;
  final bool initialJoined;
  final bool initialPending;
  final ValueChanged<JoinState>? onChanged;
  final bool compact;

  @override
  ConsumerState<JoinButton> createState() => _JoinButtonState();
}

enum JoinState { join, pending, joined }

class _JoinButtonState extends ConsumerState<JoinButton> {
  late JoinState _state = _initial();
  bool _busy = false;

  JoinState _initial() {
    if (widget.initialJoined) return JoinState.joined;
    if (widget.initialPending) return JoinState.pending;
    return JoinState.join;
  }

  @override
  void didUpdateWidget(covariant JoinButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follow fresh server state (e.g. after a refresh, or the owner
    // approving a request) instead of keeping the first value forever.
    if (!_busy &&
        (oldWidget.initialJoined != widget.initialJoined ||
            oldWidget.initialPending != widget.initialPending ||
            oldWidget.spaceId != widget.spaceId)) {
      _state = _initial();
    }
  }

  /// Lists / detail / my profile all show membership, so refetch them.
  void _invalidateMembership() {
    ref
      ..invalidate(spacesProvider)
      ..invalidate(categorySpacesProvider)
      ..invalidate(spaceDetailProvider(widget.spaceId))
      ..invalidate(userCommunityProfileProvider);
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(FriendlyError.from(context, e).body)),
    );
  }

  Future<bool> _confirmLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        final l = AppLocalizations.of(dialogCtx);
        final p = dialogCtx.palette;
        return AlertDialog(
          backgroundColor: p.surface,
          title: Text(l.cpsLeaveSpaceTitle),
          content: Text(l.cpsLeaveSpaceBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: Text(l.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              style: TextButton.styleFrom(foregroundColor: p.error),
              child: Text(l.communityLeaveSpace),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _tap() async {
    if (_busy) return;
    final repo = ref.read(communityRepositoryProvider);
    final prev = _state;
    switch (_state) {
      case JoinState.join:
        setState(() {
          _state = JoinState.pending;
          _busy = true;
        });
        try {
          await repo.joinSpace(widget.spaceId);
          _invalidateMembership();
          widget.onChanged?.call(JoinState.pending);
        } catch (e) {
          if (mounted) setState(() => _state = prev);
          _showError(e);
        } finally {
          if (mounted) setState(() => _busy = false);
        }
      case JoinState.pending:
        // Tapping a pending pill does nothing — request is in flight
        // with the owner. We could add a "Cancel request" action later
        // if users ask for it.
        break;
      case JoinState.joined:
        // Leaving a members-only space means re-requesting access, so
        // confirm first instead of leaving on a stray tap.
        _busy = true;
        final confirmed = await _confirmLeave();
        _busy = false;
        if (!confirmed || !mounted) return;
        setState(() {
          _state = JoinState.join;
          _busy = true;
        });
        try {
          await repo.leaveSpace(widget.spaceId);
          _invalidateMembership();
          widget.onChanged?.call(JoinState.join);
        } catch (e) {
          if (mounted) setState(() => _state = prev);
          _showError(e);
        } finally {
          if (mounted) setState(() => _busy = false);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final padH = widget.compact ? 14.0 : 18.0;
    final padV = widget.compact ? 6.0 : 10.0;
    final label = switch (_state) {
      JoinState.join => l.communityJoinSpace,
      JoinState.pending => l.spaceJoinPending,
      JoinState.joined => l.discussionsJoined,
    };
    final isPrimary = _state == JoinState.join;
    final currentUserId = ref.watch(currentUserProvider.select((u) => u.id));
    final isOwner = widget.ownerId != null && widget.ownerId == currentUserId;
    return GestureDetector(
      onTap: isOwner ? null : _tap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        decoration: BoxDecoration(
          gradient: isPrimary ? p.primaryGradient : null,
          color: isPrimary ? null : p.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPrimary ? Colors.transparent : p.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary ? p.onPrimary : p.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
