import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/features/ai_chat/presentation/screens/chat_threads_screen.dart';
import 'package:cosmic_mirror/features/community/presentation/screens/spaces_list_screen.dart';
import 'package:cosmic_mirror/features/home/presentation/widgets/discussions_section.dart';
import 'package:cosmic_mirror/features/home/presentation/widgets/today_in_the_sky_card.dart';
import 'package:cosmic_mirror/features/home/presentation/widgets/header_bar.dart';
import 'package:cosmic_mirror/features/home/presentation/widgets/premium_upgrade_card.dart';
import 'package:cosmic_mirror/features/home/presentation/widgets/todays_insight_card.dart';
import 'package:cosmic_mirror/shared/widgets/category_chip_bar.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/pill_search_bar.dart';
import 'package:cosmic_mirror/shared/widgets/staggered_fade_in.dart';

/// Astrolite-aligned home: cosmic backdrop, greeting + pill search at the
/// top, horizontal category chips beneath, glass content cards, and a
/// polished 5-tab bottom nav with a purple-gradient active pill.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      body: Stack(
        children: [
          _ZodiacBackdrop(palette: p),
          Positioned.fill(
            child: IndexedStack(
              index: _currentIndex,
              children: const [
                _DiscoverTab(),
                _ChartsTab(),
                ChatThreadsScreen(),
                _CommunityTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

/// Subtle radial backdrop with twinkling starfield.
class _ZodiacBackdrop extends StatelessWidget {
  const _ZodiacBackdrop({required this.palette});
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.3),
                  radius: 1.2,
                  colors: [
                    palette.primary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          CosmicStarfield(
            color: palette.textPrimary,
            starCount: 80,
            intensity: 0.9,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Discover tab — greeting, search, category chips, premium card, insight,
// astrologers, discussions. Chips filter what's shown below the search.
// ============================================================================

// Stable keys — never user-facing. Display labels come from AppLocalizations.
const _discoverCategoryKeys = ['All', 'Daily', 'Sky', 'Community'];

class _DiscoverTab extends StatefulWidget {
  const _DiscoverTab();

  @override
  State<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<_DiscoverTab> {
  String _category = 'All';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _showFor(String section) {
    if (_category == 'All') return true;
    return section == _category;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.categoryAll,
      l10n.categoryDaily,
      l10n.categorySky,
      l10n.categoryCommunity,
    ];
    final selectedIndex = _discoverCategoryKeys.indexOf(_category);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const FadeSlideIn(child: HomeHeaderBar()),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: const Duration(milliseconds: 60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PillSearchBar(
                controller: _searchCtrl,
                hint: l10n.homeSearchHint,
                onSubmitted: (_) {},
              ),
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: CategoryChipBar(
              categories: labels,
              selected: labels[selectedIndex],
              onSelected: (label) {
                final i = labels.indexOf(label);
                if (i >= 0) {
                  setState(() => _category = _discoverCategoryKeys[i]);
                }
              },
            ),
          ),
          const SizedBox(height: 18),
          if (_showFor('All')) ...[
            const FadeSlideIn(
              delay: Duration(milliseconds: 180),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: PremiumUpgradeCard(),
              ),
            ),
            const SizedBox(height: 18),
          ],
          if (_showFor('Daily')) ...[
            const FadeSlideIn(
              delay: Duration(milliseconds: 220),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: TodaysInsightCard(),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_showFor('Sky')) ...[
            const FadeSlideIn(
              delay: Duration(milliseconds: 260),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: TodayInTheSkyCard(),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (_showFor('Community')) ...[
            const FadeSlideIn(
              delay: Duration(milliseconds: 320),
              child: DiscussionsSection(),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// Charts tab — search + category chips that filter feature cards.
// ============================================================================

class _ChartFeature {
  const _ChartFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.gradientBuilder,
    required this.category,
    this.badge,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Gradient Function(AppPalette p) gradientBuilder;
  final String category; // 'Western' | 'Vedic' | 'Esoteric' | 'Forecast'
  final String? badge;
}

// Stable chart-category keys — display labels come from AppLocalizations.
const _chartCategoryKeys = [
  'All',
  'Western',
  'Vedic',
  'Esoteric',
  'Forecast',
];

List<_ChartFeature> _allChartFeatures() => [
      _ChartFeature(
        icon: Icons.auto_awesome_rounded,
        title: 'Birth Chart',
        subtitle: 'Planets, houses, aspects.\nThe map of who you are.',
        route: '/chart',
        gradientBuilder: (p) => p.primaryGradient,
        category: 'Western',
      ),
      _ChartFeature(
        icon: Icons.brightness_5_rounded,
        title: 'Vedic Chart',
        subtitle:
            'Sidereal kundli, nakshatras, dashas,\n16 vargas, yogas — full Jyotish.',
        route: '/vedic-chart',
        gradientBuilder: (p) => LinearGradient(colors: [p.gold, p.accent]),
        category: 'Vedic',
        badge: 'New',
      ),
      _ChartFeature(
        icon: Icons.numbers_rounded,
        title: 'Numerology',
        subtitle:
            'Life path, soul urge, cycles\n+ karmic patterns + compatibility.',
        route: '/numerology',
        gradientBuilder: (p) => LinearGradient(colors: [p.accent, p.gold]),
        category: 'Esoteric',
        badge: 'New',
      ),
      _ChartFeature(
        icon: Icons.account_tree_rounded,
        title: 'Human Design',
        subtitle: 'Type, strategy, authority,\nyour body graph blueprint.',
        route: '/human-design',
        gradientBuilder: (p) => LinearGradient(colors: [p.primary, p.accent]),
        category: 'Esoteric',
        badge: 'New',
      ),
      _ChartFeature(
        icon: Icons.timeline_rounded,
        title: 'Cosmic Timeline',
        subtitle:
            'Your life mapped against the sky.\nMoments + active transits.',
        route: '/life-timeline',
        gradientBuilder: (p) => p.premiumGradient,
        category: 'Forecast',
        badge: 'New',
      ),
      _ChartFeature(
        icon: Icons.calendar_month_rounded,
        title: 'Yearly Forecast',
        subtitle: 'What 2026 holds across\nlove, work, and growth.',
        route: '/yearly-forecast',
        gradientBuilder: (p) => LinearGradient(colors: [p.gold, p.warning]),
        category: 'Forecast',
      ),
      _ChartFeature(
        icon: Icons.timer_rounded,
        title: 'Transit Forecast',
        subtitle: 'The next 30 days, 3 months,\nand year ahead.',
        route: '/timeline',
        gradientBuilder: (p) => LinearGradient(colors: [p.accent, p.primary]),
        category: 'Forecast',
      ),
    ];

class _ChartsTab extends StatefulWidget {
  const _ChartsTab();

  @override
  State<_ChartsTab> createState() => _ChartsTabState();
}

class _ChartsTabState extends State<_ChartsTab> {
  String _category = 'All';
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final all = _allChartFeatures();
    final q = _query.trim().toLowerCase();
    final filtered = all.where((f) {
      final matchesCat = _category == 'All' || f.category == _category;
      final matchesQuery = q.isEmpty ||
          f.title.toLowerCase().contains(q) ||
          f.subtitle.toLowerCase().contains(q);
      return matchesCat && matchesQuery;
    }).toList();

    final l10n = AppLocalizations.of(context);
    final chartLabels = [
      l10n.categoryAll,
      l10n.chartCategoryWestern,
      l10n.chartCategoryVedic,
      l10n.chartCategoryEsoteric,
      l10n.chartCategoryForecast,
    ];
    final selectedIdx = _chartCategoryKeys.indexOf(_category);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: FadeSlideIn(
              child: Text(
                l10n.homeChartsTitle,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: Text(
                l10n.homeChartsSubtitle,
                style: TextStyle(color: p.textSecondary, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: const Duration(milliseconds: 100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PillSearchBar(
                controller: _searchCtrl,
                hint: l10n.homeChartsSearchHint,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: const Duration(milliseconds: 140),
            child: CategoryChipBar(
              categories: chartLabels,
              selected: chartLabels[selectedIdx],
              onSelected: (label) {
                final i = chartLabels.indexOf(label);
                if (i >= 0) {
                  setState(() => _category = _chartCategoryKeys[i]);
                }
              },
            ),
          ),
          const SizedBox(height: 18),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                'Nothing matches that yet.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textSecondary, fontSize: 13),
              ),
            )
          else
            for (var i = 0; i < filtered.length; i++) ...[
              FadeSlideIn(
                delay: Duration(milliseconds: 140 + i * 30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _ChartFeatureCard(feature: filtered[i]),
                ),
              ),
              const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }
}

class _ChartFeatureCard extends StatelessWidget {
  const _ChartFeatureCard({required this.feature});
  final _ChartFeature feature;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: () => context.push(feature.route),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: p.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: feature.gradientBuilder(p),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: p.primary.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(feature.icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        feature.title,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (feature.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: p.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            feature.badge!,
                            style: TextStyle(
                              color: p.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    feature.subtitle,
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: p.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityTab extends StatelessWidget {
  const _CommunityTab();

  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: SpacesListScreen());
  }
}

// ============================================================================
// Bottom nav — minimal 4-item bar matching the Astrolite reference. Active
// item shows a brighter icon + label and a small accent dot indicator
// underneath; inactive items stay quiet. Profile lives behind the avatar
// in the home header instead of taking a slot here.
// ============================================================================

class _CustomBottomNav extends StatelessWidget {
  const _CustomBottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: 0.92),
        border: Border(top: BorderSide(color: p.glassBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: l10n.navHome,
                active: currentIndex == 0,
                onTap: () => onTap(0),
                palette: p,
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                activeIcon: Icons.bar_chart_rounded,
                label: l10n.navCharts,
                active: currentIndex == 1,
                onTap: () => onTap(1),
                palette: p,
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: l10n.navChat,
                active: currentIndex == 2,
                onTap: () => onTap(2),
                palette: p,
              ),
              _NavItem(
                icon: Icons.forum_outlined,
                activeIcon: Icons.forum_rounded,
                label: l10n.navCommunity,
                active: currentIndex == 3,
                onTap: () => onTap(3),
                palette: p,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    required this.palette,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final activeColor = palette.textPrimary;
    final inactiveColor = palette.textSecondary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: active ? activeColor : inactiveColor,
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: active ? 5 : 0,
              height: active ? 5 : 0,
              decoration: BoxDecoration(
                gradient: active ? palette.primaryGradient : null,
                shape: BoxShape.circle,
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: palette.primary.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
