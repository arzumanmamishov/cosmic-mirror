import 'package:cached_network_image/cached_network_image.dart';
import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_tokens.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/config/theme/macos_colors.dart';
import 'package:cosmic_mirror/features/community/domain/entities/post.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/like_button.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/utils/avatar_url.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PostCard extends StatelessWidget {
  const PostCard({required this.post, super.key});

  final PostWithMeta post;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final pst = post.post;
    void open() => context.push('/community/${pst.spaceId}/post/${pst.id}');
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(LivelyRadius.xl),
      child: InkWell(
        onTap: open,
        borderRadius: BorderRadius.circular(LivelyRadius.xl),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LivelyRadius.xl),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => context.push('/community/user/${pst.authorId}'),
                borderRadius: BorderRadius.circular(LivelyRadius.sm),
                child: Row(
                  children: [
                    _AuthorAvatar(
                      name: post.authorName,
                      url: post.authorAvatarUrl,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: LivelyType.small(p.textPrimary)
                                .copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '@${post.spaceHandle} · ${_relativeTime(l, pst.createdAt)}',
                            style: LivelyType.caption(p.textDim),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(pst.content, style: LivelyType.body(p.textPrimary)),
              if (pst.linkUrl != null && pst.linkUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: p.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(LivelyRadius.md),
                    border:
                        Border.all(color: p.primary.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.link_rounded, size: 16, color: p.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pst.linkUrl!,
                          style: LivelyType.small(p.primary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Divider(height: 1, color: p.line),
              const SizedBox(height: 4),
              Row(
                children: [
                  LikeButton(
                    target: 'post',
                    targetId: pst.id,
                    initialLiked: post.isLikedByMe,
                    initialCount: pst.likeCount,
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: open,
                    borderRadius: BorderRadius.circular(LivelyRadius.sm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 17,
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
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Author photo, falling back to the initial on a stable per-name hue.
class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.name, this.url});
  final String name;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final hue = MacOSColors.of(context).hueFor(name);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final resolved = resolveAvatarUrl(url);
    Widget fallback() => ColoredBox(
          color: hue.withValues(alpha: 0.2),
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                color: hue,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
    return ClipOval(
      child: SizedBox(
        width: 36,
        height: 36,
        child: resolved == null
            ? fallback()
            : CachedNetworkImage(
                imageUrl: resolved,
                fit: BoxFit.cover,
                placeholder: (_, __) => fallback(),
                errorWidget: (_, __, ___) => fallback(),
              ),
      ),
    );
  }
}

String _relativeTime(AppLocalizations l, DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return l.postTimeNow;
  if (diff.inMinutes < 60) return l.postTimeMinutesShort(diff.inMinutes);
  if (diff.inHours < 24) return l.postTimeHoursShort(diff.inHours);
  if (diff.inDays < 7) return l.postTimeDaysShort(diff.inDays);
  return l.postTimeWeeksShort((diff.inDays / 7).floor());
}
