import 'package:cosmic_mirror/config/api_url_override.dart';
import 'package:flutter/foundation.dart';

enum Environment { dev, staging, prod }

class Env {
  Env._();

  // Explicit --dart-define=ENVIRONMENT wins. Otherwise we default by build
  // mode: release builds resolve to `prod` and debug/profile to `dev`, so a
  // plain `flutter build` (no dart-define) never ships pointing at a dev LAN
  // IP. Pass --dart-define=ENVIRONMENT=staging to target staging.
  static const _envOverride = String.fromEnvironment('ENVIRONMENT');

  static String get environment =>
      _envOverride.isNotEmpty ? _envOverride : (kReleaseMode ? 'prod' : 'dev');

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
    // dev machine's LAN IP changes — no rebuild required. Dev builds only:
    // in staging/prod a tampered prefs file must not be able to redirect
    // traffic (and bearer tokens) to another host.
    final override = isDev ? ApiUrlOverride.current : null;
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

  /// RevenueCat public SDK key for the platform being built (iOS keys start
  /// with `appl_`, Android keys with `goog_`). Empty unless provided with
  /// `--dart-define=REVENUECAT_API_KEY=...` — scripts/build_release.sh
  /// passes the right per-platform key. When missing (or for the wrong
  /// platform) RevenueCat is never configured and every `Purchases.*` call
  /// is skipped — see [hasRevenueCatKey].
  static const revenueCatApiKey = String.fromEnvironment('REVENUECAT_API_KEY');

  /// True only when a RevenueCat key for this platform was compiled in.
  /// In-app purchases exist only on iOS / Android (never on web), and an
  /// Android key in an iOS build (or vice versa) would fail at configure
  /// time, so it is rejected here. `test_` keys (RevenueCat Test Store)
  /// are accepted on both.
  static bool get hasRevenueCatKey {
    if (kIsWeb || revenueCatApiKey.isEmpty) return false;
    if (revenueCatApiKey.startsWith('test_')) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => revenueCatApiKey.startsWith('appl_'),
      TargetPlatform.android => revenueCatApiKey.startsWith('goog_'),
      _ => false,
    };
  }

  /// Numeric App Store id (the digits in apps.apple.com/app/id<…>). Only
  /// needed on iOS as a fallback when the in-app review prompt is
  /// unavailable. Pass with `--dart-define=APP_STORE_ID=...` once the app
  /// is listed.
  static const appStoreId = String.fromEnvironment('APP_STORE_ID');

  static bool get isDev => current == Environment.dev;
  static bool get isProd => current == Environment.prod;
}
