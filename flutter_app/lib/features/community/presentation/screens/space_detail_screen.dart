import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/domain/entities/space.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/features/community/presentation/screens/compose_post_sheet.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/join_button.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/post_card.dart';
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
    final postsAsync = ref.watch(spacePostsProvider(spaceId));

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
              onPressed: () => _showOverflow(context, ref, s.space.id, s.space.createdBy),
            ),
          ),
        ],
      ),
      floatingActionButton: spaceAsync.maybeWhen(
        orElse: () => null,
        data: (s) => FloatingActionButton.extended(
          backgroundColor: p.primary,
          icon: const Icon(Icons.edit_rounded),
          label: const Text('Post'),
          onPressed: () async {
            await showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => ComposePostSheet(spaceId: spaceId),
            );
            ref.invalidate(spacePostsProvider(spaceId));
          },
        ),
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
              message: e.toString(),
              onRetry: () => ref.invalidate(spaceDetailProvider(spaceId)),
            ),
            data: (s) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(spaceDetailProvider(spaceId));
                ref.invalidate(spacePostsProvider(spaceId));
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 100),
                children: [
                  _Hero(space: s, palette: p),
                  const SizedBox(height: 16),
                  Text(
                    'Posts',
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 11,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  postsAsync.when(
                    loading: () => const ShimmerList(itemCount: 3),
                    error: (e, _) => ErrorView(
                      message: e.toString(),
                      onRetry: () => ref.invalidate(spacePostsProvider(spaceId)),
                    ),
                    data: (posts) => posts.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Text(
                                'No posts yet — be the first.',
                                style: TextStyle(color: p.textSecondary),
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
                  ),
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
    String spaceId,
    String createdBy,
  ) {
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
              title: const Text('Members'),
              onTap: () {
                Navigator.pop(context);
                context.push('/community/$spaceId/members');
              },
            ),
            ListTile(
              leading: Icon(Icons.edit_rounded, color: p.textPrimary),
              title: const Text('Edit space'),
              onTap: () {
                Navigator.pop(context);
                context.push('/community/$spaceId/edit');
              },
            ),
          ],
        ),
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
              compact: false,
            ),
          ),
        ],
      ),
    );
  }
}
