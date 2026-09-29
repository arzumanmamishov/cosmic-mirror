import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/domain/entities/notification.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
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
    final l = AppLocalizations.of(context);
    final n = entry.notification;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: n.isUnread ? p.primary.withValues(alpha: 0.08) : p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                n.isUnread ? p.primary.withValues(alpha: 0.4) : p.glassBorder,
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
                        TextSpan(text: _actionLabel(l, n.type)),
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
                    _relative(l, n.createdAt),
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
      case 'space_join_requested':
        icon = Icons.how_to_reg_rounded;
        color = palette.primary;
      case 'space_join_approved':
        icon = Icons.check_circle_rounded;
        color = palette.success;
      case 'space_join_declined':
        icon = Icons.cancel_rounded;
        color = palette.textSecondary;
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

String _actionLabel(AppLocalizations l, String type) {
  switch (type) {
    case 'post_liked':
      return l.notificationPostLiked;
    case 'comment_liked':
      return l.notificationCommentLiked;
    case 'post_commented':
      return l.notificationPostCommented;
    case 'comment_replied':
      return l.notificationCommentReplied;
    case 'space_member_joined':
      return l.notificationSpaceMemberJoined;
    case 'space_followed':
      return l.notificationSpaceFollowed;
    case 'space_join_requested':
      return l.notificationSpaceJoinRequested;
    case 'space_join_approved':
      return l.notificationSpaceJoinApproved;
    case 'space_join_declined':
      return l.notificationSpaceJoinDeclined;
    case 'post_in_space':
      return l.notificationPostInSpace;
    case 'mentioned':
      return l.notificationMentioned;
    default:
      return l.notificationGeneric;
  }
}

String _relative(AppLocalizations l, DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 1) return l.notificationTimeJustNow;
  if (diff.inMinutes < 60) return l.notificationTimeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l.notificationTimeHoursAgo(diff.inHours);
  if (diff.inDays < 7) return l.notificationTimeDaysAgo(diff.inDays);
  return l.notificationTimeWeeksAgo((diff.inDays / 7).floor());
}
