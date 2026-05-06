import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

/// State + actions for the paywall screen.
///
/// Subscriptions go through Stripe via the mobile Payment Sheet:
///   1. The user picks monthly/yearly and taps Subscribe.
///   2. We POST `/stripe/payment-sheet` to the backend, which creates
///      (or reuses) a Stripe Customer + an incomplete Subscription and
///      returns the params the Payment Sheet needs.
///   3. We initialize + present the sheet. Stripe collects card / Apple
///      Pay / Google Pay details and confirms the first invoice's
///      PaymentIntent.
///   4. Stripe webhooks back to us flip the subscription to `active`,
///      so on success we just re-fetch session state.
final paywallProvider =
    StateNotifierProvider.autoDispose<PaywallNotifier, PaywallState>((ref) {
  return PaywallNotifier(ref);
});

class PaywallState {
  const PaywallState({
    this.isYearly = true,
    this.isPurchasing = false,
    this.error,
  });

  final bool isYearly;
  final bool isPurchasing;
  final String? error;

  PaywallState copyWith({
    bool? isYearly,
    bool? isPurchasing,
    String? error,
  }) {
    return PaywallState(
      isYearly: isYearly ?? this.isYearly,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      error: error,
    );
  }
}

class PaywallNotifier extends StateNotifier<PaywallState> {
  PaywallNotifier(this._ref) : super(const PaywallState());

  final Ref _ref;

  void togglePlan() {
    state = state.copyWith(isYearly: !state.isYearly);
  }

  /// Kicks off the Stripe Payment Sheet for the currently selected plan.
  /// Returns true on a confirmed purchase, false on cancel or any error
  /// (the error string is left in [state.error] so the UI can surface it).
  Future<bool> purchase() async {
    state = state.copyWith(isPurchasing: true, error: null);
    try {
      final api = _ref.read(apiClientProvider);
      final params = await api.post<Map<String, dynamic>>(
        ApiEndpoints.stripePaymentSheet,
        data: {'plan': state.isYearly ? 'yearly' : 'monthly'},
      );

      final clientSecret = params['client_secret'] as String?;
      final customerId = params['customer_id'] as String?;
      final ephemeralKey = params['ephemeral_key'] as String?;
      if (clientSecret == null || customerId == null || ephemeralKey == null) {
        throw const FormatException('Stripe params missing from server');
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          customerId: customerId,
          customerEphemeralKeySecret: ephemeralKey,
          merchantDisplayName: 'Lively',
          style: ThemeMode.dark,
        ),
      );
      await Stripe.instance.presentPaymentSheet();

      // Webhook will update the DB; refresh the cached session so the UI
      // reflects Premium immediately rather than next cold start.
      try {
        await _ref.read(currentUserProvider.notifier).bootstrapSession();
      } catch (_) {/* non-fatal */}

      state = state.copyWith(isPurchasing: false);
      return true;
    } on StripeException catch (e) {
      // User cancelled the sheet — not really an error.
      if (e.error.code == FailureCode.Canceled) {
        state = state.copyWith(isPurchasing: false);
        return false;
      }
      state = state.copyWith(
        isPurchasing: false,
        error: e.error.localizedMessage ?? e.error.code.name,
      );
      return false;
    } catch (e) {
      state = state.copyWith(isPurchasing: false, error: e.toString());
      return false;
    }
  }

  /// Stripe doesn't have a "restore" concept the way RevenueCat does —
  /// the source of truth is the server. Re-fetch the session and return
  /// whether the user is now Premium.
  Future<bool> restore() async {
    state = state.copyWith(isPurchasing: true, error: null);
    try {
      await _ref.read(currentUserProvider.notifier).bootstrapSession();
      state = state.copyWith(isPurchasing: false);
      return true;
    } catch (e) {
      state = state.copyWith(isPurchasing: false, error: e.toString());
      return false;
    }
  }
}
