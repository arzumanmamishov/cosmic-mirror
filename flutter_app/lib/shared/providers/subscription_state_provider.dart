import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../config/constants.dart';

final customerInfoProvider = FutureProvider<CustomerInfo>((ref) async {
  return Purchases.getCustomerInfo();
});

final isPremiumProvider = Provider<bool>((ref) {
  // TESTING OVERRIDE: always premium so all gated features are accessible.
  // Remove this short-circuit before production.
  return true;
  // ignore: dead_code
  final customerInfo = ref.watch(customerInfoProvider);
  return customerInfo.whenOrNull(
        data: (info) =>
            info.entitlements.active.containsKey(AppConstants.premiumEntitlement),
      ) ??
      false;
});

final currentOfferingsProvider = FutureProvider<Offerings>((ref) async {
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
