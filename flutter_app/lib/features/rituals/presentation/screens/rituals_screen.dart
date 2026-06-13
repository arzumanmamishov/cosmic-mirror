import 'package:cosmic_mirror/config/theme/colors.dart';
import 'package:cosmic_mirror/config/theme/typography.dart';
import 'package:cosmic_mirror/features/rituals/presentation/providers/rituals_provider.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_card.dart';
import 'package:cosmic_mirror/shared/widgets/premium_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RitualsScreen extends ConsumerWidget {
  const RitualsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final todayAsync = ref.watch(ritualsTodayProvider);
    final today = todayAsync.valueOrNull;

    bool done(String type) => today?.isCompleted(type) ?? false;
    void complete(String type) => completeRitual(ref, type);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.ritualsTitle),
      ),
      body: PremiumGate(
        featureName: 'Daily Rituals',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.ritualsTodayHeading,
                style: CosmicTypography.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                l.ritualsTodaySubtitle,
                style: CosmicTypography.bodySmall,
              ),
              const SizedBox(height: 24),
              _RitualCard(
                title: l.ritualMorningTitle,
                description: l.ritualMorningDesc,
                icon: Icons.wb_sunny_outlined,
                color: CosmicColors.gold,
                isCompleted: done('morning_intention'),
                onComplete: () => complete('morning_intention'),
              ),
              const SizedBox(height: 12),
              _RitualCard(
                title: l.ritualAffirmationTitle,
                description: l.ritualAffirmationDesc,
                icon: Icons.auto_awesome,
                color: CosmicColors.primary,
                isCompleted: done('affirmation'),
                onComplete: () => complete('affirmation'),
              ),
              const SizedBox(height: 12),
              _RitualCard(
                title: l.ritualEveningTitle,
                description: l.ritualEveningDesc,
                icon: Icons.nightlight_round,
                color: CosmicColors.accent,
                isCompleted: done('evening_reflection'),
                onComplete: () => complete('evening_reflection'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RitualCard extends StatelessWidget {
  const _RitualCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isCompleted,
    required this.onComplete,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isCompleted;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return CosmicCard(
      onTap: isCompleted ? null : onComplete,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isCompleted ? 0.05 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isCompleted ? Icons.check_circle : icon,
              color: isCompleted ? CosmicColors.success : color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: CosmicTypography.titleMedium.copyWith(
                    decoration:
                        isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(description, style: CosmicTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
