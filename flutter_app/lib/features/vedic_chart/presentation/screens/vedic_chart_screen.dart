import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/vedic_chart/data/repositories/vedic_repository.dart';
import 'package:cosmic_mirror/features/vedic_chart/domain/entities/vedic_chart.dart';
import 'package:cosmic_mirror/features/vedic_chart/presentation/providers/vedic_providers.dart';
import 'package:cosmic_mirror/features/vedic_chart/presentation/widgets/ashtakavarga_grid.dart';
import 'package:cosmic_mirror/features/vedic_chart/presentation/widgets/dasha_timeline.dart';
import 'package:cosmic_mirror/features/vedic_chart/presentation/widgets/nakshatra_card.dart';
import 'package:cosmic_mirror/features/vedic_chart/presentation/widgets/north_indian_chart.dart';
import 'package:cosmic_mirror/features/vedic_chart/presentation/widgets/shadbala_radar.dart';
import 'package:cosmic_mirror/features/vedic_chart/presentation/widgets/yoga_card.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:cosmic_mirror/shared/widgets/staggered_fade_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vedic / Jyotish chart screen. North Indian diamond layout in the hero,
/// 9 horizontally scrollable tabs below for the full classical readout.
class VedicChartScreen extends ConsumerWidget {
  const VedicChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(activeChartProvider);
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Vedic Chart'),
        actions: const [
          _AyanamsaMenu(),
          SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CosmicStarfield(
              color: p.textPrimary,
              intensity: 0.7,
            ),
          ),
          chartAsync.when(
            loading: () => const ShimmerList(itemCount: 4),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(activeChartProvider),
            ),
            data: (chart) => _Body(chart: chart),
          ),
        ],
      ),
    );
  }
}

class _AyanamsaMenu extends ConsumerWidget {
  const _AyanamsaMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final selected = ref.watch(selectedAyanamsaProvider);
    return PopupMenuButton<Ayanamsa>(
      tooltip: 'Ayanamsa',
      icon: Icon(Icons.tune_rounded, color: p.textPrimary),
      color: p.surfaceElevated,
      onSelected: (v) =>
          ref.read(selectedAyanamsaProvider.notifier).state = v,
      itemBuilder: (_) => Ayanamsa.values
          .map(
            (a) => PopupMenuItem<Ayanamsa>(
              value: a,
              child: Row(
                children: [
                  if (a == selected)
                    Icon(Icons.check_rounded, size: 16, color: p.primary)
                  else
                    const SizedBox(width: 16),
                  const SizedBox(width: 8),
                  Text(
                    a.label,
                    style: TextStyle(color: p.textPrimary, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.chart});

  final VedicChart chart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 9,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: FadeSlideIn(child: _Hero(chart: chart)),
          ),
          SliverToBoxAdapter(
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: const _TabBar(),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _PlanetsTab(chart: chart),
            _BhavasTab(chart: chart),
            _AspectsTab(chart: chart),
            _NakshatrasTab(chart: chart),
            const _VargasTab(),
            const _DashaTab(),
            const _YogasTab(),
            const _ShadbalaTab(),
            const _AshtakavargaTab(),
          ],
        ),
      ),
    );
  }
}

// =================== Hero ===================

class _Hero extends ConsumerWidget {
  const _Hero({required this.chart});

