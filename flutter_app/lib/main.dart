import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:cosmic_mirror/app.dart';
import 'package:cosmic_mirror/config/api_url_override.dart';
import 'package:cosmic_mirror/config/env.dart';
import 'package:cosmic_mirror/features/auth/presentation/providers/auth_provider.dart';
import 'package:cosmic_mirror/shared/providers/subscription_state_provider.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:cosmic_mirror/shared/widgets/error_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Single sink for every uncaught error — framework (FlutterError.onError),
/// platform/engine (PlatformDispatcher.onError) and async zone errors
/// (runZonedGuarded).
// TODO(crash-reporting): forward to the crash reporter once the owner picks
// one (Crashlytics vs Sentry), e.g. `recordError(error, stack, fatal: fatal)`.
void reportError(Object error, StackTrace? stack, {bool fatal = false}) {
  debugPrint('${fatal ? 'Fatal' : 'Uncaught'} error: $error');
  if (stack != null) debugPrint('Stack trace: $stack');
}

Future<void> main() async {
  runZonedGuarded<void>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Install the error hooks first so failures during the init below
      // are reported too.
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        reportError(details.exception, details.stack);
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        reportError(error, stack, fatal: true);
        return true;
      };

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

      // In-app purchases (App Store / Google Play) via RevenueCat. Skipped
      // on web and when no key for this platform was compiled in
      // (--dart-define=REVENUECAT_API_KEY=appl_… / goog_…, see
      // scripts/build_release.sh); every Purchases.* call is guarded by
      // RevenueCatRuntime.configured, so that degrades to "purchases
      // unavailable" instead of crashing. The app user id is set to our
      // user id after sign-in (bindRevenueCatIdentity below).
      if (Env.hasRevenueCatKey) {
        // Never let a payments SDK failure block runApp — the app would
        // sit on the native splash forever.
        try {
          await Purchases.configure(
            PurchasesConfiguration(Env.revenueCatApiKey),
          );
          RevenueCatRuntime.configured = true;
        } catch (e, st) {
          reportError(e, st);
        }
      } else if (kReleaseMode && !kIsWeb) {
        debugPrint(
          'WARNING: no RevenueCat key for this platform — in-app purchases '
          'disabled.',
        );
      }

      // Replace Flutter's red error box with our cosmic-themed error
      // card so widget-build crashes look graceful in the user's app
      // rather than screaming "RenderBox was not laid out".
      ErrorWidget.builder = cosmicErrorWidgetBuilder;

      final container = ProviderContainer();

      // Keep RevenueCat's app user id == our user id (logIn after sign-in
      // / session restore, logOut on sign-out and account deletion).
      bindRevenueCatIdentity(container);

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
    (error, stackTrace) => reportError(error, stackTrace, fatal: true),
  );
}
