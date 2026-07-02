import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/navigator_key.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:awaken/features/alarm/presentation/providers/alarm_schedule_providers.dart';
import 'package:awaken/features/alarm/presentation/screens/active_alarm_screen.dart';
import 'package:awaken/features/alarm/presentation/screens/alarm_setup_screen.dart';
import 'package:awaken/features/auth/presentation/screens/auth_screen.dart';
import 'package:awaken/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:awaken/features/success/presentation/screens/success_screen.dart';
import 'package:awaken/features/territory/presentation/providers/active_run_providers.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:awaken/features/territory/presentation/screens/territory_leaderboard_screen.dart';
import 'package:awaken/features/territory/presentation/screens/territory_overview_screen.dart';
import 'package:awaken/features/territory/presentation/screens/territory_run_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

export 'package:awaken/core/router/navigator_key.dart';

/// Route path constants — single source of truth for navigation.
abstract final class AppRoutes {
  static const String shell = '/';
  static const String dashboard = '/dashboard';
  static const String territory = '/territory';
  static const String territoryOverview = '/territory/overview';
  static const String leaderboard = '/leaderboard';
  static const String auth = '/auth';
  static const String activeAlarm = '/alarm/active';
  static const String alarmSetup = '/alarm/setup';
  static const String success = '/alarm/success';

  // Legacy aliases kept so existing code using these still compiles.
  static const String territoryRun = '/territory';
  static const String territoryLeaderboard = '/leaderboard';
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
      // ── Shell: Dashboard | Territory | Leaderboard ──────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _ShellScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.territory,
                builder: (context, state) => const TerritoryRunScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.leaderboard,
                builder: (context, state) => const TerritoryLeaderboardScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Overlay routes: rendered above the shell (no bottom nav) ─────────
      GoRoute(
        path: AppRoutes.territoryOverview,
        builder: (context, state) => const TerritoryOverviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => AuthScreen(
          onSkip: () => navigatorKey.currentContext?.go(AppRoutes.dashboard),
        ),
      ),
      GoRoute(
        path: AppRoutes.activeAlarm,
        builder: (context, state) => _ActiveAlarmRoute(state: state),
      ),
      GoRoute(
        path: AppRoutes.alarmSetup,
        builder: (context, state) => const AlarmSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.success,
        builder: (context, state) => const SuccessScreen(),
      ),

      // ── Redirect bare '/' to '/dashboard' ────────────────────────────────
      GoRoute(
        path: '/',
        redirect: (_, _) => AppRoutes.dashboard,
      ),
    ],
  );
});

// ── Active alarm: resolve entity from navigation extra, alarm list, or query ─

class _ActiveAlarmRoute extends ConsumerWidget {
  const _ActiveAlarmRoute({required this.state});

  final GoRouterState state;

  AlarmEntity? _alarmFromList(List<AlarmEntity> alarms, String id) {
    for (final alarm in alarms) {
      if (alarm.id == id) return alarm;
    }
    return null;
  }

  AlarmEntity _alarmFromQueryParams(Map<String, String> params) {
    final id = params['id']!;
    final reps = int.tryParse(params['reps'] ?? '10') ?? 10;
    final scheduledRaw = params['scheduled'];
    final scheduledTime = scheduledRaw != null && scheduledRaw.isNotEmpty
        ? DateTime.parse(Uri.decodeComponent(scheduledRaw))
        : DateTime.now();

    return AlarmEntity(
      id: id,
      scheduledTime: scheduledTime,
      requiredReps: reps,
      isActive: true,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AlarmEntity? alarm = state.extra as AlarmEntity?;

    if (alarm == null && state.uri.queryParameters.containsKey('id')) {
      final id = state.uri.queryParameters['id']!;
      final alarms = ref.watch(alarmListProvider).valueOrNull;
      alarm = alarms != null ? _alarmFromList(alarms, id) : null;
      alarm ??= _alarmFromQueryParams(state.uri.queryParameters);
    }

    return ActiveAlarmScreen(alarm: alarm);
  }
}

// ── Shell scaffold — inlines the bottom nav so GoRouter manages branch state ─

class _ShellScaffold extends ConsumerStatefulWidget {
  const _ShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<_ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<_ShellScaffold> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markTerritoryMapReadyIfNeeded(widget.navigationShell.currentIndex);
    });
  }

  void _markTerritoryMapReadyIfNeeded(int index) {
    if (index == 1 && !ref.read(territoryMapReadyProvider)) {
      ref.read(territoryMapReadyProvider.notifier).state = true;
    }
  }

  Future<bool> _confirmDiscardRun(BuildContext context) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
        title: const Text(
          'Discard this run?',
          style: TextStyle(color: AppColors.foreground),
        ),
        content: const Text(
          'Leaving now stops GPS tracking and this run will not be saved.',
          style: TextStyle(color: AppColors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep running'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Discard run',
              style: TextStyle(color: AppColors.destructive),
            ),
          ),
        ],
      ),
    );
    if (discard == true) {
      ref.read(activeRunProvider.notifier).reset();
    }
    return discard ?? false;
  }

  Future<void> _onTabSelected(int index) async {
    if (index == widget.navigationShell.currentIndex) {
      widget.navigationShell.goBranch(index, initialLocation: true);
      return;
    }

    final status = ref.read(activeRunProvider).status;
    final isTracking =
        status == RunSessionStatus.tracking || status == RunSessionStatus.finishing;
    if (isTracking) {
      final discard = await _confirmDiscardRun(context);
      if (!discard || !context.mounted) return;
    }

    if (index == 1) {
      _markTerritoryMapReadyIfNeeded(index);
    }

    widget.navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    // Covers bottom-nav taps and deep links (e.g. dashboard territory card).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _markTerritoryMapReadyIfNeeded(widget.navigationShell.currentIndex);
    });

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: widget.navigationShell,
      bottomNavigationBar: _AwakenBottomNav(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}

class _AwakenBottomNav extends StatelessWidget {
  const _AwakenBottomNav({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _primary = Color(0xFF4A9EFF);
  static const _accent = Color(0xFFA259FF);
  static const _card = Color(0xFF282828);
  static const _muted = Color(0xFF9E9E9E);
  static const _border = Color(0x1AFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _card,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                label: 'HOME',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
                accent: _primary,
                muted: _muted,
              ),
              _NavItem(
                icon: Icons.map_rounded,
                label: 'TERRITORY',
                selected: currentIndex == 1,
                onTap: () => onTap(1),
                accent: _accent,
                muted: _muted,
              ),
              _NavItem(
                icon: Icons.leaderboard_rounded,
                label: 'RANKS',
                selected: currentIndex == 2,
                onTap: () => onTap(2),
                accent: _primary,
                muted: _muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accent,
    required this.muted,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final color = selected ? accent : muted;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? accent.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
