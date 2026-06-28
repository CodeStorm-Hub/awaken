import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/theme/app_theme.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AwakenApp extends ConsumerWidget {
  const AwakenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Awaken',
      debugShowCheckedModeBanner: false,

      // Forced dark — no light theme, no system override
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.dark.copyWith(
        // Inject AwakenTypography so every descendant can call:
        // Theme.of(context).extension<AwakenTypography>()!
        extensions: <ThemeExtension<dynamic>>[AppTypography.extension],
      ),

      routerConfig: router,
    );
  }
}
