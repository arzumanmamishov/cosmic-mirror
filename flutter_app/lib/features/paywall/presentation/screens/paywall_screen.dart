import 'package:cosmic_mirror/config/theme/colors.dart';
import 'package:cosmic_mirror/config/theme/typography.dart';
import 'package:cosmic_mirror/core/error/error_message.dart';
import 'package:cosmic_mirror/features/paywall/presentation/providers/subscription_provider.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/providers/subscription_state_provider.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

const _termsUrl = 'https://livelyapp.co/terms';
const _privacyUrl = 'https://livelyapp.co/privacy';
const _supportEmail = 'support@livelyapp.co';

/// "App Store" / "Google Play" — proper nouns, not localized.
String _storeName() =>
    defaultTargetPlatform == TargetPlatform.iOS ? 'App Store' : 'Google Play';

Future<void> _open(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Real premium (no dev override) so dev builds can still test buying.
    final hasPremium = ref.watch(hasPremiumProvider);

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
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  padding: const EdgeInsets.all(16),
                  icon: const Icon(
                    Icons.close,
                    color: CosmicColors.textSecondary,
                  ),
                  onPressed: () => _close(context),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: hasPremium
                      ? const _PremiumActiveView()
                      : const _OfferView(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _close(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/home');
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        Text(
          title,
          style: CosmicTypography.displayMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: CosmicTypography.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Benefits extends StatelessWidget {
  const _Benefits();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final benefits = <(String, String, IconData)>[
      (l.paywallBenefit1Title, l.paywallBenefit1Subtitle, Icons.auto_awesome),
      (
        l.paywallBenefit2Title,
        l.paywallBenefit2Subtitle,
        Icons.chat_bubble_outline,
      ),
      (
        l.paywallBenefit3Title,
        l.paywallBenefit3Subtitle,
        Icons.favorite_outline,
      ),
      (l.paywallBenefit4Title, l.paywallBenefit4Subtitle, Icons.timeline),
      (
        l.paywallBenefit5Title,
        l.paywallBenefit5Subtitle,
        Icons.calendar_month_outlined,
      ),
      (
        l.paywallBenefit6Title,
        l.paywallBenefit6Subtitle,
        Icons.self_improvement,
      ),
    ];
    return Column(
      children: [
        for (final (title, subtitle, icon) in benefits)
          Padding(
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
          ),
      ],
    );
  }
}

/// Plans, price disclosure and purchase / restore for a non-premium user.
class _OfferView extends ConsumerWidget {
  const _OfferView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final offering = ref.watch(paywallOfferingProvider);

    // Restore outcomes are shown as a snackbar; purchase problems inline.
    ref.listen<PaywallState>(paywallProvider, (prev, next) {
      final notice = next.notice;
      if (notice == null || notice == prev?.notice) return;
      final msg = switch (notice) {
        PaywallNotice.restored => l10n.subscriptionRestoreSuccess,
        PaywallNotice.nothingToRestore => l10n.subscriptionRestoreNothing,
        _ => null,
      };
      if (msg != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(msg)));
      }
    });

    return Column(
      children: [
        _Header(
          title: l10n.paywallHeadline,
          subtitle: l10n.paywallSubheadline,
        ),
        const SizedBox(height: 28),
        const _Benefits(),
        const SizedBox(height: 24),
        offering.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(color: CosmicColors.primary),
            ),
          ),
          error: (e, _) => _UnavailablePlans(
            onRetry: () => ref.invalidate(paywallOfferingProvider),
          ),
          data: (o) {
            if (o.unavailable) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  l10n.subscriptionPurchasesUnsupported,
                  style: CosmicTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
              );
            }
            if (o.plans.isEmpty) {
              return _UnavailablePlans(
                onRetry: () => ref.invalidate(paywallOfferingProvider),
              );
            }
            return _Plans(offering: o);
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _UnavailablePlans extends StatelessWidget {
  const _UnavailablePlans({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Text(
          l10n.subscriptionPlansUnavailableTitle,
          style: CosmicTypography.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.subscriptionPlansUnavailableBody,
          style: CosmicTypography.caption,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        CosmicButton(
          label: l10n.errRetry,
          gradient: false,
          onPressed: onRetry,
        ),
        const SizedBox(height: 12),
        const _LegalLinks(),
      ],
    );
  }
}

class _Plans extends ConsumerWidget {
  const _Plans({required this.offering});

  final PaywallOffering offering;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(paywallProvider);
    final notifier = ref.read(paywallProvider.notifier);
    final locale = Localizations.localeOf(context).toLanguageTag();

    final selected = offering.plans.firstWhere(
      (p) => p.product.identifier == state.selectedProductId,
      orElse: () => offering.defaultPlan!,
    );
    final savings = offering.annualSavings;
    final trialDays = selected.freeTrialDays;
    final pricePerPeriod = _pricePerPeriodLong(l10n, selected);

    final inlineMessage = switch (state.notice) {
      PaywallNotice.paymentPending => l10n.subscriptionPaymentPending,
      PaywallNotice.purchaseNotAllowed => l10n.subscriptionPurchaseNotAllowed,
      PaywallNotice.alreadyOwned => l10n.subscriptionAlreadyOwned,
      PaywallNotice.purchaseFailed => l10n.subscriptionPurchaseFailed,
      _ => state.errorObject != null
          ? FriendlyError.from(context, state.errorObject).body
          : null,
    };

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: CosmicColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              for (final plan in offering.plans)
                _PlanTab(
                  label: plan.isMonthly
                      ? l10n.paywallMonthly
                      : plan.isAnnual
                          ? l10n.paywallYearly
                          : plan.product.title,
                  price: plan.isMonthly
                      ? l10n.paywallPricePerMonth(plan.product.priceString)
                      : plan.isAnnual
                          ? l10n.paywallPricePerYear(plan.product.priceString)
                          : plan.product.priceString,
                  badge: plan.isAnnual && savings != null
                      ? l10n.paywallSavePercent(
                          NumberFormat.percentPattern(locale).format(savings),
                        )
                      : null,
                  isSelected: identical(plan, selected),
                  onTap: () => notifier.select(plan),
                ),
            ],
          ),
        ),
        if (trialDays != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: CosmicColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.paywallTrialThenPrice(trialDays, pricePerPeriod),
              style: CosmicTypography.caption.copyWith(
                color: CosmicColors.success,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        if (inlineMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            inlineMessage,
            style: CosmicTypography.caption.copyWith(color: CosmicColors.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        CosmicButton(
          label: trialDays != null
              ? l10n.paywallStartTrialCta(trialDays)
              : l10n.paywallSubscribe,
          isLoading: state.isPurchasing,
          onPressed: state.isBusy
              ? null
              : () async {
                  final success = await notifier.purchase(selected);
                  if (success && context.mounted) _close(context);
                },
        ),
        const SizedBox(height: 16),
        // Auto-renewal disclosure (App Store guideline 3.1.2 / Play policy).
        Text(
          trialDays != null
              ? l10n.subscriptionDisclosureTrial(
                  trialDays,
                  pricePerPeriod,
                  _storeName(),
                )
              : l10n.subscriptionDisclosure(pricePerPeriod, _storeName()),
          style: CosmicTypography.caption.copyWith(fontSize: 11),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        const _LegalLinks(showRestore: true),
      ],
    );
  }
}

/// "$39.99 per year" — the full price wording used in the disclosures.
String _pricePerPeriodLong(AppLocalizations l10n, PaywallPlan plan) {
  final price = plan.product.priceString;
  if (plan.isMonthly) return l10n.subscriptionPricePerMonthLong(price);
  if (plan.isAnnual) return l10n.subscriptionPricePerYearLong(price);
  return price;
}

/// Terms of Use (EULA) · Privacy Policy · Restore Purchases.
class _LegalLinks extends ConsumerWidget {
  const _LegalLinks({this.showRestore = false});

  final bool showRestore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(paywallProvider);
    final style = CosmicTypography.caption.copyWith(
      color: CosmicColors.textSecondary,
      decoration: TextDecoration.underline,
      decorationColor: CosmicColors.textSecondary,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(
          onPressed: () => _open(_termsUrl),
          child: Text(l10n.paywallTermsOfUse, style: style),
        ),
        TextButton(
          onPressed: () => _open(_privacyUrl),
          child: Text(l10n.authPrivacy, style: style),
        ),
        if (showRestore)
          TextButton(
            onPressed: state.isBusy
                ? null
                : () => ref.read(paywallProvider.notifier).restore(),
            child: state.isRestoring
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.paywallRestoreLong, style: style),
          ),
      ],
    );
  }
}

