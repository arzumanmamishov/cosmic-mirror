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
import '../../../../shared/widgets/premium_gate.dart';

final timelineProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, type) async {
  final client = ref.read(apiClientProvider);
  return client.get<Map<String, dynamic>>(
    ApiEndpoints.timeline,
    queryParameters: {'type': type},
  );
});

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _types = ['30d', '3m', '12m'];
  static const _labels = ['30 Days', '3 Months', '12 Months'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Life Timeline'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _labels.map((l) => Tab(text: l)).toList(),
          indicatorColor: CosmicColors.primary,
          labelColor: CosmicColors.primary,
          unselectedLabelColor: CosmicColors.textSecondary,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _types.map((type) {
          return PremiumGate(
            featureName: 'Timeline Forecasts',
            child: _TimelineTab(type: type),
          );
        }).toList(),
      ),
    );
  }
}

class _TimelineTab extends ConsumerWidget {
  const _TimelineTab({required this.type});

  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(timelineProvider(type));

    return dataAsync.when(
      loading: () => const ShimmerList(),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () => ref.invalidate(timelineProvider(type)),
      ),
      data: (data) {
        final periods = data['periods'] as List<dynamic>? ?? [];

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: periods.length,
          itemBuilder: (context, index) {
            final period = periods[index] as Map<String, dynamic>;
            final title = period['title'] as String? ?? '';
            final description = period['description'] as String? ?? '';
            final dateRange = period['date_range'] as String? ?? '';
            final energy = period['energy'] as String? ?? 'neutral';

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _energyColor(energy),
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (index < periods.length - 1)
                        Container(
                          width: 2,
                          height: 100,
                          color: CosmicColors.surfaceLight,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: CosmicCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(dateRange, style: CosmicTypography.caption),
                          const SizedBox(height: 4),
                          Text(title, style: CosmicTypography.titleMedium),
                          const SizedBox(height: 8),
                          Text(description, style: CosmicTypography.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _energyColor(String energy) {
    switch (energy) {
      case 'positive':
        return CosmicColors.success;
      case 'challenging':
        return CosmicColors.warning;
      case 'intense':
        return CosmicColors.error;
      default:
        return CosmicColors.primary;
    }
  }
}
