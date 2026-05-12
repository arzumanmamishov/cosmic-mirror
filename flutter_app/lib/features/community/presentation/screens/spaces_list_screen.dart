import 'package:cached_network_image/cached_network_image.dart';
import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/category_card.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/hashtag_chip.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/space_card.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/space_filter_tabs.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/utils/avatar_url.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/gestures.dart';
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
    final l = AppLocalizations.of(context);
    final spacesAsync = ref.watch(spacesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final hashtagsAsync = ref.watch(popularHashtagsProvider);

    return CustomScrollView(
      slivers: [
        // Top action row — just the bell + avatar, no big AppBar title
        // (the hero card below carries the brand presence).
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Spacer(),
                _NotificationsBell(),
                SizedBox(width: 4),
                _MyProfileAvatar(),
              ],
            ),
          ),
        ),
        // Big eye-catching hero card with the community title +
        // subtitle + primary "Create a space" CTA.
        const SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 16),
          sliver: SliverToBoxAdapter(child: _CommunityHero()),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
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
                    l.communityCategoriesLabel,
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 96,
                    child: ScrollConfiguration(
                      // Enable mouse-drag scrolling on Flutter web; the
                      // default web scroll behavior only allows wheel.
                      behavior: const _DragScrollBehavior(),
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
              error: e,
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
                      l.communitySpacesEmptyTap,
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

class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar({required this.palette});
  final AppPalette palette;

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Hydrate from the provider so a query pushed in from the home
    // top search lands here pre-filled instead of looking empty.
    _controller = TextEditingController(
      text: ref.read(spaceSearchQueryProvider),
    );
  }

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
                    hintText: AppLocalizations.of(context).communitySearchSpaces,
                    hintStyle:
                        TextStyle(color: p.textTertiary, fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  // Live filter on every keystroke — submit-only meant
                  // the list never updated unless the user pressed
                  // Enter on the keyboard, which most never do.
                  onChanged: (v) =>
                      ref.read(spaceSearchQueryProvider.notifier).state = v,
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
          tooltip: AppLocalizations.of(context).communityNotificationsTooltip,
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

class _MyProfileAvatar extends ConsumerWidget {
  const _MyProfileAvatar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final user = ref.watch(currentUserProvider);
    final name = user.name ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final url = resolveAvatarUrl(user.avatarUrl);

    Widget fallback() => Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: p.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: GestureDetector(
        onTap: () => context.push('/community/user/me'),
        child: SizedBox(
          width: 32,
          height: 32,
          child: ClipOval(
            child: url == null
                ? fallback()
                : CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => fallback(),
                    errorWidget: (_, __, ___) => fallback(),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Eye-catching hero card at the top of the Community tab. Carries the
/// brand presence (gradient, headline, blurb) and the primary
/// "Create a space" action — which used to be a tiny icon button buried
/// in the AppBar. Tapping the card itself also pushes to /community/create.
class _CommunityHero extends ConsumerWidget {
  const _CommunityHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            p.primary.withValues(alpha: 0.20),
            p.accent.withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: p.gold.withValues(alpha: 0.30)),
        boxShadow: [
          BoxShadow(
            color: p.gold.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.gold.withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                  border: Border.all(color: p.gold.withValues(alpha: 0.6)),
                ),
                child: Icon(
                  Icons.diversity_3_rounded,
                  color: p.gold,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l.communityTitle,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l.communityHeroBlurb,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/community/create'),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l.communityCreateSpace),
              style: ElevatedButton.styleFrom(
                backgroundColor: p.gold,
                foregroundColor: const Color(0xFF1A1F2E),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ScrollBehavior that re-enables mouse-drag on Flutter web. The default
/// MaterialScrollBehavior only treats touch + stylus as drag-capable
/// pointers, which makes horizontal lists feel "frozen" in the browser.
class _DragScrollBehavior extends MaterialScrollBehavior {
  const _DragScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}
