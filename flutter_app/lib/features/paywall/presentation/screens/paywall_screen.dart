import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/config/theme/lively_type.dart';
import 'package:cosmic_mirror/core/error/error_message.dart';
import 'package:cosmic_mirror/features/paywall/presentation/providers/subscription_provider.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/providers/subscription_state_provider.dart';
import 'package:cosmic_mirror/shared/widgets/lively/gold_button.dart';
import 'package:cosmic_mirror/shared/widgets/lively/lively_backdrop.dart';
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

/// Opens [uri] externally; tells the user when nothing could handle it
/// (e.g. no browser / mail app) instead of failing silently.
Future<void> _open(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final failMsg = AppLocalizations.of(context).oaphCouldNotOpenLink;
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok) {
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(failMsg)));
  }
}

class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Real premium (no dev override) so dev builds can still test buying.
    final hasPremium = ref.watch(hasPremiumProvider);
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      // Theme-aware Lively backdrop (was a hard-coded purple gradient that
      // ignored the light theme and the design system).
      body: LivelyBackdrop(
        seed: 23,
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  padding: const EdgeInsets.all(16),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: Icon(Icons.close, color: p.textSecondary),
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
    final p = context.palette;
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: p.premiumGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: p.primary.withValues(alpha: 0.4),
                blurRadius: 24,
              ),
            ],
          ),
          child: Icon(Icons.auto_awesome, size: 40, color: p.onPrimary),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: LivelyType.d3(p.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: LivelyType.small(p.textMuted),
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
    final p = context.palette;
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
                    color: p.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: p.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: LivelyType.h2(p.textPrimary)),
                      Text(subtitle, style: LivelyType.small(p.textMuted)),
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
    final p = context.palette;
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
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: CircularProgressIndicator(color: p.primary),
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
                  style: LivelyType.small(p.textMuted),
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
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Text(
          l10n.subscriptionPlansUnavailableTitle,
          style: LivelyType.h2(p.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.subscriptionPlansUnavailableBody,
          style: LivelyType.small(p.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        GoldButton(
          label: l10n.errRetry,
          ghost: true,
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
    final p = context.palette;
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
            color: p.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.line),
          ),
          // Equal-height tabs even when only one carries the badge.
          child: IntrinsicHeight(
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
        ),
        if (trialDays != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: p.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              l10n.paywallTrialThenPrice(trialDays, pricePerPeriod),
              style: LivelyType.small(p.success).copyWith(
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
            style: LivelyType.small(p.error),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        GoldButton(
          label: trialDays != null
              ? l10n.paywallStartTrialCta(trialDays)
              : l10n.paywallSubscribe,
          loading: state.isPurchasing,
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
          style: LivelyType.small(p.textMuted).copyWith(fontSize: 11),
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
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(paywallProvider);
    final style = LivelyType.small(p.textSecondary).copyWith(
      fontSize: 12,
      decoration: TextDecoration.underline,
      decorationColor: p.textSecondary,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        TextButton(
          onPressed: () => _open(context, Uri.parse(_termsUrl)),
          child: Text(l10n.paywallTermsOfUse, style: style),
        ),
        TextButton(
          onPressed: () => _open(context, Uri.parse(_privacyUrl)),
          child: Text(l10n.authPrivacy, style: style),
        ),
        if (showRestore)
          TextButton(
            onPressed: state.isBusy
                ? null
                : () => ref.read(paywallProvider.notifier).restore(),
            child: state.isRestoring
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: p.primary,
                    ),
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
    final p = context.palette;
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
              style: LivelyType.small(p.textMuted),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 20),
        if (manageUri != null)
          GoldButton(
            label: l10n.subscriptionManage,
            onPressed: () => _open(context, manageUri),
          )
        else if (server != null && server.isWebSubscription)
          GoldButton(
            label: l10n.subscriptionContactSupport,
            ghost: true,
            onPressed: () =>
                _open(context, Uri.parse('mailto:$_supportEmail')),
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
    final p = context.palette;
    // Text on the selected (gold) tab uses onPrimary — the light text
    // colors were unreadable on gold.
    final fg = isSelected ? p.onPrimary : p.textPrimary;
    final fgMuted = isSelected ? p.onPrimary : p.textMuted;
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? p.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (badge != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? p.onPrimary : p.gold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? p.primary : p.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                label,
                style: LivelyType.button(fg, size: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                price,
                style: LivelyType.small(fgMuted).copyWith(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
