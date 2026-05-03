import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/theme/app_theme.dart';
import 'router/app_router.dart';
import 'shared/providers/theme_provider.dart';

class CosmicMirrorApp extends ConsumerWidget {
  const CosmicMirrorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Lively',
      debugShowCheckedModeBanner: false,
      theme: CosmicTheme.lightTheme,
      darkTheme: CosmicTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
