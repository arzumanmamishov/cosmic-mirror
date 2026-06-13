import 'package:cosmic_mirror/config/api_url_override.dart';

enum Environment { dev, staging, prod }

class Env {
  Env._();

  static const environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );

  static Environment get current {
    switch (environment) {
      case 'prod':
        return Environment.prod;
      case 'staging':
        return Environment.staging;
      default:
        return Environment.dev;
    }
  }

  static String get apiBaseUrl {
    // A runtime override (set via Settings → Developer) beats the
    // compile-time default. This keeps a stale binary usable when the
    // dev machine's LAN IP changes — no rebuild required.
    final override = ApiUrlOverride.current;
    if (override != null && override.isNotEmpty) return override;
    switch (current) {
      case Environment.prod:
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://api.livelyapp.co',
        );
      case Environment.staging:
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://staging-api.livelyapp.co',
        );
      case Environment.dev:
        // For real Android/iOS devices, "localhost" points at the device
        // itself, not the dev machine, so we use the LAN IP. Override at
        // build time with --dart-define=API_BASE_URL=... when needed
        // (e.g. http://10.0.2.2:8080 for the Android emulator).
        return const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://192.168.1.44:8080',
        );
    }
  }

  static const revenueCatApiKey = String.fromEnvironment(
    'REVENUECAT_API_KEY',
    defaultValue: 'your_revenuecat_api_key',
  );

  /// Stripe **publishable** key (safe to ship in the binary). The mobile
  /// Payment Sheet uses this together with the per-customer ephemeral
  /// key + payment-intent client_secret minted by our backend. Override
  /// at build time with `--dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_…`.
  static const stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
  );

  /// `merchant.com.lively.app` for Apple Pay — wire to a real merchant
  /// id in Stripe + your provisioning profile before enabling Apple Pay.
  static const stripeMerchantIdentifier = String.fromEnvironment(
    'STRIPE_MERCHANT_IDENTIFIER',
    defaultValue: 'merchant.com.lively.app',
  );

  static bool get isDev => current == Environment.dev;
  static bool get isProd => current == Environment.prod;
}
