import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/theme/colors.dart';
import '../../../../config/theme/typography.dart';
import '../../../../shared/providers/user_provider.dart';
import '../../../../shared/widgets/cosmic_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: CosmicColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (user.name ?? 'U')[0].toUpperCase(),
                  style: CosmicTypography.displayMedium,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(user.name ?? 'Stargazer', style: CosmicTypography.headlineMedium),
            Text(user.email ?? '', style: CosmicTypography.bodySmall),
            const SizedBox(height: 32),

            // Signs
            if (user.sunSign != null) ...[
              CosmicCard(
                child: Column(
                  children: [
                    _SignRow(label: 'Sun', sign: user.sunSign!,
                        color: CosmicColors.gold),
                    const Divider(height: 24),
                    _SignRow(label: 'Moon', sign: user.moonSign ?? 'Unknown',
                        color: CosmicColors.primaryLight),
                    const Divider(height: 24),
                    _SignRow(label: 'Rising', sign: user.risingSign ?? 'Unknown',
                        color: CosmicColors.accent),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Edit birth data
            CosmicCard(
              onTap: () {
                // Navigate to edit birth data
              },
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, color: CosmicColors.textSecondary),
                  const SizedBox(width: 12),
                  Text('Edit Birth Data', style: CosmicTypography.titleMedium),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: CosmicColors.textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignRow extends StatelessWidget {
  const _SignRow({required this.label, required this.sign, required this.color});

  final String label;
  final String sign;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Text(label, style: CosmicTypography.bodySmall),
        const Spacer(),
        Text(sign, style: CosmicTypography.titleMedium),
      ],
    );
  }
}
