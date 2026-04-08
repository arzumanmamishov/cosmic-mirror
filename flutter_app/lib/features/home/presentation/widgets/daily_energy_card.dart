import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../shared/widgets/cosmic_card.dart';

class DailyEnergyCard extends ConsumerWidget {
  const DailyEnergyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In production, this reads from dailyReadingProvider
    return CosmicCard(
      glassmorphism: true,
      onTap: () => context.push('/daily-reading'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CosmicColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "TODAY'S ENERGY",
                  style: CosmicTypography.overline.copyWith(
                    color: CosmicColors.gold,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right,
                color: CosmicColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'A day for inner reflection and creative expression',
            style: CosmicTypography.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'The Moon in Pisces heightens your intuition. Trust your instincts today, especially in conversations that matter.',
            style: CosmicTypography.bodySmall,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          // Energy level indicator
          Row(
            children: [
              _EnergyDot(filled: true, color: CosmicColors.success),
              _EnergyDot(filled: true, color: CosmicColors.success),
              _EnergyDot(filled: true, color: CosmicColors.gold),
              _EnergyDot(filled: true, color: CosmicColors.gold),
              _EnergyDot(filled: false, color: CosmicColors.textTertiary),
              const SizedBox(width: 8),
              Text(
                'Moderate Energy',
                style: CosmicTypography.caption.copyWith(
                  color: CosmicColors.gold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EnergyDot extends StatelessWidget {
  const _EnergyDot({required this.filled, required this.color});

  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: filled ? color : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: filled ? color : CosmicColors.textTertiary,
          width: 1.5,
        ),
      ),
    );
  }
}
