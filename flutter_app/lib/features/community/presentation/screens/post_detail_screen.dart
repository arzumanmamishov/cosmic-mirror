import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/comment_tile.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/like_button.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({
    required this.spaceId,
    required this.postId,
    super.key,
  });

  final String spaceId;
  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _comment = TextEditingController();
  String? _replyToCommentId;
  String? _replyToName;
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _comment.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(communityRepositoryProvider).createComment(
            postId: widget.postId,
            content: text,
            parentCommentId: _replyToCommentId,
          );
      _comment.clear();
      ref
        ..invalidate(commentsProvider(widget.postId))
        ..invalidate(postDetailProvider(widget.postId));
      setState(() {
        _replyToCommentId = null;
        _replyToName = null;
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(commentsProvider(widget.postId));

    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Post'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CosmicStarfield(
              color: p.textPrimary,
              starCount: 40,
              intensity: 0.5,
            ),
          ),
          Column(
            children: [
              Expanded(
                child: postAsync.when(
                  loading: () => const ShimmerList(itemCount: 4),
                  error: (e, _) => ErrorView(
                    message: e.toString(),
                    onRetry: () =>
                        ref.invalidate(postDetailProvider(widget.postId)),
                  ),
                  data: (post) {
                    final pst = post.post;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 100, 20, 16),
                      children: [
                        // Author + handle
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: p.primary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                post.authorName.isNotEmpty
                                    ? post.authorName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: p.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.authorName,
                                    style: TextStyle(
                                      color: p.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    'in @${post.spaceHandle}',
                                    style: TextStyle(
                                      color: p.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          pst.content,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            LikeButton(
                              target: 'post',
                              targetId: pst.id,
                              initialLiked: post.isLikedByMe,
                              initialCount: pst.likeCount,
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.chat_bubble_outline_rounded,
                                size: 16, color: p.textSecondary),
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
                        Divider(color: p.glassBorder, height: 32),
                        Text(
                          'Comments',
                          style: TextStyle(
                            color: p.textSecondary,
                            fontSize: 11,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        commentsAsync.when(
                          loading: () => const ShimmerList(itemCount: 3),
                          error: (e, _) => Text(
                            e.toString(),
                            style: TextStyle(color: p.error, fontSize: 12),
                          ),
                          data: (comments) => comments.isEmpty
                              ? Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'No comments yet.',
                                      style:
                                          TextStyle(color: p.textSecondary),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (final c in comments)
                                      CommentTile(
                                        comment: c,
                                        onReply: () => setState(() {
                                          _replyToCommentId = c.comment.id;
                                          _replyToName = c.authorName;
                                        }),
                                      ),
                                  ],
                                ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Sticky comment composer
              Container(
                padding: EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  10 + MediaQuery.of(context).padding.bottom,
                ),
                decoration: BoxDecoration(
                  color: p.surface,
                  border: Border(top: BorderSide(color: p.glassBorder)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_replyToName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Text(
                              'Replying to $_replyToName',
                              style: TextStyle(
                                color: p.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setState(() {
                                _replyToCommentId = null;
                                _replyToName = null;
                              }),
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: p.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: p.surfaceElevated,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _comment,
                              minLines: 1,
                              maxLines: 4,
                              style: TextStyle(
                                color: p.textPrimary,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Write a comment',
                                hintStyle: TextStyle(
                                  color: p.textTertiary,
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            Icons.send_rounded,
                            color: _comment.text.trim().isEmpty
                                ? p.textTertiary
                                : p.primary,
                          ),
                          onPressed: _busy ? null : _send,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
