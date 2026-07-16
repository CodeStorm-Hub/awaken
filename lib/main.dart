import 'dart:async';

import 'package:awaken/app.dart';
import 'package:awaken/core/constants/supabase_config.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/services/alarm_notification_service.dart';
import 'package:awaken/core/services/fcm_push_service.dart';
import 'package:awaken/core/services/territory_decay_notification_service.dart';
import 'package:awaken/core/services/turf_hit_notification_service.dart';
import 'package:awaken/core/utils/expected_async_cancellation.dart';
import 'package:awaken/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Timezone setup (required by flutter_local_notifications zonedSchedule) ─
  tz.initializeTimeZones();
  try {
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
  } catch (e) {
    // Falling back to UTC silently would shift every zonedSchedule() call by
    // the device's UTC offset, so an alarm set for a local wall-clock time
    // would fire at the wrong moment (or appear to never fire in the
    // expected window). Log it so a bad fallback is diagnosable.
    debugPrint('[Timezone] Failed to resolve local timezone, using UTC: $e');
    tz.setLocalLocation(tz.UTC);
  }

  // ── Supabase ──────────────────────────────────────────────────────────────
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey, // ignore: deprecated_member_use
  );

  // ── Alarm notification init (must complete before runApp for scheduling) ──
  await AlarmNotificationService.initialize();
  // TerritoryDecayNotificationService.initialize() is deferred to after the
  // first frame — see [_deferNonCriticalStartup] below.

  // Detect if we were launched by tapping an alarm notification
  // getInitialRoute() returns AppRoutes.dashboard ('/' in the old router) when
  // not launched from a notification. Remap that to '/dashboard' (the shell
  // branch root) so the new StatefulShellRoute resolves correctly.
  var rawRoute = await AlarmNotificationService.getInitialRoute();
  if (rawRoute == '/' || rawRoute == AppRoutes.dashboard) {
    final onboardingDone = await OnboardingScreen.isComplete();
    if (!onboardingDone) {
      rawRoute = AppRoutes.onboarding;
    } else {
      rawRoute = AppRoutes.dashboard;
    }
  }
  final initialRoute = rawRoute;

  // ── System UI ─────────────────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Swallow expected vector_map_tiles tile-render cancellations (tab dispose /
  // visible-tile churn) before runApp so they never flood the console.
  installExpectedAsyncCancellationHandlers();

  // Defer non-critical startup work until after the first frame is painted.
  // Keeps timezone + alarm notification init on the critical path above.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(_deferNonCriticalStartup());
  });

  runApp(
    ProviderScope(
      overrides: [
        if (initialRoute != AppRoutes.dashboard)
          initialLocationProvider.overrideWithValue(initialRoute),
      ],
      child: const AwakenApp(),
    ),
  );
}

/// Startup work intentionally deferred from [main] to reduce first-frame jank.
///
/// - [TerritoryDecayNotificationService.initialize]: creates a secondary
///   notification channel; not needed until the dashboard surfaces decay warnings.
Future<void> _deferNonCriticalStartup() async {
  await TerritoryDecayNotificationService.initialize();
  await TurfHitNotificationService.initialize();
  await FcmPushService.initialize();
}
