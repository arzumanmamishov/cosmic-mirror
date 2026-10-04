import 'dart:async';

import 'package:cosmic_mirror/core/error/exceptions.dart';
import 'package:cosmic_mirror/shared/providers/subscription_state_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Paywall data + actions. Premium is bought through App Store / Google
/// Play in-app purchases via RevenueCat:
///   1. [paywallOfferingProvider] loads the current RevenueCat offering
///      (monthly + annual packages, localized store prices) and whether
///      the user is eligible for the annual plan's free trial.
///   2. [PaywallNotifier.purchase] runs `Purchases.purchasePackage`. The
///      returned CustomerInfo unlocks Premium immediately; the RevenueCat
///      webhook then updates the server, which we poll briefly.
///   3. [PaywallNotifier.restore] runs `Purchases.restorePurchases`.

/// One purchasable plan on the paywall.
class PaywallPlan {
  const PaywallPlan({required this.package, this.freeTrialDays});

  final Package package;

  /// Length of the free-trial introductory offer, when the product has one
  /// AND this user is eligible for it. Null = no trial to promise.
  final int? freeTrialDays;

  StoreProduct get product => package.storeProduct;
  bool get isAnnual => package.packageType == PackageType.annual;
  bool get isMonthly => package.packageType == PackageType.monthly;
  bool get hasFreeTrial => freeTrialDays != null && freeTrialDays! > 0;
}

/// What the paywall can sell right now.
class PaywallOffering {
  const PaywallOffering({required this.plans, this.unavailable = false});

  /// In-app purchases aren't available in this build (web, or no
  /// RevenueCat key compiled in).
  const PaywallOffering.unavailable()
      : plans = const [],
        unavailable = true;

  /// Monthly first, then annual, then anything else in the offering.
  final List<PaywallPlan> plans;
  final bool unavailable;

  PaywallPlan? get annual => plans.where((p) => p.isAnnual).firstOrNull;
  PaywallPlan? get monthly => plans.where((p) => p.isMonthly).firstOrNull;

  /// Default selection: the annual plan (it carries the trial).
  PaywallPlan? get defaultPlan => annual ?? plans.firstOrNull;

  /// Annual savings vs. paying monthly for a year, as a fraction (0.52 =
  /// 52%). Null unless both plans exist and the saving is meaningful.
  double? get annualSavings {
    final a = annual?.product.price;
    final m = monthly?.product.price;
    if (a == null || m == null || m <= 0) return null;
    final saving = 1 - a / (m * 12);
    return saving >= 0.05 ? saving : null;
  }
}

final paywallOfferingProvider =
    FutureProvider.autoDispose<PaywallOffering>((ref) async {
  if (!RevenueCatRuntime.configured) return const PaywallOffering.unavailable();

  final offerings = await Purchases.getOfferings();
  final offering = offerings.current;
  if (offering == null) return const PaywallOffering(plans: []);

  final packages = <Package>[
    if (offering.monthly != null) offering.monthly!,
    if (offering.annual != null) offering.annual!,
  ];
  if (packages.isEmpty) packages.addAll(offering.availablePackages);

  final eligible = await _trialEligibleProducts(packages);
  return PaywallOffering(
    plans: [
      for (final p in packages)
        PaywallPlan(
          package: p,
          freeTrialDays: eligible.contains(p.storeProduct.identifier)
              ? freeTrialDays(p.storeProduct)
              : null,
        ),
    ],
  );
});

/// Days of free trial in [product]'s introductory offer, or null when it
/// has none (or the intro offer is a discounted price, not free).
int? freeTrialDays(StoreProduct product) {
  final intro = product.introductoryPrice;
  if (intro == null || intro.price > 0) return null;
  final units = intro.periodNumberOfUnits * (intro.cycles > 0 ? intro.cycles : 1);
  final days = switch (intro.periodUnit) {
    PeriodUnit.day => units,
    PeriodUnit.week => units * 7,
    PeriodUnit.month => units * 30,
    PeriodUnit.year => units * 365,
    PeriodUnit.unknown => 0,
  };
  return days > 0 ? days : null;
}

/// Product ids whose free trial this user may be promised. Apple: only
/// when RevenueCat confirms eligibility (a user who already had the trial
/// or a subscription in the group is ineligible). Google Play only returns
/// offers the user is eligible for, and RevenueCat reports "unknown"
/// there, so an existing free intro offer counts unless explicitly
/// ineligible.
Future<Set<String>> _trialEligibleProducts(List<Package> packages) async {
  final withTrial = [
    for (final p in packages)
      if (freeTrialDays(p.storeProduct) != null) p.storeProduct.identifier,
  ];
  if (withTrial.isEmpty) return const {};
  final isAndroid = defaultTargetPlatform == TargetPlatform.android;
  try {
    final result =
        await Purchases.checkTrialOrIntroductoryPriceEligibility(withTrial);
    return {
      for (final id in withTrial)
        if (_eligible(result[id]?.status, isAndroid: isAndroid)) id,
    };
  } catch (e) {
    debugPrint('Trial eligibility check failed: $e');
    // Never promise a trial we can't confirm on iOS.
    return isAndroid ? withTrial.toSet() : const {};
  }
}

bool _eligible(IntroEligibilityStatus? status, {required bool isAndroid}) {
  return switch (status) {
    IntroEligibilityStatus.introEligibilityStatusEligible => true,
    IntroEligibilityStatus.introEligibilityStatusIneligible ||
    IntroEligibilityStatus.introEligibilityStatusNoIntroOfferExists =>
      false,
    IntroEligibilityStatus.introEligibilityStatusUnknown || null => isAndroid,
  };
}

