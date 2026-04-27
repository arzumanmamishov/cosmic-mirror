import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/widgets/cosmic_card.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/premium_gate.dart';

final compatibilityReportProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, personId) async {
  final client = ref.read(apiClientProvider);
  return client.get<Map<String, dynamic>>(
    ApiEndpoints.compatibility(personId),
  );
});

class CompatibilityReportScreen extends ConsumerWidget {
  const CompatibilityReportScreen({required this.personId, super.key});

  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(compatibilityReportProvider(personId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compatibility'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              final report = reportAsync.valueOrNull;
              if (report != null) {
                final name = report['person_name'] as String? ?? 'Someone';
                final score = report['overall_score'] as int? ?? 0;
                Share.share(
                  'My cosmic compatibility with $name is $score%! '
                  'Check yours on Lively.',
                );
              }
            },
          ),
        ],
      ),
      body: reportAsync.when(
        loading: () => const ShimmerList(itemCount: 4),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(compatibilityReportProvider(personId)),
        ),
        data: (report) {
          final name = report['person_name'] as String? ?? '';
          final emotional = report['emotional_score'] as int? ?? 0;
          final communication = report['communication_score'] as int? ?? 0;
          final chemistry = report['chemistry_score'] as int? ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Text(
                  'You & $name',
                  style: CosmicTypography.displaySmall,
                ),
                const SizedBox(height: 24),

                // Score cards
                Row(
                  children: [
                    _ScoreCard(
                      label: 'Emotional',
                      score: emotional,
                      color: CosmicColors.accent,
                    ),
                    const SizedBox(width: 12),
                    _ScoreCard(
                      label: 'Communication',
                      score: communication,
                      color: CosmicColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _ScoreCard(
                      label: 'Chemistry',
                      score: chemistry,
                      color: CosmicColors.gold,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Detailed sections (premium gated)
                PremiumGate(
                  featureName: 'Full Compatibility Report',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (report['conflict_patterns'] != null) ...[
                        _ReportSection(
                          title: 'Conflict Patterns',
                          icon: Icons.warning_amber_outlined,
                          content: report['conflict_patterns'] as String,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (report['advice'] != null)
                        _ReportSection(
                          title: 'Advice',
                          icon: Icons.lightbulb_outline,
                          content: report['advice'] as String,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({
    required this.label,
    required this.score,
    required this.color,
  });

  final String label;
  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CosmicCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: score / 100,
                    backgroundColor: CosmicColors.surfaceLight,
                    color: color,
                    strokeWidth: 4,
                  ),
                  Center(
                    child: Text(
                      '$score',
                      style: CosmicTypography.headlineMedium.copyWith(
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: CosmicTypography.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.title,
    required this.icon,
    required this.content,
  });

  final String title;
  final IconData icon;
  final String content;

  @override
  Widget build(BuildContext context) {
    return CosmicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: CosmicColors.primaryLight, size: 20),
              const SizedBox(width: 8),
              Text(title, style: CosmicTypography.titleLarge),
            ],
          ),
          const SizedBox(height: 12),
          Text(content, style: CosmicTypography.bodyMedium),
        ],
      ),
    );
  }
}
