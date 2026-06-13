import 'package:cosmic_mirror/config/theme/colors.dart';
import 'package:cosmic_mirror/config/theme/typography.dart';
import 'package:cosmic_mirror/features/paywall/presentation/providers/subscription_provider.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  static List<(String, String, IconData)> _benefits(AppLocalizations l) => [
        (l.paywallBenefit1Title, l.paywallBenefit1Subtitle, Icons.auto_awesome),
        (l.paywallBenefit2Title, l.paywallBenefit2Subtitle, Icons.chat_bubble_outline),
        (l.paywallBenefit3Title, l.paywallBenefit3Subtitle, Icons.favorite_outline),
        (l.paywallBenefit4Title, l.paywallBenefit4Subtitle, Icons.timeline),
        (l.paywallBenefit5Title, l.paywallBenefit5Subtitle, Icons.calendar_month_outlined),
        (l.paywallBenefit6Title, l.paywallBenefit6Subtitle, Icons.self_improvement),
      ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(paywallProvider);
    final notifier = ref.read(paywallProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final benefits = _benefits(l10n);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1040), Color(0xFF0A0E27)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () => context.go('/home'),
                    child: const Icon(
                      Icons.close,
                      color: CosmicColors.textSecondary,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Premium badge
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: CosmicColors.premiumGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: CosmicColors.primary.withValues(alpha: 0.4),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.auto_awesome, size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 20),
                      Text(l10n.paywallHeadline,
                          style: CosmicTypography.displayMedium,
                          textAlign: TextAlign.center,),
                      const SizedBox(height: 8),
                      Text(
                        l10n.paywallSubheadline,
                        style: CosmicTypography.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // Benefits
                      ...List.generate(benefits.length, (i) {
                        final (title, subtitle, icon) = benefits[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: CosmicColors.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, color: CosmicColors.primaryLight, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: CosmicTypography.titleMedium),
                                    Text(subtitle, style: CosmicTypography.caption),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 24),

                      // Plan toggle
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: CosmicColors.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _PlanTab(
                              label: l10n.paywallMonthly,
                              // Real price comes from the Stripe Price ID
                              // shown in the Payment Sheet — this string
                              // is just a hint above the toggle.
                              price: r'$6.99/mo',
                              isSelected: !state.isYearly,
                              onTap: () {
                                if (state.isYearly) notifier.togglePlan();
                              },
                            ),
                            _PlanTab(
                              label: l10n.paywallYearly,
                              price: r'$39.99/yr',
                              badge: l10n.paywallSaveBadge,
                              isSelected: state.isYearly,
                              onTap: () {
                                if (!state.isYearly) notifier.togglePlan();
                              },
                            ),
                          ],
                        ),
                      ),

                      if (state.isYearly) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: CosmicColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.paywallTrialIncluded,
                            style: CosmicTypography.caption.copyWith(
                              color: CosmicColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],

                      if (state.error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          state.error!,
                          style: CosmicTypography.caption.copyWith(
                            color: CosmicColors.error,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],

                      const SizedBox(height: 24),

                      CosmicButton(
                        label: state.isYearly
                            ? l10n.paywallStartFreeTrial
                            : l10n.paywallSubscribe,
                        isLoading: state.isPurchasing,
                        onPressed: () async {
                          final success = await notifier.purchase();
                          if (success && context.mounted) {
                            context.go('/home');
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () async {
                          final restored = await notifier.restore();
                          if (restored && context.mounted) {
                            context.go('/home');
                          }
                        },
                        child: Text(
                          l10n.paywallRestoreLong,
                          style: CosmicTypography.bodySmall.copyWith(
                            color: CosmicColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.paywallCancelNote,
                        style: CosmicTypography.caption,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanTab extends StatelessWidget {
  const _PlanTab({
    required this.label,
    required this.price,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  final String label;
  final String price;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? CosmicColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              if (badge != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: CosmicColors.gold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(label, style: CosmicTypography.labelLarge),
              const SizedBox(height: 2),
              Text(price, style: CosmicTypography.caption),
            ],
          ),
        ),
      ),
    );
  }
}
