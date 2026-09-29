import 'package:cached_network_image/cached_network_image.dart';
import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_tokens.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/features/community/domain/entities/space.dart';
import 'package:cosmic_mirror/features/community/presentation/providers/community_providers.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/category_card.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/hashtag_chip.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/space_card.dart';
import 'package:cosmic_mirror/features/community/presentation/widgets/space_filter_tabs.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/utils/avatar_url.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/lively/gold_button.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Main Community-tab landing. Renders inline (no Scaffold) so it works as
/// either the body of the home Community tab OR a pushed standalone route.
///
/// Layout: serif title header (bell + avatar) → search + create row →
/// category tiles → trending hashtags → All/Joined toggle → spaces list.
class SpacesListScreen extends ConsumerWidget {
  const SpacesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    final spacesAsync = ref.watch(spacesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final hashtagsAsync = ref.watch(popularHashtagsProvider);

    return RefreshIndicator(
      color: p.primary,
      backgroundColor: p.surface,
      onRefresh: () async {
        ref
          ..invalidate(categoriesProvider)
          ..invalidate(popularHashtagsProvider);
        await ref.refresh(spacesProvider.future).catchError((_) => <Never>[]);
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 12, 12, 0),
            sliver: SliverToBoxAdapter(child: _Header()),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(child: _SearchBar()),
                  SizedBox(width: 10),
                  _CreateSpaceButton(),
                ],
              ),
            ),
          ),
          // Categories — horizontal tiles.
          SliverToBoxAdapter(
            child: categoriesAsync.maybeWhen(
              orElse: () => const SizedBox.shrink(),
              data: (cats) => cats.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
                          child: Text(
                            l.communityCategoriesLabel.toUpperCase(),
                            style: LivelyType.kicker(p.textMuted),
                          ),
                        ),
                        _CategoryCarousel(categories: cats),
                      ],
                    ),
            ),
          ),
          // Trending hashtags — one swipeable row.
          SliverToBoxAdapter(
            child: hashtagsAsync.maybeWhen(
              orElse: () => const SizedBox.shrink(),
              data: (tags) => tags.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: SizedBox(
                        height: 34,
                        child: ScrollConfiguration(
                          behavior: const _DragScrollBehavior(),
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            physics: const BouncingScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            itemCount: tags.take(12).length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) =>
                                HashtagChip(tag: tags[i].name),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 14),
            sliver: SliverToBoxAdapter(child: SpaceFilterTabs()),
          ),
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
                return const SliverToBoxAdapter(child: _EmptySpaces());
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                sliver: SliverList.separated(
                  itemCount: spaces.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => SpaceCard(space: spaces[i]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Serif page title + blurb on the left, bell + avatar on the right.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(l.communityTitle, style: LivelyType.d2(p.textPrimary)),
              const SizedBox(height: 8),
              Text(l.communityHeroBlurb, style: LivelyType.small(p.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const _NotificationsBell(),
        const _MyProfileAvatar(),
      ],
    );
  }
}

class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  late final TextEditingController _controller;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    // Hydrate from the provider so a query pushed in from the home
    // top search lands here pre-filled instead of looking empty.
    _controller = TextEditingController(
      text: ref.read(spaceSearchQueryProvider),
    );
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  StateController<String> get _query =>
      ref.read(spaceSearchQueryProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final focused = _focus.hasFocus;
    return AnimatedContainer(
      duration: LivelyMotion.quick,
      height: 46,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(LivelyRadius.full),
        border: Border.all(
          color: focused ? p.primary.withValues(alpha: 0.6) : p.line,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: focused ? p.primary : p.textDim,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              cursorColor: p.primary,
              textInputAction: TextInputAction.search,
              style: LivelyType.small(p.textPrimary).copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).communitySearchSpaces,
                hintStyle: LivelyType.small(p.textDim).copyWith(fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
              // Live filter on every keystroke — submit-only meant
              // the list never updated unless the user pressed
              // Enter on the keyboard, which most never do.
              onChanged: (v) {
                _query.state = v;
                setState(() {});
              },
              onSubmitted: (v) => _query.state = v,
            ),
          ),
          if (_controller.text.isNotEmpty)
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close_rounded, size: 18, color: p.textMuted),
              onPressed: () {
                _controller.clear();
                _query.state = '';
                setState(() {});
              },
            ),
        ],
      ),
    );
  }
}