/// User-facing outcome the paywall shows as a localized message.
enum PaywallNotice {
  /// Restore found no active Premium purchase for this store account.
  nothingToRestore,

  /// Restore re-activated Premium.
  restored,

  /// The store is waiting on payment (e.g. Ask to Buy, pending card).
  paymentPending,

  /// Purchases are disabled on this device (parental controls, etc.).
  purchaseNotAllowed,

  /// The subscription is already owned by this store account.
  alreadyOwned,

  /// Any other store failure.
  purchaseFailed,
}

class PaywallState {
  const PaywallState({
    this.selectedProductId,
    this.isPurchasing = false,
    this.isRestoring = false,
    this.notice,
    this.errorObject,
  });

  /// Store product id of the selected plan; null = the offering default.
  final String? selectedProductId;
  final bool isPurchasing;
  final bool isRestoring;
  final PaywallNotice? notice;

  /// Raw failure (e.g. offline); the UI maps it through `FriendlyError`.
  final Object? errorObject;

  bool get isBusy => isPurchasing || isRestoring;

  PaywallState copyWith({
    String? selectedProductId,
    bool? isPurchasing,
    bool? isRestoring,
    PaywallNotice? notice,
    Object? errorObject,
  }) {
    return PaywallState(
      selectedProductId: selectedProductId ?? this.selectedProductId,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      isRestoring: isRestoring ?? this.isRestoring,
      // Messages are one-shot: cleared unless explicitly set.
      notice: notice,
      errorObject: errorObject,
    );
  }
}

final paywallProvider =
    StateNotifierProvider.autoDispose<PaywallNotifier, PaywallState>((ref) {
  return PaywallNotifier(ref);
});

class PaywallNotifier extends StateNotifier<PaywallState> {
  PaywallNotifier(this._ref) : super(const PaywallState());

  final Ref _ref;

  void select(PaywallPlan plan) {
    if (state.isBusy) return;
    state = state.copyWith(selectedProductId: plan.product.identifier);
  }

  /// Buys [plan] through the store. Returns true when Premium is active
  /// afterwards. A user-cancelled purchase returns false silently; other
  /// failures leave a [PaywallNotice] / error in the state.
  Future<bool> purchase(PaywallPlan plan) async {
    if (state.isBusy || !RevenueCatRuntime.configured) return false;
    state = state.copyWith(isPurchasing: true);
    try {
      final info = await Purchases.purchasePackage(plan.package);
      _ref.read(customerInfoProvider.notifier).state = info;
      unawaited(_refreshServerPremium());
      if (activePremiumEntitlement(info) == null) {
        // Store accepted the purchase but hasn't granted it yet.
        if (mounted) {
          state = state.copyWith(
            isPurchasing: false,
            notice: PaywallNotice.paymentPending,
          );
        }
        return false;
      }
      if (mounted) state = state.copyWith(isPurchasing: false);
      return true;
    } on PlatformException catch (e) {
      if (mounted) state = _stateForError(e);
      return false;
    } catch (e) {
      if (mounted) state = state.copyWith(isPurchasing: false, errorObject: e);
      return false;
    }
  }

  /// Restores earlier store purchases for this store account. Returns
  /// true when Premium is active afterwards; otherwise the state carries
  /// [PaywallNotice.nothingToRestore] (or an error) and the user stays on
  /// the paywall.
  Future<bool> restore() async {
    if (state.isBusy || !RevenueCatRuntime.configured) return false;
    state = state.copyWith(isRestoring: true);
    try {
      final info = await Purchases.restorePurchases();
      _ref.read(customerInfoProvider.notifier).state = info;
      final restored = activePremiumEntitlement(info) != null;
      if (restored) unawaited(_refreshServerPremium());
      if (mounted) {
        state = state.copyWith(
          isRestoring: false,
          notice: restored
              ? PaywallNotice.restored
              : PaywallNotice.nothingToRestore,
        );
      }
      return restored;
    } on PlatformException catch (e) {
      if (mounted) state = _stateForError(e);
      return false;
    } catch (e) {
      if (mounted) state = state.copyWith(isRestoring: false, errorObject: e);
      return false;
    }
  }

  PaywallState _stateForError(PlatformException e) {
    final idle = state.copyWith(isPurchasing: false, isRestoring: false);
    final code = PurchasesErrorHelper.getErrorCode(e);
    return switch (code) {
      PurchasesErrorCode.purchaseCancelledError => idle,
      PurchasesErrorCode.paymentPendingError =>
        idle.copyWith(notice: PaywallNotice.paymentPending),
      PurchasesErrorCode.purchaseNotAllowedError =>
        idle.copyWith(notice: PaywallNotice.purchaseNotAllowed),
      PurchasesErrorCode.productAlreadyPurchasedError ||
      PurchasesErrorCode.receiptAlreadyInUseError =>
        idle.copyWith(notice: PaywallNotice.alreadyOwned),
      PurchasesErrorCode.networkError ||
      PurchasesErrorCode.offlineConnectionError =>
        idle.copyWith(errorObject: const NetworkException()),
      _ => idle.copyWith(notice: PaywallNotice.purchaseFailed),
    };
  }

  /// The RevenueCat webhook reaches our server a moment after the store
  /// transaction; poll briefly so server-gated features unlock without an
  /// app restart. The UI already trusts the CustomerInfo meanwhile.
  Future<void> _refreshServerPremium() async {
    final container = _ref.container;
    for (var i = 0; i < 8; i++) {
      container.invalidate(serverSubscriptionProvider);
      try {
        if (await container.read(serverPremiumProvider.future)) return;
      } catch (_) {/* retry */}
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }
}
