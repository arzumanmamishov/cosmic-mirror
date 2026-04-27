import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/theme/app_theme.dart';
import 'router/app_router.dart';

class CosmicMirrorApp extends ConsumerWidget {
  const CosmicMirrorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Lively',
      debugShowCheckedModeBanner: false,
      theme: CosmicTheme.darkTheme,
      routerConfig: router,
    );
  }
}