/// Shown instead of the offer when the user already has Premium, so a
/// subscriber can never buy a second subscription.
class _PremiumActiveView extends ConsumerWidget {
  const _PremiumActiveView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final info = ref.watch(customerInfoProvider);
    final entitlement = activePremiumEntitlement(info);
    final server = ref.watch(serverSubscriptionProvider).valueOrNull;
    final manageUri = storeSubscriptionManagementUri(info);

    String formatDate(DateTime d) => DateFormat.yMMMd(locale).format(d.toLocal());

    final details = <String>[];
    if (entitlement != null) {
      final expires = entitlement.expirationDate == null
          ? null
          : DateTime.tryParse(entitlement.expirationDate!);
      if (expires != null) {
        if (entitlement.periodType == PeriodType.trial) {
          details.add(l10n.subscriptionTrialEndsOn(formatDate(expires)));
        } else if (entitlement.willRenew) {
          details.add(l10n.subscriptionRenewsOn(formatDate(expires)));
        } else {
          details.add(l10n.subscriptionActiveUntil(formatDate(expires)));
        }
      }
      if (entitlement.billingIssueDetectedAt != null) {
        details.add(l10n.subscriptionBillingIssue);
      }
    } else if (server != null && server.isWebSubscription) {
      if (server.expiresAt != null) {
        details.add(
          server.willRenew
              ? l10n.subscriptionRenewsOn(formatDate(server.expiresAt!))
              : l10n.subscriptionActiveUntil(formatDate(server.expiresAt!)),
        );
      }
      details.add(l10n.subscriptionManagedOnWeb);
    } else if (server?.expiresAt != null) {
      details.add(l10n.subscriptionActiveUntil(formatDate(server!.expiresAt!)));
    }

    return Column(
      children: [
        const SizedBox(height: 24),
        _Header(
          title: l10n.subscriptionPremiumActiveTitle,
          subtitle: l10n.subscriptionPremiumActiveBody,
        ),
        const SizedBox(height: 20),
        for (final line in details)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              line,
              style: CosmicTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 20),
        if (manageUri != null)
          CosmicButton(
            label: l10n.subscriptionManage,
            onPressed: () =>
                launchUrl(manageUri, mode: LaunchMode.externalApplication),
          )
        else if (server != null && server.isWebSubscription)
          CosmicButton(
            label: l10n.subscriptionContactSupport,
            gradient: false,
            onPressed: () => launchUrl(Uri.parse('mailto:$_supportEmail')),
          ),
        const SizedBox(height: 12),
        const _LegalLinks(),
        const SizedBox(height: 32),
      ],
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
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
              Text(
                label,
                style: CosmicTypography.labelLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                price,
                style: CosmicTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
