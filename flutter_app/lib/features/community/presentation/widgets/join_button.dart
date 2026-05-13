import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
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
    this.onChanged,
    this.compact = true,
    super.key,
  });

  final String spaceId;
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
          widget.onChanged?.call(JoinState.pending);
        } catch (_) {
          setState(() => _state = prev);
        } finally {
          if (mounted) setState(() => _busy = false);
        }
        break;
      case JoinState.pending:
        // Tapping a pending pill does nothing — request is in flight
        // with the owner. We could add a "Cancel request" action later
        // if users ask for it.
        break;
      case JoinState.joined:
        setState(() {
          _state = JoinState.join;
          _busy = true;
        });
        try {
          await repo.leaveSpace(widget.spaceId);
          widget.onChanged?.call(JoinState.join);
        } catch (_) {
          setState(() => _state = prev);
        } finally {
          if (mounted) setState(() => _busy = false);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final padH = widget.compact ? 14.0 : 18.0;
    final padV = widget.compact ? 6.0 : 10.0;
    final label = switch (_state) {
      JoinState.join => 'Join',
      JoinState.pending => 'Pending',
      JoinState.joined => 'Joined',
    };
    final isPrimary = _state == JoinState.join;
    return GestureDetector(
      onTap: _tap,
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
            color: isPrimary ? Colors.white : p.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
