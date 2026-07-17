import 'package:awaken/core/services/battery_optimization_service.dart';
import 'package:awaken/core/services/exact_alarm_permission_service.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:awaken/features/dashboard/domain/entities/dashboard_stats_entity.dart';
import 'package:awaken/features/sessions/domain/entities/session_entity.dart';
import 'package:awaken/features/sessions/presentation/providers/session_providers.dart';
// StateProvider moved to legacy.dart in Riverpod 3.
import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_providers.g.dart';

/// Session-scoped dismiss for the exact-alarm permission banner.
final exactAlarmBannerDismissedProvider = StateProvider<bool>((ref) => false);

/// Session-scoped dismiss for the battery-optimization exemption banner.
final batteryOptimizationBannerDismissedProvider = StateProvider<bool>(
  (ref) => false,
);

/// Session-scoped dismiss for the guest "sign in to sync" prompt.
final guestSyncPromptDismissedProvider = StateProvider<bool>((ref) => false);

/// Android exact-alarm permission state.
///
/// `null` when not applicable (iOS / desktop). `false` when Android and the
/// user has denied "Alarms & reminders" — alarms may not fire on time.
@Riverpod(keepAlive: true)
Future<bool?> exactAlarmPermission(Ref ref) async {
  if (!ExactAlarmPermissionService.isAndroid) return null;
  return ExactAlarmPermissionService.isGranted();
}

/// Android battery-optimization exemption state.
///
/// `null` when not applicable (iOS / desktop). `false` when Android and the
/// app is still subject to battery optimization — OEM background killers
/// (MIUI/EMUI/ColorOS/One UI) may terminate the app before a scheduled alarm
/// fires even with exact-alarm permission granted.
@Riverpod(keepAlive: true)
Future<bool?> batteryOptimizationExempt(Ref ref) async {
  if (!BatteryOptimizationService.isAndroid) return null;
  return BatteryOptimizationService.isExempt();
}

/// Ticking clock — emits a new DateTime every second.
@Riverpod(keepAlive: true)
Stream<DateTime> clock(Ref ref) {
  return Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  ).asBroadcastStream();
}

/// Formatted clock string — only emits when the displayed HH:MM value changes
/// (once per minute). Downstream widgets that render the clock should watch
/// this, not [clockProvider], to avoid rebuilding every second.
@Riverpod(keepAlive: true)
Stream<String> clockDisplay(Ref ref) async* {
  var last = _fmt(DateTime.now());
  yield last;

  await for (final dt in Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  )) {
    final next = _fmt(dt);
    if (next != last) {
      last = next;
      yield next;
    }
  }
}

String _fmt(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Dashboard stats — cloud when signed in, local SharedPreferences when guest.
@Riverpod(keepAlive: true)
Future<DashboardStatsEntity> dashboardStats(Ref ref) async {
  final user = ref.watch(currentUserProvider);
  final sessionRepo = ref.read(sessionRepositoryProvider);

  final userId = user?.id ?? SessionEntity.localGuestUserId;
  final streak = await sessionRepo.streakStats(userId);
  final weeklyReps = await sessionRepo.weeklyReps(userId);
  final monthlyCalories = await sessionRepo.monthlyCalories(userId);
  final repsTrend = await sessionRepo.weeklyRepsTrend(userId);

  return DashboardStatsEntity(
    currentStreak: streak.current,
    bestStreak: streak.best,
    weeklyReps: weeklyReps,
    monthlyCalories: monthlyCalories,
    nextAlarm: DateTime.now().add(const Duration(hours: 8)),
    nextAlarmReps: 10,
    repsTrend: repsTrend,
  );
}

// Remaining hand-written providers (not yet migrated to @riverpod):
// - lib/features/alarm/presentation/providers/alarm_schedule_providers.dart
// - lib/features/sessions/presentation/providers/session_providers.dart
// - lib/features/territory/presentation/providers/territory_providers.dart
