import 'dart:async';

import 'package:cosmic_mirror/config/constants.dart';
import 'package:cosmic_mirror/config/env.dart';
import 'package:cosmic_mirror/core/network/api_endpoints.dart';
import 'package:cosmic_mirror/features/auth/presentation/providers/auth_provider.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Premium is sold on iOS / Android through App Store / Google Play
/// in-app purchases via RevenueCat (store policy: App Store guideline
/// 3.1.1, Google Play payments policy). The backend learns about purchases
/// from RevenueCat webhooks and is the source of truth for what the API
/// allows; the app additionally trusts the RevenueCat [CustomerInfo] right
/// after a purchase so Premium unlocks without waiting for the webhook.

/// Whether RevenueCat was configured at startup (see main.dart). Every
/// `Purchases.*` call must be guarded by this: calling the SDK before
/// `Purchases.configure` hits a native fatal error on iOS.
class RevenueCatRuntime {
  RevenueCatRuntime._();

  static bool configured = false;
}

/// The store entitlement that grants Premium, if active.
EntitlementInfo? activePremiumEntitlement(CustomerInfo? info) =>
    info?.entitlements.active[AppConstants.premiumEntitlement];

/// Latest RevenueCat [CustomerInfo] for the signed-in user, or null when
/// RevenueCat isn't available / nobody is signed in. Kept current by
/// [bindRevenueCatIdentity] (SDK update listener + logIn result) and by
/// purchase / restore results.
final customerInfoProvider = StateProvider<CustomerInfo?>((ref) => null);

/// Subscription as the SERVER sees it (`GET /subscription/status`): premium
/// from either source — App Store / Google Play via RevenueCat, or a web
/// (Stripe) subscription. This is the same rule the API enforces on
/// premium endpoints. Re-fetched whenever the signed-in user changes.
final serverSubscriptionProvider =
    FutureProvider<ServerSubscription>((ref) async {
  final userId = ref.watch(currentUserProvider.select((u) => u.id));
  if (userId == null) return const ServerSubscription();
  final data = await ref
      .read(apiClientProvider)
      .get<Map<String, dynamic>>(ApiEndpoints.subscriptionStatus);
  return ServerSubscription.fromJson(data);
});

/// Premium according to the server only.
final serverPremiumProvider = FutureProvider<bool>((ref) async {
  final sub = await ref.watch(serverSubscriptionProvider.future);
  return sub.isPremium;
});

/// The user really has Premium: the server says so, or the store
/// entitlement is active on this device (covers the seconds between a
/// purchase and the RevenueCat webhook reaching the server). Unlike
/// [isPremiumProvider] this has no dev override — the paywall and
/// "Manage subscription" use it so dev builds can still test purchases.
final hasPremiumProvider = Provider<bool>((ref) {
  final server = ref.watch(serverPremiumProvider).valueOrNull ?? false;
  if (server) return true;
  return activePremiumEntitlement(ref.watch(customerInfoProvider)) != null;
});

/// Gate for premium features.
final isPremiumProvider = Provider<bool>((ref) {
  // Dev-only override: unlock all gated features while testing. Gated on
  // Env.isDev so production builds always use the real checks.
  if (Env.isDev) {
    return true;
  }
  return ref.watch(hasPremiumProvider);
});

/// `/subscription/status` response.
class ServerSubscription {
  const ServerSubscription({
    this.isPremium = false,
    this.source,
    this.store,
    this.expiresAt,
    this.isTrial = false,
    this.willRenew = false,
  });

  factory ServerSubscription.fromJson(Map<String, dynamic> json) {
    final source = json['source'] as String?;
    final expires = json['expires_at'] as String?;
    return ServerSubscription(
      isPremium: json['is_premium'] == true,
      source: (source == null || source.isEmpty) ? null : source,
      store: json['store'] as String?,
      expiresAt: expires == null ? null : DateTime.tryParse(expires),
      isTrial: json['is_trial'] == true,
      willRenew: json['will_renew'] == true,
    );
  }

  final bool isPremium;

  /// `revenuecat` (App Store / Google Play) or `stripe` (web); null when
  /// not premium.
  final String? source;

  /// `app_store` / `play_store` when [source] is `revenuecat`.
  final String? store;
  final DateTime? expiresAt;
  final bool isTrial;
  final bool willRenew;

  bool get isWebSubscription => isPremium && source == 'stripe';
}

/// Where the user manages their store subscription (change plan, cancel):
/// RevenueCat's management URL, falling back to the store's subscriptions
/// page. Null when the Premium in effect isn't a store subscription.
Uri? storeSubscriptionManagementUri(CustomerInfo? info) {
  final entitlement = activePremiumEntitlement(info);
  if (entitlement == null) return null;
  final url = info?.managementURL;
  if (url != null && url.isNotEmpty) {
    final uri = Uri.tryParse(url);
    if (uri != null) return uri;
  }
  return switch (entitlement.store) {
    Store.appStore ||
    Store.macAppStore =>
      Uri.parse('https://apps.apple.com/account/subscriptions'),
    Store.playStore =>
      Uri.parse('https://play.google.com/store/account/subscriptions'),
    _ => null,
  };
}

/// Keeps RevenueCat's app user id equal to the signed-in backend user id
/// (our user UUID), so purchases are attributed to the account and the
/// server's webhook can map them back. Logs out of RevenueCat on sign-out
/// / account deletion so the next user on this device starts clean.
///
/// Call once at startup, after `Purchases.configure`.
void bindRevenueCatIdentity(ProviderContainer container) {
  if (!RevenueCatRuntime.configured) return;

  Purchases.addCustomerInfoUpdateListener((info) {
    // Ignore updates that arrive for an anonymous user after sign-out.
    if (container.read(currentUserProvider).id == null) return;
    container.read(customerInfoProvider.notifier).state = info;
  });

  // Serialize logIn / logOut so a fast sign-out → sign-in can't interleave.
  var pending = Future<void>.value();
  void sync(String? userId) {
    if (userId == null) {
      // Revoke store premium in the UI immediately.
      container.read(customerInfoProvider.notifier).state = null;
    }
    pending = pending.then((_) => _syncRevenueCatUser(container, userId));
  }

  container
    // Signed in (login, registration, or session restore via /users/me).
    ..listen<String?>(
      currentUserProvider.select((u) => u.id),
      (previous, next) {
        if (next != null) {
          sync(next);
        } else if (previous != null) {
          sync(null); // sign-out / account deletion
        }
      },
      fireImmediately: true,
    )
    // Signed out (incl. a cold start without a session, or an expired one).
    ..listen(
      authControllerProvider,
      (previous, next) {
        if (next is AsyncData && next.value == null) sync(null);
      },
      fireImmediately: true,
    );
}

Future<void> _syncRevenueCatUser(
  ProviderContainer container,
  String? userId,
) async {
  try {
    if (userId != null && userId.isNotEmpty) {
      final result = await Purchases.logIn(userId);
      // The user may have changed while logIn was in flight.
      if (container.read(currentUserProvider).id == userId) {
        container.read(customerInfoProvider.notifier).state =
            result.customerInfo;
      }
    } else if (container.read(currentUserProvider).id == null &&
        !await Purchases.isAnonymous) {
      await Purchases.logOut();
    }
  } catch (e) {
    // Non-fatal: premium still comes from the server, and the next
    // sign-in retries. Never block auth on the payments SDK.
    debugPrint('RevenueCat identity sync failed: $e');
  }
}
