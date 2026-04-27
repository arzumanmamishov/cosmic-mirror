import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../shared/widgets/cosmic_card.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../../../shared/widgets/loading_shimmer.dart';
import '../../../../shared/widgets/premium_gate.dart';
import '../providers/daily_reading_provider.dart';

class DailyReadingScreen extends ConsumerWidget {
  const DailyReadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final readingAsync = ref.watch(dailyReadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Reading'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              final reading = readingAsync.valueOrNull;
              if (reading != null) {
                Share.share(
                  '"${reading.affirmation}"\n\nMy lucky color today: '
                  '${reading.luckyColor}\n\n~ Lively',
                );
              }
            },
          ),
        ],
      ),
      body: readingAsync.when(
        loading: () => const ShimmerList(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(dailyReadingProvider),
        ),
        data: (reading) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Energy level
              CosmicCard(
                glassmorphism: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ENERGY LEVEL',
                      style: CosmicTypography.overline.copyWith(
                        color: CosmicColors.gold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: List.generate(10, (i) {
                        final filled = i < reading.energyLevel;
                        return Expanded(
                          child: Container(
                            height: 6,
                            margin: const EdgeInsets.only(right: 3),
                            decoration: BoxDecoration(
                              color: filled
                                  ? _energyColor(reading.energyLevel)
                                  : CosmicColors.surfaceLight,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${reading.energyLevel}/10 - ${_energyLabel(reading.energyLevel)}',
                      style: CosmicTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Emotional overview (free)
              _ReadingSection(
                title: 'Emotional Overview',
                icon: Icons.psychology_outlined,
                iconColor: CosmicColors.primaryLight,
                content: reading.emotional,
              ),
              const SizedBox(height: 16),

              // Love (premium)
              PremiumGate(
                featureName: 'Love Guidance',
                child: _ReadingSection(
                  title: 'Love & Relationships',
                  icon: Icons.favorite_outline,
                  iconColor: CosmicColors.accent,
                  content: reading.love,
                ),
              ),
              const SizedBox(height: 16),

              // Career (premium)
              PremiumGate(
                featureName: 'Career Insights',
                child: _ReadingSection(
                  title: 'Career & Purpose',
                  icon: Icons.work_outline,
                  iconColor: CosmicColors.gold,
                  content: reading.career,
                ),
              ),
              const SizedBox(height: 16),

              // Health
              PremiumGate(
                featureName: 'Health Guidance',
                child: _ReadingSection(
                  title: 'Health & Wellness',
                  icon: Icons.spa_outlined,
                  iconColor: CosmicColors.success,
                  content: reading.health,
                ),
              ),
              const SizedBox(height: 16),

              // Caution
              _ReadingSection(
                title: 'Caution',
                icon: Icons.warning_amber_outlined,
                iconColor: CosmicColors.warning,
                content: reading.caution,
              ),
              const SizedBox(height: 16),

              // Action steps
              _ReadingSection(
                title: 'Action Steps',
                icon: Icons.rocket_launch_outlined,
                iconColor: CosmicColors.primary,
                content: reading.action,
              ),
              const SizedBox(height: 24),

              // Affirmation
              CosmicCard(
                showGradientBorder: true,
                child: Column(
                  children: [
                    Text(
                      'AFFIRMATION',
                      style: CosmicTypography.overline.copyWith(
                        color: CosmicColors.gold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      reading.affirmation,
                      style: CosmicTypography.affirmation,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lucky color & number
              Row(
                children: [
                  Expanded(
                    child: CosmicCard(
                      child: Column(
                        children: [
                          Text('LUCKY COLOR', style: CosmicTypography.overline),
                          const SizedBox(height: 8),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _parseColor(reading.luckyColor),
                              shape: BoxShape.circle,
                              border: Border.all(color: CosmicColors.glassBorder),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            reading.luckyColor,
                            style: CosmicTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CosmicCard(
                      child: Column(
                        children: [
                          Text('LUCKY NUMBER', style: CosmicTypography.overline),
                          const SizedBox(height: 8),
                          Text(
                            '${reading.luckyNumber}',
                            style: CosmicTypography.displayMedium.copyWith(
                              color: CosmicColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Color _energyColor(int level) {
    if (level <= 3) return CosmicColors.error;
    if (level <= 6) return CosmicColors.gold;
    return CosmicColors.success;
  }

  String _energyLabel(int level) {
    if (level <= 3) return 'Low Energy';
    if (level <= 6) return 'Moderate Energy';
    return 'High Energy';
  }

  Color _parseColor(String colorName) {
    final colorMap = {
      'red': Colors.red,
      'blue': Colors.blue,
      'green': Colors.green,
      'purple': Colors.purple,
      'gold': const Color(0xFFF4C542),
      'pink': Colors.pink,
      'orange': Colors.orange,
      'white': Colors.white,
      'silver': Colors.grey.shade300,
      'teal': Colors.teal,
      'indigo': Colors.indigo,
      'lavender': const Color(0xFFE6E6FA),
    };
    return colorMap[colorName.toLowerCase()] ?? CosmicColors.primary;
  }
}

class _ReadingSection extends StatelessWidget {
  const _ReadingSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.content,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final String content;

  @override
  Widget build(BuildContext context) {
    return CosmicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
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
