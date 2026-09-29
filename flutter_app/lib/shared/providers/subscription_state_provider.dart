import 'package:cosmic_mirror/config/constants.dart';
import 'package:cosmic_mirror/config/env.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Calling any `Purchases.*` API before `Purchases.configure` hits a
/// native fatal error on iOS, so bail out with a Dart error instead when
/// no RevenueCat key was compiled in (see main.dart).
void _requireRevenueCat() {
  if (!Env.hasRevenueCatKey) {
    throw StateError('RevenueCat is not configured (REVENUECAT_API_KEY).');
  }
}

final customerInfoProvider = FutureProvider<CustomerInfo>((ref) async {
  _requireRevenueCat();
  return Purchases.getCustomerInfo();
});

/// Premium as the SERVER sees it — the Stripe-backed subscription that
/// `/subscription/status` reports. This is the same rule the API enforces
/// on premium endpoints, so the app and server can't disagree. Re-fetched
/// whenever the signed-in user changes.
final serverPremiumProvider = FutureProvider<bool>((ref) async {
  final userId = ref.watch(currentUserProvider.select((u) => u.id));
  if (userId == null) return false;
  final data = await ref
      .read(apiClientProvider)
      .get<Map<String, dynamic>>(ApiEndpoints.subscriptionStatus);
  return data['is_premium'] == true;
});

final isPremiumProvider = Provider<bool>((ref) {
  // Dev-only override: unlock all gated features while testing. Gated on
  // Env.isDev so production builds always use the real checks below.
  if (Env.isDev) {
    return true;
  }
  // Purchases go through Stripe, so the backend is the source of truth.
  final server = ref.watch(serverPremiumProvider).valueOrNull ?? false;
  if (server) return true;
  // RevenueCat entitlement only counts when a key is compiled in.
  if (!Env.hasRevenueCatKey) return false;
  final customerInfo = ref.watch(customerInfoProvider);
  return customerInfo.whenOrNull(
        data: (info) => info.entitlements.active
            .containsKey(AppConstants.premiumEntitlement),
      ) ??
      false;
});

final currentOfferingsProvider = FutureProvider<Offerings>((ref) async {
  _requireRevenueCat();
  return Purchases.getOfferings();
});

final subscriptionStateProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  return SubscriptionNotifier();
});

enum SubscriptionStatus { free, trialing, premium, expired }

class SubscriptionState {
  const SubscriptionState({
    this.status = SubscriptionStatus.free,
    this.expiresAt,
    this.isLoading = false,
  });

  final SubscriptionStatus status;
  final DateTime? expiresAt;
  final bool isLoading;

  bool get isPremium =>
      status == SubscriptionStatus.premium ||
      status == SubscriptionStatus.trialing;

  SubscriptionState copyWith({
    SubscriptionStatus? status,
    DateTime? expiresAt,
    bool? isLoading,
  }) {
    return SubscriptionState(
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  SubscriptionNotifier() : super(const SubscriptionState());

  Future<void> purchasePackage(Package package) async {
    state = state.copyWith(isLoading: true);
    try {
      _requireRevenueCat();
      final result = await Purchases.purchasePackage(package);
      if (result.entitlements.active
          .containsKey(AppConstants.premiumEntitlement)) {
        state = state.copyWith(
          status: SubscriptionStatus.premium,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> restorePurchases() async {
    state = state.copyWith(isLoading: true);
    try {
      _requireRevenueCat();
      final info = await Purchases.restorePurchases();
      if (info.entitlements.active
          .containsKey(AppConstants.premiumEntitlement)) {
        state = state.copyWith(
          status: SubscriptionStatus.premium,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> refresh() async {
    try {
      _requireRevenueCat();
      final info = await Purchases.getCustomerInfo();
      if (info.entitlements.active
          .containsKey(AppConstants.premiumEntitlement)) {
        state = state.copyWith(status: SubscriptionStatus.premium);
      }
    } catch (_) {
      // Silent refresh failure
    }
  }
}