  final VedicChart chart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final sun = chart.planets.where((e) => e.name == 'Sun').firstOrNull;
    final moon = chart.planets.where((e) => e.name == 'Moon').firstOrNull;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _BigSign(
                  label: 'LAGNA',
                  english: chart.lagna.sign,
                  sanskrit: chart.lagna.signSanskrit,
                  color: p.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BigSign(
                  label: 'CHANDRA',
                  english: moon?.sign ?? '—',
                  sanskrit: moon?.signSanskrit ?? '',
                  color: p.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BigSign(
                  label: 'SURYA',
                  english: sun?.sign ?? '—',
                  sanskrit: sun?.signSanskrit ?? '',
                  color: p.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: p.gold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Atmakaraka: ${chart.atmaKaraka}',
              style: TextStyle(
                color: p.gold,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 24),
          NorthIndianChart(chart: chart),
          const SizedBox(height: 12),
          Text(
            '${chart.vargaName} (D${chart.varga}) · ${chart.ayanamsa} ayanamsa',
            style: TextStyle(color: p.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _BigSign extends StatelessWidget {
  const _BigSign({
    required this.label,
    required this.english,
    required this.sanskrit,
    required this.color,
  });

  final String label;
  final String english;
  final String sanskrit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.glassBorder),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            english,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            sanskrit,
            style: TextStyle(color: p.textTertiary, fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// =================== Tab bar ===================

class _TabBar extends StatelessWidget {
  const _TabBar();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
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
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Planets'),
          Tab(text: 'Bhavas'),
          Tab(text: 'Aspects'),
          Tab(text: 'Nakshatras'),
          Tab(text: 'Vargas'),
          Tab(text: 'Dasha'),
          Tab(text: 'Yogas'),
          Tab(text: 'Shadbala'),
          Tab(text: 'Ashtakavarga'),
        ],
      ),
    );
  }
}

// =================== Tab contents ===================

class _PlanetsTab extends StatelessWidget {
  const _PlanetsTab({required this.chart});
  final VedicChart chart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      itemCount: chart.planets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final pl = chart.planets[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.glassBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _dignityColor(pl.dignity, p).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pl.name.substring(0, 2),
                  style: TextStyle(
                    color: _dignityColor(pl.dignity, p),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${pl.name} · ${pl.sanskrit}',
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (pl.retrograde)
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _badge('Rx', p.warning, p),
                          ),
                        if (pl.combust)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: _badge('Combust', p.error, p),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pl.sign} (${pl.signSanskrit}) · '
                      '${pl.degree.toStringAsFixed(1)}° · House ${pl.house}',
                      style: TextStyle(color: p.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pl.nakshatra.name} pada ${pl.pada} · '
                      '${_dignityLabel(pl.dignity)}',
                      style: TextStyle(color: p.textTertiary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _badge(String text, Color color, AppPalette p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Color _dignityColor(String dignity, AppPalette p) {
    switch (dignity) {
      case 'exalted':
      case 'mooltrikona':
        return p.success;
      case 'debilitated':
        return p.error;
      case 'own':
        return p.gold;
      case 'friend':
        return p.primary;
      case 'enemy':
        return p.warning;
      default:
        return p.textPrimary;
    }
  }

  String _dignityLabel(String d) =>
      d.isEmpty ? '' : '${d[0].toUpperCase()}${d.substring(1)}';
}

class _BhavasTab extends StatelessWidget {
  const _BhavasTab({required this.chart});
  final VedicChart chart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      itemCount: chart.bhavas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final b = chart.bhavas[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.glassBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: p.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${b.number}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.description,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${b.sign} (${b.signSanskrit}) · Lord ${b.lord}',
                      style: TextStyle(color: p.textSecondary, fontSize: 12),
                    ),
                    if (b.planets.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Occupants: ${b.planets.join(", ")}',
                        style: TextStyle(color: p.textTertiary, fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AspectsTab extends StatelessWidget {
  const _AspectsTab({required this.chart});
  final VedicChart chart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final grahaAspects =
        chart.aspects.where((a) => a.to != 'House').toList();
    if (grahaAspects.isEmpty) {
      return Center(
        child: Text(
          'No graha-to-graha drishti',
          style: TextStyle(color: p.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      itemCount: grahaAspects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final a = grahaAspects[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.glassBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  a.type,
                  style: TextStyle(
                    color: p.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${a.from} aspects ${a.to}',
                  style: TextStyle(color: p.textPrimary, fontSize: 13),
                ),
              ),
              Text(
                '×${a.strength.toStringAsFixed(2)}',
                style: TextStyle(color: p.textTertiary, fontSize: 11),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NakshatrasTab extends StatelessWidget {
  const _NakshatrasTab({required this.chart});
  final VedicChart chart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        NakshatraCard(
          title: 'Lagna',
          nakshatra: chart.lagna.nakshatra,
          pada: chart.lagna.pada,
        ),
        for (final pl in chart.planets)
          NakshatraCard(
            title: pl.name,
            nakshatra: pl.nakshatra,
            pada: pl.pada,
          ),
      ],
    );
  }
}

class _VargasTab extends ConsumerWidget {
  const _VargasTab();

  static const _vargas = [
    (1, 'D1 Rasi'),
    (2, 'D2 Hora'),
    (3, 'D3 Drekkana'),
    (4, 'D4 Chaturthamsa'),
    (7, 'D7 Saptamsa'),
    (9, 'D9 Navamsa'),
    (10, 'D10 Dasamsa'),
    (12, 'D12 Dvadasamsa'),
    (16, 'D16 Shodasamsa'),
    (20, 'D20 Vimsamsa'),
    (24, 'D24 Chaturvimsa'),
    (27, 'D27 Bhamsa'),
    (30, 'D30 Trimsamsa'),
    (40, 'D40 Khavedamsa'),
    (45, 'D45 Akshavedamsa'),
    (60, 'D60 Shashtiamsa'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final selected = ref.watch(selectedVargaProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _vargas.map((v) {
            final isSelected = v.$1 == selected;
            return GestureDetector(
              onTap: () =>
                  ref.read(selectedVargaProvider.notifier).state = v.$1,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected ? p.primaryGradient : null,
                  color: isSelected ? null : p.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.glassBorder),
                ),
                child: Text(
                  v.$2,
                  style: TextStyle(
                    color: isSelected ? Colors.white : p.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'The hero chart above re-renders for the selected Varga. '
          'Each divisional chart reveals a different facet of life: '
          'D9 marriage and dharma, D10 career, D12 parents, D60 past karma.',
          style: TextStyle(color: p.textSecondary, fontSize: 12, height: 1.5),
        ),
      ],
    );
  }
}

class _DashaTab extends ConsumerWidget {
  const _DashaTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashaAsync = ref.watch(vedicDashaProvider);
    return dashaAsync.when(
      loading: () => const ShimmerList(itemCount: 5),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(vedicDashaProvider),
      ),
      data: (tree) => DashaTimeline(tree: tree),
    );
  }
}

class _YogasTab extends ConsumerWidget {
  const _YogasTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final yogasAsync = ref.watch(vedicYogasProvider);
    return yogasAsync.when(
      loading: () => const ShimmerList(itemCount: 4),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(vedicYogasProvider),
      ),
      data: (yogas) {
        final active = yogas.where((y) => y.active).toList();
        if (active.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No active classical yogas detected for this chart.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.textSecondary, fontSize: 13),
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [for (final y in active) YogaCard(yoga: y)],
        );
      },
    );
  }
}

class _ShadbalaTab extends ConsumerWidget {
  const _ShadbalaTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shadbalaAsync = ref.watch(vedicShadbalaProvider);
    return shadbalaAsync.when(
      loading: () => const ShimmerList(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(vedicShadbalaProvider),
      ),
      data: (map) {
        final entries = map.entries.toList();
        if (entries.isEmpty) {
          return const Center(child: Text('No Shadbala data'));
        }
        return PageView.builder(
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final e = entries[i];
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: ShadbalaRadar(planet: e.key, bala: e.value),
            );
          },
        );
      },
    );
  }
}

class _AshtakavargaTab extends ConsumerWidget {
  const _AshtakavargaTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avAsync = ref.watch(vedicAshtakavargaProvider);
    return avAsync.when(
      loading: () => const ShimmerList(itemCount: 4),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(vedicAshtakavargaProvider),
      ),
      data: (av) => AshtakavargaGrid(av: av),
    );
  }
}
