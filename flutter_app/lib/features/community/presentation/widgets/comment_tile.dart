import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/core/error/error_message.dart';
import 'package:cosmic_mirror/features/community/data/repositories/community_repository.dart';
import 'package:cosmic_mirror/features/community/domain/entities/post.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/like_button.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/moderation_actions.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CommentTile extends ConsumerWidget {
  const CommentTile({
    required this.comment,
    this.onReply,
    this.canModerate = false,
    super.key,
  });

  final CommentWithMeta comment;
  final VoidCallback? onReply;

  /// The viewer owns the space this comment's post is in, so they may
  /// delete other members' comments (the server also allows mods).
  final bool canModerate;

  List<ContentAction> _actions(
    BuildContext context, {
    required bool isMine,
  }) {
    final l = AppLocalizations.of(context);
    final c = comment.comment;
    return [
      if (!isMine)
        ...reportAndBlockActions(
          context,
          target: ReportTarget.comment,
          targetId: c.id,
          authorId: c.authorId,
          authorName: comment.authorName,
        ),
      if (isMine || canModerate)
        ContentAction(
          icon: Icons.delete_outline_rounded,
          label: l.moderationDeleteComment,
          destructive: true,
          onSelected: () async {
            if (!await confirmDelete(
              context,
              l.moderationDeleteCommentConfirm,
            )) {
              return;
            }
            if (!context.mounted) return;
            final container = ProviderScope.containerOf(context, listen: false);
            final messenger = ScaffoldMessenger.of(context);
            try {
              await container
                  .read(communityRepositoryProvider)
                  .deleteComment(c.id);
              container
                ..invalidate(commentsProvider(c.postId))
                ..invalidate(postDetailProvider(c.postId));
            } catch (e) {
              if (context.mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(FriendlyError.from(context, e).body),
                  ),
                );
              }
            }
          },
        ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final c = comment.comment;
    final isReply = c.parentCommentId != null;
    final myId = ref.watch(currentUserProvider.select((s) => s.id));
    final isMine = myId != null && myId == c.authorId;
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 28 : 0, top: 8, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push('/community/user/${c.authorId}'),
            child: Container(
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
                      GestureDetector(
                        onTap: () =>
                            context.push('/community/user/${c.authorId}'),
                        child: Text(
                          comment.authorName,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
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
                      if (c.isHidden) ...[
                        const SizedBox(height: 6),
                        const HiddenContentNotice(),
                      ],
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
                            AppLocalizations.of(context).communityReply,
                            style: TextStyle(
                              color: p.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    ContentMoreButton(
                      size: 16,
                      actions: () => _actions(context, isMine: isMine),
                    ),
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
