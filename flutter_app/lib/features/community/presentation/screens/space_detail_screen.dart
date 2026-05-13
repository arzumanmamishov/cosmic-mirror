import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/domain/entities/space.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/features/community/presentation/screens/compose_post_sheet.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/join_button.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/post_card.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SpaceDetailScreen extends ConsumerWidget {
  const SpaceDetailScreen({required this.spaceId, super.key});

  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final spaceAsync = ref.watch(spaceDetailProvider(spaceId));
    final currentUserId = ref.watch(
      currentUserProvider.select((s) => s.id),
    );

    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        actions: [
          spaceAsync.maybeWhen(
            orElse: () => const SizedBox.shrink(),
            data: (s) => IconButton(
              icon: Icon(Icons.more_vert_rounded, color: p.textPrimary),
              onPressed: () => _showOverflow(
                context,
                ref,
                s.space.id,
                isOwner: currentUserId != null && currentUserId == s.space.createdBy,
              ),
            ),
          ),
        ],
      ),
      // The compose-post FAB is only shown to approved members. Pending
      // requesters and non-members would hit a 403 on submit, so we hide
      // the affordance entirely rather than let them tap into a dead end.
      floatingActionButton: spaceAsync.maybeWhen(
        orElse: () => null,
        data: (s) => s.isJoined
            ? FloatingActionButton.extended(
                backgroundColor: p.primary,
                icon: const Icon(Icons.edit_rounded),
                label: Text(AppLocalizations.of(context).communityPostSubmit),
                onPressed: () async {
                  await showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ComposePostSheet(spaceId: spaceId),
                  );
                  ref.invalidate(spacePostsProvider(spaceId));
                },
              )
            : null,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CosmicStarfield(
              color: p.textPrimary,
              starCount: 50,
              intensity: 0.6,
            ),
          ),
          spaceAsync.when(
            loading: () => const ShimmerList(itemCount: 4),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.invalidate(spaceDetailProvider(spaceId)),
            ),
            data: (s) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(spaceDetailProvider(spaceId));
                if (s.isJoined) {
                  ref.invalidate(spacePostsProvider(spaceId));
                }
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 100),
                children: [
                  _Hero(space: s, palette: p),
                  const SizedBox(height: 16),
                  // Content is gated: posts are only fetched + shown to
                  // approved members. Pending and never-joined users see
                  // a locked-content placeholder explaining what to do.
                  if (s.isJoined) ...[
                    Text(
                      AppLocalizations.of(context).spacePostsHeader,
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PostList(spaceId: spaceId, palette: p),
                  ] else
                    _LockedContent(isPending: s.isPending, palette: p),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOverflow(
    BuildContext context,
    WidgetRef ref,
    String spaceId, {
    required bool isOwner,
  }) {
    final p = context.palette;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.surface,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.group_rounded, color: p.textPrimary),
              title: Text(AppLocalizations.of(context).communityMembers),
              onTap: () {
                Navigator.pop(context);
                context.push('/community/$spaceId/members');
              },
            ),
            if (isOwner) ...[
              ListTile(
                leading: Icon(Icons.how_to_reg_rounded, color: p.textPrimary),
                title: Text(AppLocalizations.of(context).spaceManageRequests),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/community/$spaceId/requests');
                },
              ),
              ListTile(
                leading: Icon(Icons.edit_rounded, color: p.textPrimary),
                title: Text(AppLocalizations.of(context).communityEditSpace),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/community/$spaceId/edit');
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Posts list for approved members. Pulled into its own widget so the
/// gated branch in `build` doesn't even subscribe to spacePostsProvider
/// — that way pending viewers don't burn a 403 round-trip just by
/// opening the space.
class _PostList extends ConsumerWidget {
  const _PostList({required this.spaceId, required this.palette});
  final String spaceId;
  final AppPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(spacePostsProvider(spaceId));
    return postsAsync.when(
      loading: () => const ShimmerList(itemCount: 3),
      error: (e, _) => ErrorView(
        error: e,
        onRetry: () => ref.invalidate(spacePostsProvider(spaceId)),
      ),
      data: (posts) => posts.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  AppLocalizations.of(context).spaceNoPosts,
                  style: TextStyle(color: palette.textSecondary),
                ),
              ),
            )
          : Column(
              children: [
                for (final post in posts) ...[
                  PostCard(post: post),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }
}

/// Locked-content placeholder shown to non-approved viewers. Two
/// states: the user hasn't requested yet (prompt to request), or the
/// request is pending the owner's review.
class _LockedContent extends StatelessWidget {
  const _LockedContent({required this.isPending, required this.palette});
  final bool isPending;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final title = isPending ? l.spacePendingTitle : l.spaceLockedTitle;
    final body = isPending ? l.spacePendingBody : l.spaceLockedBody;
    final icon = isPending ? Icons.hourglass_top_rounded : Icons.lock_outline_rounded;
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.glassBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: palette.primary, size: 36),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.space, required this.palette});
  final SpaceWithMeta space;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final s = space.space;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: palette.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${s.handle} · ${s.memberCount} members',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
            ),
          ),
          if (s.description != null && s.description!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              s.description!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: JoinButton(
              spaceId: s.id,
              initialJoined: space.isJoined,
              initialPending: space.isPending,
              compact: false,
            ),
          ),
        ],
      ),
    );
  }
}
