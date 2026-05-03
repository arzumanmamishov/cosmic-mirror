import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/domain/entities/notification.dart';
import 'package:flutter/material.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    required this.entry,
    required this.onTap,
    super.key,
  });

  final NotificationWithMeta entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = entry.notification;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: n.isUnread
              ? p.primary.withValues(alpha: 0.08)
              : p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: n.isUnread ? p.primary.withValues(alpha: 0.4) : p.glassBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActionIcon(type: n.type, palette: p),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                      children: [
                        if (entry.actorName != null)
                          TextSpan(
                            text: '${entry.actorName} ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        TextSpan(text: _actionLabel(n.type)),
                      ],
                    ),
                  ),
                  if (n.snippet != null && n.snippet!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      n.snippet!,
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _relative(n.createdAt),
                    style: TextStyle(color: p.textTertiary, fontSize: 10),
                  ),
                ],
              ),
            ),
            if (n.isUnread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4, left: 8),
                decoration: BoxDecoration(
                  color: p.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({required this.type, required this.palette});
  final String type;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (type) {
      case 'post_liked':
      case 'comment_liked':
        icon = Icons.favorite_rounded;
        color = palette.accent;
      case 'post_commented':
      case 'comment_replied':
        icon = Icons.chat_bubble_rounded;
        color = palette.primary;
      case 'space_member_joined':
      case 'space_followed':
        icon = Icons.group_add_rounded;
        color = palette.success;
      case 'post_in_space':
        icon = Icons.article_rounded;
        color = palette.gold;
      case 'mentioned':
        icon = Icons.alternate_email_rounded;
        color = palette.warning;
      default:
        icon = Icons.notifications_rounded;
        color = palette.textSecondary;
    }
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

String _actionLabel(String type) {
  switch (type) {
    case 'post_liked':
      return 'liked your post';
    case 'comment_liked':
      return 'liked your comment';
    case 'post_commented':
      return 'commented on your post';
    case 'comment_replied':
      return 'replied to your comment';
    case 'space_member_joined':
      return 'joined your space';
    case 'space_followed':
      return 'followed your space';
    case 'post_in_space':
      return 'posted in a space you follow';
    case 'mentioned':
      return 'mentioned you';
    default:
      return type;
  }
}

String _relative(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${(diff.inDays / 7).floor()}w ago';
}
