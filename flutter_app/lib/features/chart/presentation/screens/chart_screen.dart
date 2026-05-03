import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/features/chart/presentation/widgets/natal_chart_wheel.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_pulse.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:cosmic_mirror/shared/widgets/staggered_fade_in.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final chartProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final client = ref.read(apiClientProvider);
  return client.get<Map<String, dynamic>>(ApiEndpoints.chart);
});

class ChartScreen extends ConsumerWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(chartProvider);
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Birth Chart'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CosmicStarfield(
              color: p.textPrimary,
              starCount: 60,
              intensity: 0.7,
            ),
          ),
          chartAsync.when(
            loading: () => const ShimmerList(itemCount: 4),
            error: (error, _) => ErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(chartProvider),
            ),
            data: (chart) => _ChartContent(chart: chart),
          ),
        ],
      ),
    );
  }
}

class _ChartContent extends StatelessWidget {
  const _ChartContent({required this.chart});
  final Map<String, dynamic> chart;

  @override
  Widget build(BuildContext context) {
    final planets = (chart['planets'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final houses = (chart['houses'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final aspects = (chart['aspects'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final elements = chart['elements'] as Map<String, dynamic>? ?? {};

    final big3 = _bigThree(planets, houses);

    return DefaultTabController(
      length: 4,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: FadeSlideIn(
              child: _Hero(
                planets: planets,
                houses: houses,
                aspects: aspects,
                big3: big3,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: const _DetailTabs(),
            ),
          ),
        ],
        body: TabBarView(
          children: [
            _PlanetsTab(planets: planets),
            _HousesTab(houses: houses),
            _AspectsTab(aspects: aspects),
            _ElementsTab(elements: elements),
          ],
        ),
      ),
    );
  }

  _BigThree _bigThree(
    List<Map<String, dynamic>> planets,
    List<Map<String, dynamic>> houses,
  ) {
    String? sunSign;
    String? moonSign;
    for (final p in planets) {
      if (p['name'] == 'Sun') sunSign = p['sign'] as String?;
      if (p['name'] == 'Moon') moonSign = p['sign'] as String?;
    }
    final risingSign =
        houses.isNotEmpty ? houses.first['sign'] as String? : null;
    return _BigThree(sun: sunSign, moon: moonSign, rising: risingSign);
  }
}

class _BigThree {
  const _BigThree({this.sun, this.moon, this.rising});
  final String? sun;
  final String? moon;
  final String? rising;
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.planets,
    required this.houses,
    required this.aspects,
    required this.big3,
  });

  final List<Map<String, dynamic>> planets;
  final List<Map<String, dynamic>> houses;
  final List<Map<String, dynamic>> aspects;
  final _BigThree big3;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 24),
      child: Column(
        children: [
          // Big three signs
          Row(
            children: [
              Expanded(
                child: _BigSignCard(
                  label: 'Sun',
                  sign: big3.sun ?? '—',
                  glyph: '☉',
                  color: p.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BigSignCard(
                  label: 'Moon',
                  sign: big3.moon ?? '—',
                  glyph: '☽',
                  color: p.accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BigSignCard(
                  label: 'Rising',
                  sign: big3.rising ?? '—',
                  glyph: '↑',
                  color: p.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // The wheel itself, with a subtle breathing glow
          CosmicPulse(
            color: p.primary,
            maxRadius: 200,
            duration: const Duration(seconds: 5),
            child: NatalChartWheel(
              planets: planets,
              houses: houses,
              aspects: aspects,
              size: 320,
            ),
          ),
          const SizedBox(height: 20),
          _LegendRow(),
          const SizedBox(height: 16),
          _VedicChartLink(),
        ],
      ),
    );
  }
}

class _VedicChartLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: () => context.push('/vedic-chart'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.gold.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.brightness_5_rounded, color: p.gold, size: 18),
            const SizedBox(width: 10),
            Text(
              'View Vedic Chart',
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, color: p.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _BigSignCard extends StatelessWidget {
  const _BigSignCard({
    required this.label,
    required this.sign,
    required this.glyph,
    required this.color,
  });

  final String label;
  final String sign;
  final String glyph;
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
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              glyph,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: p.textTertiary,
              fontSize: 9,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sign,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget chip(String label, Color color) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        chip('Conjunction', p.textPrimary),
        chip('Sextile', p.success),
        chip('Square', p.error),
        chip('Trine', p.accent),
        chip('Opposition', const Color(0xFFE14B8A)),
      ],
    );
  }
}

class _DetailTabs extends StatelessWidget {
  const _DetailTabs();

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
          Tab(text: 'Houses'),
          Tab(text: 'Aspects'),
          Tab(text: 'Elements'),
        ],
      ),
    );
  }
}

// =================== Detail tabs ===================

