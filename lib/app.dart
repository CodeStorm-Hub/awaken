import 'dart:async';

import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/services/alarm_notification_service.dart';
import 'package:awaken/core/services/turf_hit_realtime_service.dart';
import 'package:awaken/core/theme/app_theme.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/alarm/domain/services/alarm_bailout_service.dart';
import 'package:awaken/features/alarm/presentation/providers/alarm_schedule_providers.dart';
import 'package:awaken/features/dashboard/presentation/providers/hud_theme_providers.dart';
import 'package:awaken/features/sessions/presentation/providers/session_providers.dart';
import 'package:awaken/features/territory/presentation/providers/active_run_providers.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(ref.read(activeRunProvider.notifier).restoreFromCheckpoint());
      // Covers a cold-start race: flutter_local_notifications can deliver an
      // alarm notification tap via the foreground-tap callback (fired during
      // plugin init, before this widget tree existed) rather than through
      // getNotificationAppLaunchDetails(). That callback stashes the route
      // (see AlarmNotificationService._onForegroundTap) since it had no
      // navigator context yet — consume it here as soon as one exists,
      // rather than waiting for an AppLifecycleState.resumed transition that
      // may never fire right after a genuine cold start.
      unawaited(_navigatePendingAlarmRoute());
    });
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
      unawaited(ref.read(activeRunProvider.notifier).flushPendingCaptures());
      unawaited(
        ref.read(activeRunProvider.notifier).ensureBackgroundTracking(),
      );
      unawaited(_applyBailouts());
      unawaited(_navigatePendingAlarmRoute());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Best-effort flush so a kill mid-background still has a fresh checkpoint.
      unawaited(ref.read(activeRunProvider.notifier).persistCheckpointNow());
    }
  }

  Future<void> _applyBailouts() async {
    final applied = await const AlarmBailoutService().applyBailoutPenalties(
      repository: ref.read(alarmRepositoryProvider),
    );
    if (applied > 0) {
      ref.invalidate(alarmListProvider);
    }
  }

  Future<void> _navigatePendingAlarmRoute() async {
    final route = await AlarmNotificationService.consumePendingRoute();
    if (route == null) return;
    ref.read(appRouterProvider).go(route);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionSyncOnSignInProvider);
    ref.watch(captureSyncOnSignInProvider);
    ref.watch(turfHitRealtimeProvider);
    // Keep active-run notifier alive at app root so checkpoint restore runs
    // on cold start even before the user opens the Territory tab.
    ref.watch(activeRunProvider);

    final router = ref.watch(appRouterProvider);
    final hudTheme = ref.watch(activeHudThemeProvider);

    return MaterialApp.router(
      title: 'Awaken',
      debugShowCheckedModeBanner: false,

      // Forced dark — no light theme, no system override
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.dark.copyWith(
        // Inject AwakenTypography and the active HudTheme so every descendant
        // can call:  Theme.of(context).extension<AwakenTypography>()!
        //            Theme.of(context).extension<HudTheme>()!
        extensions: <ThemeExtension<dynamic>>[
          AppTypography.extension,
          hudTheme,
        ],
      ),

      routerConfig: router,
    );
  }
}
