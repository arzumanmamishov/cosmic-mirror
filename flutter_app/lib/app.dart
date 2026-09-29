import 'package:cosmic_mirror/config/theme/app_theme.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/router/app_router.dart';
import 'package:cosmic_mirror/shared/providers/locale_provider.dart';
import 'package:cosmic_mirror/shared/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      // Status-bar icons follow the active theme: light icons on the dark
      // cosmic ground, dark icons on the light macOS grey.
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: dark
              ? SystemUiOverlayStyle.light
                  .copyWith(statusBarColor: Colors.transparent)
              : SystemUiOverlayStyle.dark
                  .copyWith(statusBarColor: Colors.transparent),
          child: child!,
        );
      },
    );
  }
}
