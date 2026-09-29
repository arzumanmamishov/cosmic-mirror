import 'package:cosmic_mirror/config/theme/colors.dart';
import 'package:cosmic_mirror/config/theme/typography.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DailyEnergyCard extends ConsumerWidget {
  const DailyEnergyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // In production, this reads from dailyReadingProvider
    final l = AppLocalizations.of(context);
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
                  color: CosmicColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l.homeTodaysEnergyLabel,
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
            l.homeDailyEnergyHeadline,
            style: CosmicTypography.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            l.homeDailyEnergyBody,
            style: CosmicTypography.bodySmall,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          // Energy level indicator
          Row(
            children: [
              const _EnergyDot(filled: true, color: CosmicColors.success),
              const _EnergyDot(filled: true, color: CosmicColors.success),
              const _EnergyDot(filled: true, color: CosmicColors.gold),
              const _EnergyDot(filled: true, color: CosmicColors.gold),
              const _EnergyDot(filled: false, color: CosmicColors.textTertiary),
              const SizedBox(width: 8),
              Text(
                l.homeModerateEnergy,
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
