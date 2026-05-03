import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Toggleable like button with optimistic update. Works for both posts and
/// comments — pass [target] = 'post' or 'comment' and the relevant id.
class LikeButton extends ConsumerStatefulWidget {
  const LikeButton({
    required this.target,
    required this.targetId,
    required this.initialLiked,
    required this.initialCount,
    this.onChanged,
    super.key,
  });

  final String target; // 'post' or 'comment'
  final String targetId;
  final bool initialLiked;
  final int initialCount;
  final ValueChanged<bool>? onChanged;

  @override
  ConsumerState<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends ConsumerState<LikeButton> {
  late bool _liked = widget.initialLiked;
  late int _count = widget.initialCount;
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    final wasLiked = _liked;
    setState(() {
      _liked = !wasLiked;
      _count += _liked ? 1 : -1;
      _busy = true;
    });
    try {
      final repo = ref.read(communityRepositoryProvider);
      if (widget.target == 'post') {
        await repo.setPostLiked(widget.targetId, liked: _liked);
      } else {
        await repo.setCommentLiked(widget.targetId, liked: _liked);
      }
      widget.onChanged?.call(_liked);
    } catch (_) {
      // Revert on error.
      setState(() {
        _liked = wasLiked;
        _count += wasLiked ? 1 : -1;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = _liked ? p.accent : p.textSecondary;
    return InkWell(
      onTap: _toggle,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _liked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              '$_count',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
