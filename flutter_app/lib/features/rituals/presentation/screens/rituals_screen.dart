import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../shared/widgets/cosmic_card.dart';
import '../../../../shared/widgets/premium_gate.dart';

class RitualsScreen extends ConsumerWidget {
  const RitualsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Rituals')),
      body: PremiumGate(
        featureName: 'Daily Rituals',
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your rituals for today',
                style: CosmicTypography.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Complete these to strengthen your cosmic connection.',
                style: CosmicTypography.bodySmall,
              ),
              const SizedBox(height: 24),
              _RitualCard(
                title: 'Morning Intention',
                description: 'Set your intention for the day ahead.',
                icon: Icons.wb_sunny_outlined,
                color: CosmicColors.gold,
                isCompleted: false,
                onComplete: () {},
              ),
              const SizedBox(height: 12),
              _RitualCard(
                title: 'Affirmation',
                description: 'Read and internalize today\'s affirmation.',
                icon: Icons.auto_awesome,
                color: CosmicColors.primary,
                isCompleted: false,
                onComplete: () {},
              ),
              const SizedBox(height: 12),
              _RitualCard(
                title: 'Evening Reflection',
                description:
                    'Reflect on your day and note what you\'re grateful for.',
                icon: Icons.nightlight_round,
                color: CosmicColors.accent,
                isCompleted: false,
                onComplete: () {},
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
              color: color.withOpacity(isCompleted ? 0.05 : 0.12),
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
