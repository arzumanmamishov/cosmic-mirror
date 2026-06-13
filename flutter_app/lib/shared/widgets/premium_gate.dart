import 'package:cosmic_mirror/config/theme/colors.dart';
import 'package:cosmic_mirror/config/theme/typography.dart';
import 'package:cosmic_mirror/shared/providers/subscription_state_provider.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PremiumGate extends ConsumerWidget {
  const PremiumGate({
    required this.child,
    super.key,
    this.featureName = 'this feature',
    this.previewChild,
    this.showInline = true,
  });

  final Widget child;
  final String featureName;
  final Widget? previewChild;
  final bool showInline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);

    if (isPremium) return child;

    if (previewChild != null) {
      return Column(
        children: [
          previewChild!,
          const SizedBox(height: 16),
          _UpgradePrompt(featureName: featureName),
        ],
      );
    }

    if (showInline) {
      return _UpgradePrompt(featureName: featureName);
    }

    return child;
  }
}

class _UpgradePrompt extends StatelessWidget {
  const _UpgradePrompt({required this.featureName});

  final String featureName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CosmicColors.primary.withValues(alpha: 0.15),
            CosmicColors.accent.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: CosmicColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.auto_awesome,
            color: CosmicColors.gold,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            'Unlock $featureName',
            style: CosmicTypography.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Upgrade to Premium for full access to personalized insights.',
            style: CosmicTypography.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          CosmicButton(
            label: 'View Plans',
            onPressed: () => context.push('/paywall'),
            fullWidth: false,
          ),
        ],
      ),
    );
  }
}
