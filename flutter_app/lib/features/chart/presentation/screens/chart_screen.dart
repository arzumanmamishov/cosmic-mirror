import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/widgets/cosmic_card.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_shimmer.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Your Natal Chart')),
      body: chartAsync.when(
        loading: () => const ShimmerList(itemCount: 4),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(chartProvider),
        ),
        data: (chart) {
          final planets =
              chart['planets'] as List<dynamic>? ?? [];
          final houses = chart['houses'] as List<dynamic>? ?? [];
          final aspects = chart['aspects'] as List<dynamic>? ?? [];
          final elements =
              chart['elements'] as Map<String, dynamic>? ?? {};

          return DefaultTabController(
            length: 4,
            child: Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Planets'),
                    Tab(text: 'Houses'),
                    Tab(text: 'Aspects'),
                    Tab(text: 'Elements'),
                  ],
                  indicatorColor: CosmicColors.primary,
                  labelColor: CosmicColors.primary,
                  unselectedLabelColor: CosmicColors.textSecondary,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _PlanetsTab(planets: planets),
                      _HousesTab(houses: houses),
                      _AspectsTab(aspects: aspects),
                      _ElementsTab(elements: elements),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlanetsTab extends StatelessWidget {
  const _PlanetsTab({required this.planets});

  final List<dynamic> planets;

  @override
  Widget build(BuildContext context) {
    if (planets.isEmpty) {
      return const Center(child: Text('No planet data available.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: planets.length,
      itemBuilder: (context, index) {
        final planet = planets[index] as Map<String, dynamic>;
        final name = planet['name'] as String? ?? '';
        final sign = planet['sign'] as String? ?? '';
        final house = planet['house'] as int?;
        final degree = planet['degree'] as num?;
        final retrograde = planet['retrograde'] as bool? ?? false;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CosmicCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: CosmicColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      _planetEmoji(name),
                      style: const TextStyle(fontSize: 22),
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
                          Text(name, style: CosmicTypography.titleMedium),
                          if (retrograde) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: CosmicColors.warning.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Rx',
                                style: CosmicTypography.caption.copyWith(
                                  color: CosmicColors.warning,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '$sign${house != null ? ' - House $house' : ''}'
                        '${degree != null ? ' (${degree.toStringAsFixed(1)}°)' : ''}',
                        style: CosmicTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _planetEmoji(String name) {
    final map = {
      'Sun': '\u2609', 'Moon': '\u263D', 'Mercury': '\u263F',
      'Venus': '\u2640', 'Mars': '\u2642', 'Jupiter': '\u2643',
      'Saturn': '\u2644', 'Uranus': '\u2645', 'Neptune': '\u2646',
      'Pluto': '\u2647',
    };
    return map[name] ?? '\u2605';
  }
}

class _HousesTab extends StatelessWidget {
  const _HousesTab({required this.houses});
  final List<dynamic> houses;

  @override
  Widget build(BuildContext context) {
    if (houses.isEmpty) {
      return const Center(child: Text('No house data available.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: houses.length,
      itemBuilder: (context, index) {
        final house = houses[index] as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CosmicCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('House ${house['number']}',
                    style: CosmicTypography.titleMedium),
                Text('${house['sign']} - ${house['description'] ?? ''}',
                    style: CosmicTypography.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AspectsTab extends StatelessWidget {
  const _AspectsTab({required this.aspects});
  final List<dynamic> aspects;

  @override
  Widget build(BuildContext context) {
    if (aspects.isEmpty) {
      return const Center(child: Text('No aspect data available.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: aspects.length,
      itemBuilder: (context, index) {
        final aspect = aspects[index] as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CosmicCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${aspect['planet1']} ${aspect['type']} ${aspect['planet2']}',
                    style: CosmicTypography.titleMedium,
                  ),
                ),
                Text('${aspect['orb']}°', style: CosmicTypography.bodySmall),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ElementsTab extends StatelessWidget {
  const _ElementsTab({required this.elements});
  final Map<String, dynamic> elements;

  @override
  Widget build(BuildContext context) {
    final entries = elements.entries.toList();
    if (entries.isEmpty) {
      return const Center(child: Text('No element data available.'));
    }

    final colors = {
      'Fire': Colors.red, 'Earth': Colors.green,
      'Air': Colors.lightBlue, 'Water': Colors.blue,
    };

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: entries.map((e) {
          final percentage = (e.value as num).toDouble();
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CosmicCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.key, style: CosmicTypography.titleMedium),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: CosmicColors.surfaceLight,
                    color: colors[e.key] ?? CosmicColors.primary,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 4),
                  Text('${percentage.toInt()}%',
                      style: CosmicTypography.bodySmall),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
