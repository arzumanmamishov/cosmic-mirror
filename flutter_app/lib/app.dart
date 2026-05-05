import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'router/app_router.dart';
import 'shared/providers/locale_provider.dart';
import 'shared/providers/theme_provider.dart';

class CosmicMirrorApp extends ConsumerWidget {
  const CosmicMirrorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Lively',
      debugShowCheckedModeBanner: false,
      theme: CosmicTheme.lightTheme,
      darkTheme: CosmicTheme.darkTheme,
      themeMode: themeMode,
      // Locale = null → follow device. When the user picks a language in
      // settings we override it explicitly.
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
