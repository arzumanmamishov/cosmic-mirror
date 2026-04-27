import 'dart:async';

import 'package:cosmic_mirror/app.dart';
import 'package:cosmic_mirror/config/env.dart';
import 'package:cosmic_mirror/firebase_options.dart';
import 'package:cosmic_mirror/shared/providers/user_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

Future<void> main() async {
  runZonedGuarded(
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

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      await Hive.initFlutter();

      if (!kIsWeb) {
        await Purchases.configure(
          PurchasesConfiguration(Env.revenueCatApiKey),
        );
      }

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        // TODO: Send to crash reporting service (e.g. Crashlytics)
      };

      final container = ProviderContainer();

      // Bootstrap session once when Firebase auth state changes
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user != null) {
          try {
            await container
                .read(currentUserProvider.notifier)
                .bootstrapSession();
          } catch (_) {}
        } else {
          container.read(currentUserProvider.notifier).clear();
        }
      });

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
