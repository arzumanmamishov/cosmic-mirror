import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/core/error/error_message.dart';
import 'package:cosmic_mirror/features/community/data/repositories/community_repository.dart';
import 'package:cosmic_mirror/features/community/domain/entities/post.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/comment_tile.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/like_button.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/moderation_actions.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final _commentFocus = FocusNode();
  String? _replyToCommentId;
  String? _replyToName;
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  /// Opens a post's link in the browser. Links are stored as typed, so
  /// add a scheme when the author left it out.
  Future<void> _openLink(String raw) async {
    final trimmed = raw.trim();
    final uri = Uri.tryParse(
      trimmed.contains('://') ? trimmed : 'https://$trimmed',
    );
    final opened = uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)
            .catchError((Object _) => false);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).cpsLinkOpenFailed)),
      );
    }
  }

  /// Pull-to-refresh: awaits both fetches so the spinner stays up until
  /// data lands. Errors are rendered by the providers' error states.
  Future<void> _refresh() async {
    try {
      await Future.wait<Object?>([
        ref.refresh(postDetailProvider(widget.postId).future),
        ref.refresh(commentsProvider(widget.postId).future),
      ]);
    } catch (_) {}
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
        ..invalidate(postDetailProvider(widget.postId))
        // Comment count on the space feed card. widget.spaceId is empty
        // when opened from a notification, so prefer the loaded post's.
        ..invalidate(
          spacePostsProvider(
            ref.read(postDetailProvider(widget.postId)).valueOrNull?.post
                    .spaceId ??
                widget.spaceId,
          ),
        );
      if (!mounted) return;
      _commentFocus.unfocus();
      setState(() {
        _replyToCommentId = null;
        _replyToName = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(FriendlyError.from(context, e).body)),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// "…" menu for the post: delete for the author, report + block for
  /// everyone else. Leaves the screen when the post is gone for the viewer.
  List<ContentAction> _postActions(PostWithMeta post, {required bool isMine}) {
    final l = AppLocalizations.of(context);
    final pst = post.post;
    void leave() {
      if (mounted) Navigator.of(context).maybePop();
    }

    if (isMine) {
      return [
        ContentAction(
          icon: Icons.delete_outline_rounded,
          label: l.moderationDeletePost,
          destructive: true,
          onSelected: () async {
            if (!await confirmDelete(context, l.moderationDeletePostConfirm)) {
              return;
            }
            if (!mounted) return;
            final messenger = ScaffoldMessenger.of(context);
            final deleted = l.cpsPostDeleted;
            try {
              await ref.read(communityRepositoryProvider).deletePost(pst.id);
              ref
                ..invalidate(spacePostsProvider(pst.spaceId))
                ..invalidate(userCommunityProfileProvider);
              messenger.showSnackBar(SnackBar(content: Text(deleted)));
              leave();
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(FriendlyError.from(context, e).body)),
              );
            }
          },
        ),
      ];
    }
    return reportAndBlockActions(
      context,
      target: ReportTarget.post,
      targetId: pst.id,
      authorId: pst.authorId,
      authorName: post.authorName,
      onBlocked: leave,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final postAsync = ref.watch(postDetailProvider(widget.postId));
    final commentsAsync = ref.watch(commentsProvider(widget.postId));
    final myId = ref.watch(currentUserProvider.select((s) => s.id));

    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: Text(l.communityPostTitle),
        actions: [
          postAsync.maybeWhen(
            orElse: () => const SizedBox.shrink(),
            data: (post) => ContentMoreButton(
              size: 22,
              actions: () => _postActions(
                post,
                isMine: myId != null && myId == post.post.authorId,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
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
                    error: e,
                    onRetry: () =>
                        ref.invalidate(postDetailProvider(widget.postId)),
                  ),
                  data: (post) {
                    final pst = post.post;
                    // Space owners may delete any comment on posts in
                    // their space (mods too, server-side).
                    final ownsSpace = myId != null &&
                        ref
                                .watch(spaceDetailProvider(pst.spaceId))
                                .valueOrNull
                                ?.space
                                .createdBy ==
                            myId;
                    return RefreshIndicator(
                      color: p.primary,
                      backgroundColor: p.surface,
                      edgeOffset: MediaQuery.paddingOf(context).top +
                          kToolbarHeight,
                      onRefresh: _refresh,
                      child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      // Clear the transparent app bar + status bar on
                      // every device instead of a fixed 100px.
                      padding: EdgeInsets.fromLTRB(
                        20,
                        MediaQuery.paddingOf(context).top +
                            kToolbarHeight +
                            12,
                        20,
                        16,
                      ),
                      children: [
                        // Author + handle — tap opens their profile.
                        InkWell(
                          onTap: () => context
                              .push('/community/user/${pst.authorId}'),
                          borderRadius: BorderRadius.circular(8),
                          child: Row(
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: p.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    l.postInSpace(post.spaceHandle),
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
                        ),
                        if (pst.isHidden) ...[
                          const SizedBox(height: 12),
                          const HiddenContentNotice(),
                        ],
                        const SizedBox(height: 14),
                        Text(
                          pst.content,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                        // The link was shown on the feed card but could
                        // not be opened anywhere; make it tappable here.
                        if (pst.linkUrl != null &&
                            pst.linkUrl!.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Material(
                            color: p.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: () => _openLink(pst.linkUrl!),
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.link_rounded,
                                      size: 16,
                                      color: p.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        pst.linkUrl!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: p.primary,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.open_in_new_rounded,
                                      size: 15,
                                      color: p.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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
                        Divider(color: p.glassBorder, height: 32),
                        Text(
                          l.postCommentsHeader,
                          style: TextStyle(
                            color: p.textSecondary,
                            fontSize: 11,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        commentsAsync.when(
                          loading: () => const ShimmerList(),
                          error: (e, _) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    FriendlyError.from(context, e).body,
                                    style: TextStyle(
                                      color: p.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => ref.invalidate(
                                    commentsProvider(widget.postId),
                                  ),
                                  child: Text(l.errRetry),
                                ),
                              ],
                            ),
                          ),
                          data: (comments) => comments.isEmpty
                              ? Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      l.postNoComments,
                                      style: TextStyle(color: p.textSecondary),
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (final c in comments)
                                      CommentTile(
                                        key: ValueKey(c.comment.id),
                                        comment: c,
                                        canModerate: ownsSpace,
                                        onReply: () {
                                          setState(() {
                                            _replyToCommentId = c.comment.id;
                                            _replyToName = c.authorName;
                                          });
                                          // Bring up the keyboard so the
                                          // reply can be typed right away.
                                          _commentFocus.requestFocus();
                                        },
                                      ),
                                  ],
                                ),
                        ),
                      ],
                      ),
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
                            Expanded(
                              child: Text(
                                l.postReplyingTo(_replyToName!),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: p.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            // Padded so the 14px icon has a usable target.
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() {
                                _replyToCommentId = null;
                                _replyToName = null;
                              }),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 14,
                                  color: p.textSecondary,
                                ),
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
                              focusNode: _commentFocus,
                              textCapitalization:
                                  TextCapitalization.sentences,
                              minLines: 1,
                              maxLines: 4,
                              style: TextStyle(
                                color: p.textPrimary,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                hintText: l.postWriteCommentHint,
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
                          tooltip: l.communityComment,
                          icon: _busy
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: p.primary,
                                  ),
                                )
                              : Icon(
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
