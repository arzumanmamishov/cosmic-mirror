import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/ai_chat/presentation/screens/chat_threads_screen.dart';
import 'package:cosmic_mirror/features/community/presentation/screens/spaces_list_screen.dart';
import 'package:cosmic_mirror/features/home/presentation/widgets/astrologers_section.dart';
import 'package:cosmic_mirror/features/home/presentation/widgets/discussions_section.dart';
import 'package:cosmic_mirror/features/home/presentation/widgets/header_bar.dart';
import 'package:cosmic_mirror/features/home/presentation/widgets/premium_upgrade_card.dart';
import 'package:cosmic_mirror/features/home/presentation/widgets/todays_insight_card.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/staggered_fade_in.dart';

/// Redesigned home screen matching the premium reference design:
/// header avatar + name, premium upgrade card, today's insight,
/// popular astrologers, featured discussions, and a custom 4-tab nav.
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

/// Subtle radial backdrop with twinkling starfield, suggesting the zodiac
/// wheel watermark in the reference design. Stays out of the way of the
/// foreground content (set as IgnorePointer inside the starfield).
class _ZodiacBackdrop extends StatelessWidget {
  const _ZodiacBackdrop({required this.palette});
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Radial primary glow at the top
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
          // Twinkling stars
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

class _DiscoverTab extends StatelessWidget {
  const _DiscoverTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: const [
          FadeSlideIn(child: HomeHeaderBar()),
          SizedBox(height: 20),
          FadeSlideIn(
            delay: Duration(milliseconds: 80),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: PremiumUpgradeCard(),
            ),
          ),
          SizedBox(height: 18),
          FadeSlideIn(
            delay: Duration(milliseconds: 160),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TodaysInsightCard(),
            ),
          ),
          SizedBox(height: 24),
          FadeSlideIn(
            delay: Duration(milliseconds: 240),
            child: AstrologersSection(),
          ),
          SizedBox(height: 24),
          FadeSlideIn(
            delay: Duration(milliseconds: 320),
            child: DiscussionsSection(),
          ),
        ],
      ),
    );
  }
}

class _ChartsTab extends StatelessWidget {
  const _ChartsTab();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          FadeSlideIn(
            child: Text(
              'Your Cosmos',
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          FadeSlideIn(
            delay: const Duration(milliseconds: 60),
            child: Text(
              'Your blueprint and your story.',
              style: TextStyle(color: p.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(height: 22),
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: _ChartFeatureCard(
              icon: Icons.auto_awesome_rounded,
              title: 'Birth Chart',
              subtitle: 'Planets, houses, aspects.\nThe map of who you are.',
              onTap: () => context.push('/chart'),
              gradient: p.primaryGradient,
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: const Duration(milliseconds: 150),
            child: _ChartFeatureCard(
              icon: Icons.brightness_5_rounded,
              title: 'Vedic Chart',
              subtitle:
                  'Sidereal kundli, nakshatras, dashas,\n16 vargas, yogas — full Jyotish.',
              onTap: () => context.push('/vedic-chart'),
              gradient: LinearGradient(
                colors: [p.gold, p.accent],
              ),
              badge: 'New',
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: const Duration(milliseconds: 180),
            child: _ChartFeatureCard(
              icon: Icons.timeline_rounded,
              title: 'Cosmic Timeline',
              subtitle:
                  'Your life mapped against the sky.\nMoments + active transits.',
              onTap: () => context.push('/life-timeline'),
              gradient: p.premiumGradient,
              badge: 'New',
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: const Duration(milliseconds: 240),
            child: _ChartFeatureCard(
              icon: Icons.calendar_month_rounded,
              title: 'Yearly Forecast',
              subtitle: 'What 2026 holds across\nlove, work, and growth.',
              onTap: () => context.push('/yearly-forecast'),
              gradient: LinearGradient(
                colors: [p.gold, p.warning],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: const Duration(milliseconds: 300),
            child: _ChartFeatureCard(
              icon: Icons.timer_rounded,
              title: 'Transit Forecast',
              subtitle: 'The next 30 days, 3 months,\nand year ahead.',
              onTap: () => context.push('/timeline'),
              gradient: LinearGradient(
                colors: [p.accent, p.primary],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartFeatureCard extends StatelessWidget {
  const _ChartFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.gradient,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Gradient gradient;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onTap,
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
                gradient: gradient,
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
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (badge != null) ...[
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
                            badge!,
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
                    subtitle,
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

/// Bottom navigation with three primary destinations:
/// Discover, Charts, and Community.
class _CustomBottomNav extends StatelessWidget {
  const _CustomBottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.glassBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.travel_explore_rounded,
                activeIcon: Icons.travel_explore_rounded,
                label: 'Discover',
                active: currentIndex == 0,
                onTap: () => onTap(0),
                palette: p,
              ),
              _NavItem(
                icon: Icons.bar_chart_rounded,
                activeIcon: Icons.bar_chart_rounded,
                label: 'Charts',
                active: currentIndex == 1,
                onTap: () => onTap(1),
                palette: p,
              ),
              _NavItem(
                icon: Icons.auto_awesome_rounded,
                activeIcon: Icons.auto_awesome_rounded,
                label: 'Astrologer',
                active: currentIndex == 2,
                onTap: () => onTap(2),
                palette: p,
              ),
              _NavItem(
                icon: Icons.forum_rounded,
                activeIcon: Icons.forum_rounded,
                label: 'Community',
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
    final color = active ? palette.accent : palette.textSecondary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Icon(active ? activeIcon : icon, color: color, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