/// Round gradient "+" that opens the create-space flow.
class _CreateSpaceButton extends StatelessWidget {
  const _CreateSpaceButton();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Tooltip(
      message: AppLocalizations.of(context).communityNewSpaceTooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: p.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: p.primary.withValues(alpha: 0.30),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => context.push('/community/create'),
            child: Icon(Icons.add_rounded, color: p.onPrimary, size: 24),
          ),
        ),
      ),
    );
  }
}

class _EmptySpaces extends StatelessWidget {
  const _EmptySpaces();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.diversity_3_rounded, color: p.primary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            l.communitySpacesEmptyTap,
            style: LivelyType.small(p.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GoldButton(
            label: l.communityCreateSpace,
            full: false,
            small: true,
            onPressed: () => context.push('/community/create'),
          ),
        ],
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
          icon: Icon(Icons.notifications_none_rounded, color: p.textPrimary),
          onPressed: () => context.push('/community/notifications'),
        ),
        if (unread > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: p.error,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.background, width: 1.5),
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
            style: TextStyle(
              color: p.onPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: GestureDetector(
        onTap: () => context.push('/community/user/me'),
        child: Container(
          width: 34,
          height: 34,
          padding: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: p.primary.withValues(alpha: 0.5)),
          ),
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

/// ScrollBehavior that re-enables mouse-drag on Flutter web. The default
/// MaterialScrollBehavior only treats touch + stylus as drag-capable
/// pointers, which makes horizontal lists feel "frozen" in the browser.
/// Snapping category carousel: the centred card is full size, neighbours
/// shrink and fade, and each time a new card settles in the middle the
/// phone gives a light haptic tick. Tapping a side card centres it;
/// tapping the centred card opens the category.
class _CategoryCarousel extends StatefulWidget {
  const _CategoryCarousel({required this.categories});

  final List<SpaceCategory> categories;

  @override
  State<_CategoryCarousel> createState() => _CategoryCarouselState();
}

class _CategoryCarouselState extends State<_CategoryCarousel> {
  static const _cardWidth = 136.0;
  static const _height = 128.0;
  static const _minScale = 0.78;

  PageController? _controller;
  late int _current = widget.categories.length > 1 ? 1 : 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // viewportFraction depends on screen width, so build the controller
    // once MediaQuery is available (and rebuild it on rotation).
    final width = MediaQuery.sizeOf(context).width;
    final fraction = (_cardWidth / width).clamp(0.2, 0.9);
    if (_controller?.viewportFraction != fraction) {
      final page = _controller?.hasClients ?? false
          ? (_controller!.page ?? _current).round()
          : _current;
      _controller?.dispose();
      _controller = PageController(
        viewportFraction: fraction,
        initialPage: page,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    setState(() => _current = i);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller!;
    final cats = widget.categories;
    return SizedBox(
      height: _height,
      child: ScrollConfiguration(
        // Enable mouse-drag scrolling on Flutter web; the default web
        // scroll behavior only allows wheel.
        behavior: const _DragScrollBehavior(),
        child: PageView.builder(
          controller: controller,
          physics: const BouncingScrollPhysics(),
          itemCount: cats.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, i) => AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final page = controller.position.haveDimensions
                  ? controller.page ?? _current.toDouble()
                  : _current.toDouble();
              final t = (1 - (page - i).abs()).clamp(0.0, 1.0);
              final scale = _minScale + (1 - _minScale) * t;
              return Opacity(
                opacity: 0.55 + 0.45 * t,
                child: Transform.scale(scale: scale, child: child),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: CategoryCard(
                category: cats[i],
                onTap: i == _current
                    ? null
                    : () => controller.animateToPage(
                          i,
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                        ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
