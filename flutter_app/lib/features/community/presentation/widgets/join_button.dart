import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Join / Joined toggle button with optimistic update. Mirrors the
/// "Join" / "Joined" pill in the screenshot reference.
class JoinButton extends ConsumerStatefulWidget {
  const JoinButton({
    required this.spaceId,
    required this.initialJoined,
    this.onChanged,
    this.compact = true,
    super.key,
  });

  final String spaceId;
  final bool initialJoined;
  final ValueChanged<bool>? onChanged;
  final bool compact;

  @override
  ConsumerState<JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends ConsumerState<JoinButton> {
  late bool _joined = widget.initialJoined;
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    final wasJoined = _joined;
    setState(() {
      _joined = !wasJoined;
      _busy = true;
    });
    try {
      final repo = ref.read(communityRepositoryProvider);
      if (_joined) {
        await repo.joinSpace(widget.spaceId);
      } else {
        await repo.leaveSpace(widget.spaceId);
      }
      widget.onChanged?.call(_joined);
    } catch (_) {
      setState(() => _joined = wasJoined);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final padH = widget.compact ? 14.0 : 18.0;
    final padV = widget.compact ? 6.0 : 10.0;
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        decoration: BoxDecoration(
          gradient: _joined ? null : p.primaryGradient,
          color: _joined ? p.surfaceElevated : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _joined ? p.glassBorder : Colors.transparent,
          ),
        ),
        child: Text(
          _joined ? 'Joined' : 'Join',
          style: TextStyle(
            color: _joined ? p.textSecondary : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
