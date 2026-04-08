import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'app.dart';
import 'config/env.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

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

      await Firebase.initializeApp();
      await Hive.initFlutter();

      await Purchases.configure(
        PurchasesConfiguration(Env.revenueCatApiKey),
      );

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        // TODO: Send to crash reporting service (e.g. Crashlytics)
      };

      runApp(
        const ProviderScope(
          child: CosmicMirrorApp(),
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
