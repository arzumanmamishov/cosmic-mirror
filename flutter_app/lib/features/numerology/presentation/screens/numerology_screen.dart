import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/numerology/domain/entities/numerology.dart';
import 'package:cosmic_mirror/features/numerology/presentation/providers/numerology_providers.dart';
import 'package:cosmic_mirror/features/numerology/presentation/widgets/cycles_timeline.dart';
import 'package:cosmic_mirror/features/numerology/presentation/widgets/karmic_grid.dart';
import 'package:cosmic_mirror/features/numerology/presentation/widgets/number_card.dart';
import 'package:cosmic_mirror/features/numerology/presentation/widgets/personal_today_card.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_backdrop.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class NumerologyScreen extends ConsumerWidget {
  const NumerologyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final readingAsync = ref.watch(numerologyReadingProvider);
    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: Text(AppLocalizations.of(context).numerologyTitle),
      ),
      body: LivelyBackdrop(
        seed: 23,
        intensity: 0.6,
        child: readingAsync.when(
          loading: () => const ShimmerList(itemCount: 5),
          error: (e, _) => ErrorView(
            error: e,
            onRetry: () => ref.invalidate(numerologyReadingProvider),
          ),
          data: (reading) => _Body(reading: reading),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.reading});
  final NumerologyReading reading;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(child: _Hero(reading: reading)),
          SliverToBoxAdapter(child: _TabBar()),
        ],
        body: TabBarView(
          children: [
            _CoreTab(profile: reading.profile),
            _TodayTab(cycles: reading.cycles),
            _CyclesTab(cycles: reading.cycles),
            _KarmicTab(profile: reading.profile),
            const _CompatTab(),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.reading});
  final NumerologyReading reading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final lp = reading.profile.lifePath;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: p.primaryGradient,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).numerologyLifePathBadge,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  lp.display,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 14),
                if (lp.isMaster)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizations.of(context).numerologyMasterBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              lp.description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          gradient: p.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: p.textSecondary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: l.numerologyTabCore),
          Tab(text: l.numerologyTabToday),
          Tab(text: l.numerologyTabCycles),
          Tab(text: l.numerologyTabKarmic),
          Tab(text: l.numerologyTabCompat),
        ],
      ),
    );
  }
}

class _CoreTab extends StatelessWidget {
  const _CoreTab({required this.profile});
  final NumerologyProfile profile;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        _CalculatorEntry(),
        const SizedBox(height: 12),
        NumberCard(
          title: l.numerologyCoreLifePath,
          number: profile.lifePath,
          icon: Icons.route_rounded,
        ),
        NumberCard(
          title: l.numerologyCoreExpression,
          number: profile.expression,
          icon: Icons.campaign_rounded,
        ),
        NumberCard(
          title: l.numerologyCoreSoulUrge,
          number: profile.soulUrge,
          icon: Icons.favorite_rounded,
        ),
        NumberCard(
          title: l.numerologyCorePersonality,
          number: profile.personality,
          icon: Icons.face_rounded,
        ),
        NumberCard(
          title: l.numerologyCoreMaturity,
          number: profile.maturity,
          icon: Icons.workspace_premium_rounded,
        ),
        NumberCard(
          title: l.numerologyCoreBirthday,
          number: profile.birthday,
          icon: Icons.cake_rounded,
        ),
      ],
    );
  }
}

/// CTA card on the Core tab that opens the standalone Name Calculator —
/// users can analyze any name (partner, friend, business, character)
/// without touching their own profile.
class _CalculatorEntry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return InkWell(
      onTap: () => context.push('/numerology/name-calculator'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.gold.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.gold.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.calculate_rounded, color: p.gold, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l.numerologyNameOpenCalculator,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _TodayTab extends StatelessWidget {
  const _TodayTab({required this.cycles});
  final NumerologyCycles cycles;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        PersonalTodayCard(cycles: cycles),
      ],
    );
  }
}

class _CyclesTab extends StatelessWidget {
  const _CyclesTab({required this.cycles});
  final NumerologyCycles cycles;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        CyclesTimeline(
          pinnacles: cycles.pinnacles,
          challenges: cycles.challenges,
          currentAge: cycles.currentAge,
        ),
      ],
    );
  }
}

class _KarmicTab extends StatelessWidget {
  const _KarmicTab({required this.profile});
  final NumerologyProfile profile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        KarmicGrid(
          karmicLessons: profile.karmicLessons,
          hiddenPassion: profile.hiddenPassion,
        ),
      ],
    );
  }
}

class _CompatTab extends StatelessWidget {
  const _CompatTab();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 40),
      child: Column(
        children: [
          Icon(Icons.favorite_rounded, color: p.accent, size: 48),
          const SizedBox(height: 14),
          Text(
            l.numerologyCompareWith,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.numerologyCompatBlurb,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textSecondary, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: () => context.push('/numerology/compatibility'),
            style: ElevatedButton.styleFrom(
              backgroundColor: p.primary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(l.numerologyOpenCompat),
          ),
        ],
      ),
    );
  }
}