class _PlanetsTab extends StatelessWidget {
  const _PlanetsTab({required this.planets});
  final List<Map<String, dynamic>> planets;

  static const _glyphs = {
    'Sun': '☉', 'Moon': '☽', 'Mercury': '☿', 'Venus': '♀',
    'Mars': '♂', 'Jupiter': '♃', 'Saturn': '♄', 'Uranus': '♅',
    'Neptune': '♆', 'Pluto': '♇', 'North Node': '☊', 'Chiron': '⚷',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (planets.isEmpty) {
      return Center(
        child: Text('No planet data', style: TextStyle(color: p.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      itemCount: planets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final pl = planets[i];
        final name = pl['name'] as String? ?? '';
        final sign = pl['sign'] as String? ?? '';
        final house = pl['house'] as int?;
        final degree = (pl['degree'] as num?)?.toDouble() ?? 0;
        final retro = (pl['retrograde'] as bool?) ?? false;

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
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  _glyphs[name] ?? '★',
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
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
                          name,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (retro) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: p.warning.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Rx',
                              style: TextStyle(
                                color: p.warning,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$sign · ${degree.toStringAsFixed(1)}°'
                      '${house != null ? ' · House $house' : ''}',
                      style: TextStyle(color: p.textSecondary, fontSize: 12),
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
}

class _HousesTab extends StatelessWidget {
  const _HousesTab({required this.houses});
  final List<Map<String, dynamic>> houses;

  static const _meanings = {
    1: 'Self & Identity',
    2: 'Values & Resources',
    3: 'Communication',
    4: 'Home & Roots',
    5: 'Creativity & Joy',
    6: 'Work & Wellness',
    7: 'Partnerships',
    8: 'Transformation',
    9: 'Philosophy & Travel',
    10: 'Career & Legacy',
    11: 'Community & Vision',
    12: 'Spirit & Surrender',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (houses.isEmpty) {
      return Center(
        child: Text('No house data', style: TextStyle(color: p.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      itemCount: houses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final h = houses[i];
        final houseNum = h['number'] as int? ?? (i + 1);
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: p.primaryGradient,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$houseNum',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _meanings[houseNum] ?? 'House $houseNum',
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${h['sign']} · ${(h['degree'] as num? ?? 0).toStringAsFixed(1)}°',
                      style: TextStyle(color: p.textSecondary, fontSize: 12),
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
}

class _AspectsTab extends StatelessWidget {
  const _AspectsTab({required this.aspects});
  final List<Map<String, dynamic>> aspects;

  static const _typeColor = {
    'conjunction': Color(0xFFE6EAF2),
    'sextile': Color(0xFF5ED39A),
    'square': Color(0xFFF07C82),
    'trine': Color(0xFF4DA3FF),
    'opposition': Color(0xFFE14B8A),
    'quincunx': Color(0xFFF2B66D),
  };

  static const _typeSymbol = {
    'conjunction': '☌',
    'sextile': '⚹',
    'square': '□',
    'trine': '△',
    'opposition': '☍',
    'quincunx': '⚻',
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (aspects.isEmpty) {
      return Center(
        child: Text('No aspect data', style: TextStyle(color: p.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      itemCount: aspects.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final a = aspects[i];
        final type = a['type'] as String? ?? '';
        final color = _typeColor[type] ?? p.textSecondary;
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  _typeSymbol[type] ?? '·',
                  style: TextStyle(color: color, fontSize: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${a['planet1']} ${type[0].toUpperCase()}${type.substring(1)} ${a['planet2']}',
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Orb ${(a['orb'] as num? ?? 0).toStringAsFixed(2)}°',
                      style: TextStyle(color: p.textSecondary, fontSize: 11),
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
}

class _ElementsTab extends StatelessWidget {
  const _ElementsTab({required this.elements});
  final Map<String, dynamic> elements;

  static const _colors = {
    'fire': Color(0xFFF07C82),
    'earth': Color(0xFF5ED39A),
    'air': Color(0xFF4DA3FF),
    'water': Color(0xFF9966CC),
  };

  static const _icons = {
    'fire': Icons.local_fire_department_rounded,
    'earth': Icons.terrain_rounded,
    'air': Icons.air_rounded,
    'water': Icons.water_drop_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final entries = elements.entries
        .where((e) => _colors.containsKey(e.key.toLowerCase()))
        .toList();
    if (entries.isEmpty) {
      return Center(
        child: Text('No element data',
            style: TextStyle(color: p.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final e = entries[i];
        final pct = (e.value as num).toDouble();
        final color = _colors[e.key.toLowerCase()]!;
        final icon = _icons[e.key.toLowerCase()]!;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${e.key[0].toUpperCase()}${e.key.substring(1)}',
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${pct.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 8,
                  backgroundColor: p.surfaceElevated,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
