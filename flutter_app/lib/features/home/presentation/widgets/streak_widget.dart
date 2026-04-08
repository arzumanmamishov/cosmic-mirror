import 'package:flutter/material.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../shared/widgets/cosmic_card.dart';

class StreakWidget extends StatelessWidget {
  const StreakWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // In production, streak count comes from ritual/journal provider
    const streakDays = 7;
    final today = DateTime.now().weekday;

    return CosmicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: CosmicColors.gold, size: 22),
              const SizedBox(width: 8),
              Text(
                '$streakDays Day Streak',
                style: CosmicTypography.titleLarge,
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: CosmicColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Keep it up!',
                  style: CosmicTypography.caption.copyWith(
                    color: CosmicColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final dayNum = index + 1;
              final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              final isCompleted = dayNum < today;
              final isToday = dayNum == today;

              return Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? CosmicColors.primary
                          : isToday
                              ? CosmicColors.primary.withOpacity(0.2)
                              : CosmicColors.surfaceLight,
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(color: CosmicColors.primary, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? const Icon(Icons.check,
                              size: 16, color: Colors.white)
                          : Text(
                              dayLabels[index],
                              style: CosmicTypography.caption.copyWith(
                                color: isToday
                                    ? CosmicColors.primary
                                    : CosmicColors.textTertiary,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
