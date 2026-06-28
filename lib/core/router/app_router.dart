import 'package:awaken/features/alarm/presentation/screens/active_alarm_screen.dart';
import 'package:awaken/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:awaken/features/success/presentation/screens/success_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Route path constants — single source of truth for navigation.
abstract final class AppRoutes {
  static const String dashboard = '/';
  static const String activeAlarm = '/alarm/active';
  static const String success = '/alarm/success';
}

/// GoRouter kept alive for the session lifetime — never rebuilt or disposed.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.activeAlarm,
        builder: (context, state) => const ActiveAlarmScreen(),
      ),
      GoRoute(
        path: AppRoutes.success,
        builder: (context, state) => const SuccessScreen(),
      ),
    ],
  );
});
