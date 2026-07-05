import 'dart:async';

import 'package:cosmic_mirror/app.dart';
import 'package:cosmic_mirror/config/api_url_override.dart';
import 'package:cosmic_mirror/config/env.dart';
import 'package:cosmic_mirror/features/auth/presentation/providers/auth_provider.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/error_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

Future<void> main() async {
  runZonedGuarded<void>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      if (!kIsWeb) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);

        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Color(0xFF0A0E27),
            systemNavigationBarIconBrightness: Brightness.light,
          ),
        );
      }

      // Hydrate the runtime API base URL override BEFORE anything that
      // might construct an ApiClient — otherwise the first session call
      // would still go to the compile-time default.
      await ApiUrlOverride.load();

      await Hive.initFlutter();

      // Skip RevenueCat init when no real API key is wired in. The default
      // placeholder ('your_revenuecat_api_key') triggers a noisy
      // InvalidCredentialsError on every cold start in dev. Pass a real
      // key via --dart-define=REVENUECAT_API_KEY=... to enable.
      final hasRcKey = Env.revenueCatApiKey.isNotEmpty &&
          Env.revenueCatApiKey != 'your_revenuecat_api_key';
      if (!kIsWeb && hasRcKey) {
        await Purchases.configure(
          PurchasesConfiguration(Env.revenueCatApiKey),
        );
      }

      // Stripe — the publishable key MUST be set before any
      // Stripe.instance.* call (Payment Sheet, Apple Pay, etc.). Skip
      // on web (flutter_stripe mobile-only) and when no key is wired
      // (silent dev mode).
      if (!kIsWeb && Env.stripePublishableKey.isNotEmpty) {
        Stripe.publishableKey = Env.stripePublishableKey;
        Stripe.merchantIdentifier = Env.stripeMerchantIdentifier;
        await Stripe.instance.applySettings();
      }

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        // TODO: Send to crash reporting service (e.g. Crashlytics)
      };

      // Replace Flutter's red error box with our cosmic-themed error
      // card so widget-build crashes look graceful in the user's app
      // rather than screaming "RenderBox was not laid out".
      ErrorWidget.builder = cosmicErrorWidgetBuilder;

      final container = ProviderContainer();

      // Warm the AuthController (async build reads the stored refresh
      // token) then, if there's a session, bootstrap the /users/me
      // profile so the router redirect knows onboarding status. The
      // ApiClient interceptor handles access-token refresh from there.
      unawaited(
        container.read(authControllerProvider.future).then((user) async {
          if (user != null) {
            try {
              await container
                  .read(currentUserProvider.notifier)
                  .bootstrapSession();
            } catch (_) {/* surfaced via UserState.bootstrapError */}
          }
        }),
      );

      runApp(
        UncontrolledProviderScope(
          container: container,
          child: const CosmicMirrorApp(),
        ),
      );
    },
    (error, stackTrace) {
      debugPrint('Uncaught error: $error');
      debugPrint('Stack trace: $stackTrace');
      // TODO: Send to crash reporting service
    },
  );
}
