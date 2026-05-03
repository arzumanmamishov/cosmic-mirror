import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/domain/entities/post.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/like_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PostCard extends StatelessWidget {
  const PostCard({required this.post, super.key});

  final PostWithMeta post;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pst = post.post;
    return InkWell(
      onTap: () => context.push('/community/${pst.spaceId}/post/${pst.id}'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _AuthorDot(name: post.authorName, palette: p),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '@${post.spaceHandle} · ${_relativeTime(pst.createdAt)}',
                        style: TextStyle(color: p.textTertiary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              pst.content,
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            if (pst.linkUrl != null && pst.linkUrl!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: p.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, size: 14, color: p.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        pst.linkUrl!,
                        style: TextStyle(color: p.textSecondary, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                LikeButton(
                  target: 'post',
                  targetId: pst.id,
                  initialLiked: post.isLikedByMe,
                  initialCount: pst.likeCount,
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 16,
                  color: p.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${pst.commentCount}',
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthorDot extends StatelessWidget {
  const _AuthorDot({required this.name, required this.palette});
  final String name;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: palette.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _relativeTime(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${(diff.inDays / 7).floor()}w';
}
