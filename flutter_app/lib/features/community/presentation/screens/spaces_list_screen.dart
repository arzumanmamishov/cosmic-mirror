import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/category_card.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/hashtag_chip.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/space_card.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/space_filter_tabs.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Main Community-tab landing. Renders inline (no Scaffold) so it works as
/// either the body of the home Community tab OR a pushed standalone route.
class SpacesListScreen extends ConsumerWidget {
  const SpacesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final spacesAsync = ref.watch(spacesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final hashtagsAsync = ref.watch(popularHashtagsProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          floating: true,
          title: Text(
            'Community',
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            const _NotificationsBell(),
            IconButton(
              tooltip: 'New space',
              icon: Icon(Icons.add_circle_outline_rounded, color: p.textPrimary),
              onPressed: () => context.push('/community/create'),
            ),
            const SizedBox(width: 4),
          ],
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: SpaceFilterTabs(),
          ),
        ),
        SliverToBoxAdapter(child: _SearchBar(palette: p)),
        // Categories grid
        SliverToBoxAdapter(
          child: categoriesAsync.when(
            loading: () => const SizedBox(height: 100),
            error: (_, __) => const SizedBox.shrink(),
            data: (cats) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categories',
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: cats.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) => SizedBox(
                        width: 130,
                        child: CategoryCard(category: cats[i]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Hashtag chips
        SliverToBoxAdapter(
          child: hashtagsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (tags) => tags.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in tags.take(8)) HashtagChip(tag: t.name),
                      ],
                    ),
                  ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        spacesAsync.when(
          loading: () => const SliverToBoxAdapter(
            child: ShimmerList(itemCount: 4),
          ),
          error: (e, _) => SliverToBoxAdapter(
            child: ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(spacesProvider),
            ),
          ),
          data: (spaces) {
            if (spaces.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
                  child: Center(
                    child: Text(
                      'No spaces yet — tap + to create the first one.',
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              sliver: SliverList.separated(
                itemCount: spaces.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => SpaceCard(space: spaces[i]),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.palette});
  final AppPalette palette;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      child: Consumer(
        builder: (context, ref, _) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: p.glassBorder),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: p.textTertiary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: TextStyle(color: p.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search spaces',
                    hintStyle:
                        TextStyle(color: p.textTertiary, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  onSubmitted: (v) =>
                      ref.read(spaceSearchQueryProvider.notifier).state = v,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsBell extends ConsumerWidget {
  const _NotificationsBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final unreadAsync = ref.watch(unreadCountProvider);
    final unread = unreadAsync.value ?? 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notifications',
          icon: Icon(Icons.notifications_outlined, color: p.textPrimary),
          onPressed: () => context.push('/community/notifications'),
        ),
        if (unread > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: p.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              alignment: Alignment.center,
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
