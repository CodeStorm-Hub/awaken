import 'package:awaken/core/router/navigator_key.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:awaken/features/alarm/presentation/screens/active_alarm_screen.dart';
import 'package:awaken/features/alarm/presentation/screens/alarm_setup_screen.dart';
import 'package:awaken/features/auth/presentation/screens/auth_screen.dart';
import 'package:awaken/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:awaken/features/success/presentation/screens/success_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

export 'package:awaken/core/router/navigator_key.dart';

/// Route path constants — single source of truth for navigation.
abstract final class AppRoutes {
  static const String dashboard = '/';
  static const String auth = '/auth';
  static const String activeAlarm = '/alarm/active';
  static const String alarmSetup = '/alarm/setup';
  static const String success = '/alarm/success';
}

/// Override this before runApp() when the app was launched from a notification.
final initialLocationProvider = Provider<String>((_) => AppRoutes.dashboard);

/// GoRouter kept alive for the session lifetime — never rebuilt or disposed.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: ref.read(initialLocationProvider),
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => AuthScreen(
          onSkip: () => navigatorKey.currentContext?.go(AppRoutes.dashboard),
        ),
      ),
      GoRoute(
        path: AppRoutes.activeAlarm,
        builder: (context, state) => ActiveAlarmScreen(
          alarm: state.extra as AlarmEntity?,
        ),
      ),
      GoRoute(
        path: AppRoutes.alarmSetup,
        builder: (context, state) => const AlarmSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.success,
        builder: (context, state) => const SuccessScreen(),
      ),
    ],
  );
});
