import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/domain/entities/post.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/like_button.dart';
import 'package:flutter/material.dart';

class CommentTile extends StatelessWidget {
  const CommentTile({
    required this.comment,
    this.onReply,
    super.key,
  });

  final CommentWithMeta comment;
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = comment.comment;
    final isReply = c.parentCommentId != null;
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 28 : 0, top: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              comment.authorName.isNotEmpty
                  ? comment.authorName[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: p.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: p.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.authorName,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.content,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    LikeButton(
                      target: 'comment',
                      targetId: c.id,
                      initialLiked: comment.isLikedByMe,
                      initialCount: c.likeCount,
                    ),
                    if (!isReply && onReply != null) ...[
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: onReply,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Text(
                            'Reply',
                            style: TextStyle(
                              color: p.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
