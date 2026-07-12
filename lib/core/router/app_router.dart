import 'package:awaken/core/router/navigator_key.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:awaken/features/alarm/presentation/providers/alarm_schedule_providers.dart';
import 'package:awaken/features/alarm/presentation/screens/active_alarm_screen.dart';
import 'package:awaken/features/alarm/presentation/screens/alarm_setup_screen.dart';
import 'package:awaken/features/auth/presentation/screens/auth_screen.dart';
import 'package:awaken/features/auth/presentation/screens/profile_screen.dart';
import 'package:awaken/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:awaken/features/onboarding/presentation/screens/onboarding_screen.dart';
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
  static const String profile = '/profile';
  static const String activeAlarm = '/alarm/active';
  static const String alarmSetup = '/alarm/setup';
  static const String success = '/alarm/success';
  static const String onboarding = '/onboarding';

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
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
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
        builder: (context, state) => SuccessScreen(
          alarm: state.extra is AlarmEntity ? state.extra as AlarmEntity : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
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
      _syncShellTabIndex(widget.navigationShell.currentIndex);
    });
  }

  void _syncShellTabIndex(int index) {
    ref.read(territoryShellTabIndexProvider.notifier).state = index;
    _markTerritoryMapReadyIfNeeded(index);
  }

  void _markTerritoryMapReadyIfNeeded(int index) {
    if (index == 1 && !ref.read(territoryMapReadyProvider)) {
      ref.read(territoryMapReadyProvider.notifier).state = true;
    }
  }

  void _onTabSelected(int index) {
    if (index == widget.navigationShell.currentIndex) {
      widget.navigationShell.goBranch(index, initialLocation: true);
      return;
    }

    // Active runs keep GPS tracking across tab switches — only Stop ends them.
    _syncShellTabIndex(index);
    widget.navigationShell.goBranch(index);
  }

  @override
  Widget build(BuildContext context) {
    // Covers bottom-nav taps and deep links (e.g. dashboard territory card).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncShellTabIndex(widget.navigationShell.currentIndex);
    });

    final runStatus = ref.watch(activeRunProvider.select((s) => s.status));
    final runActive = runStatus == RunSessionStatus.tracking ||
        runStatus == RunSessionStatus.paused ||
        runStatus == RunSessionStatus.finishing;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: widget.navigationShell,
      bottomNavigationBar: _AwakenBottomNav(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: _onTabSelected,
        territoryRunActive: runActive,
      ),
    );
  }
}

class _AwakenBottomNav extends StatelessWidget {
  const _AwakenBottomNav({
    required this.currentIndex,
    required this.onTap,
    this.territoryRunActive = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool territoryRunActive;

  static const _primary = AppColors.primary;
  static const _accent = AppColors.accent;
  static const _card = AppColors.card;
  static const _muted = AppColors.mutedForeground;
  static const _border = AppColors.border;

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
                showLiveDot: territoryRunActive,
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
    this.showLiveDot = false,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;
  final Color muted;
  final bool showLiveDot;

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
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 22),
                  if (showLiveDot)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.destructive,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.card, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
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
