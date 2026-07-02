import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/theme/app_theme.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/sessions/presentation/providers/session_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AwakenApp extends ConsumerStatefulWidget {
  const AwakenApp({super.key});

  @override
  ConsumerState<AwakenApp> createState() => _AwakenAppState();
}

class _AwakenAppState extends ConsumerState<AwakenApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(sessionSyncServiceProvider).flushPendingSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionSyncOnSignInProvider);

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
