import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../shared/providers/subscription_state_provider.dart';

final paywallProvider =
    StateNotifierProvider.autoDispose<PaywallNotifier, PaywallState>((ref) {
  return PaywallNotifier(ref);
});

class PaywallState {
  const PaywallState({
    this.isYearly = true,
    this.offerings,
    this.isLoading = false,
    this.isPurchasing = false,
    this.error,
  });

  final bool isYearly;
  final Offerings? offerings;
  final bool isLoading;
  final bool isPurchasing;
  final String? error;

  Package? get selectedPackage {
    final offering = offerings?.current;
    if (offering == null) return null;
    return isYearly ? offering.annual : offering.monthly;
  }

  PaywallState copyWith({
    bool? isYearly,
    Offerings? offerings,
    bool? isLoading,
    bool? isPurchasing,
    String? error,
  }) {
    return PaywallState(
      isYearly: isYearly ?? this.isYearly,
      offerings: offerings ?? this.offerings,
      isLoading: isLoading ?? this.isLoading,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      error: error,
    );
  }
}

class PaywallNotifier extends StateNotifier<PaywallState> {
  PaywallNotifier(this._ref) : super(const PaywallState(isLoading: true)) {
    _loadOfferings();
  }

  final Ref _ref;

  Future<void> _loadOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      state = state.copyWith(offerings: offerings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void togglePlan() {
    state = state.copyWith(isYearly: !state.isYearly);
  }

  Future<bool> purchase() async {
    final package = state.selectedPackage;
    if (package == null) return false;

    state = state.copyWith(isPurchasing: true, error: null);
    try {
      await _ref
          .read(subscriptionStateProvider.notifier)
          .purchasePackage(package);
      state = state.copyWith(isPurchasing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isPurchasing: false, error: e.toString());
      return false;
    }
  }

  Future<bool> restore() async {
    state = state.copyWith(isPurchasing: true, error: null);
    try {
      await _ref.read(subscriptionStateProvider.notifier).restorePurchases();
      state = state.copyWith(isPurchasing: false);
      return _ref.read(isPremiumProvider);
    } catch (e) {
      state = state.copyWith(isPurchasing: false, error: e.toString());
      return false;
    }
  }
}
