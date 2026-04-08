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

final yearlyForecastProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final client = ref.read(apiClientProvider);
  return client.get<Map<String, dynamic>>(ApiEndpoints.yearlyForecast);
});

class YearlyForecastScreen extends ConsumerWidget {
  const YearlyForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastAsync = ref.watch(yearlyForecastProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Yearly Forecast')),
      body: PremiumGate(
        featureName: 'Yearly Forecast',
        child: forecastAsync.when(
          loading: () => const ShimmerList(itemCount: 5),
          error: (e, _) => ErrorView(
            message: e.toString(),
            onRetry: () => ref.invalidate(yearlyForecastProvider),
          ),
          data: (data) {
            final theme = data['theme'] as String? ?? '';
            final overview = data['overview'] as String? ?? '';
            final quarters =
                data['quarters'] as List<dynamic>? ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CosmicCard(
                    showGradientBorder: true,
                    child: Column(
                      children: [
                        Text(
                          'YOUR YEAR THEME',
                          style: CosmicTypography.overline.copyWith(
                            color: CosmicColors.gold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          theme,
                          style: CosmicTypography.displaySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          overview,
                          style: CosmicTypography.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('Quarter Breakdown',
                      style: CosmicTypography.headlineSmall),
                  const SizedBox(height: 16),
                  ...quarters.map((q) {
                    final quarter = q as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CosmicCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quarter['label'] as String? ?? '',
                              style: CosmicTypography.titleLarge.copyWith(
                                color: CosmicColors.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              quarter['description'] as String? ?? '',
                              style: CosmicTypography.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
