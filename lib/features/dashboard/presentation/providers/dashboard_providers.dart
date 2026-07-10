import 'package:awaken/core/services/exact_alarm_permission_service.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:awaken/features/dashboard/domain/entities/dashboard_stats_entity.dart';
import 'package:awaken/features/sessions/domain/entities/session_entity.dart';
import 'package:awaken/features/sessions/presentation/providers/session_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_providers.g.dart';

/// Android exact-alarm permission state.
///
/// `null` when not applicable (iOS / desktop). `false` when Android and the
/// user has denied "Alarms & reminders" — alarms may not fire on time.
@Riverpod(keepAlive: true)
Future<bool?> exactAlarmPermission(ExactAlarmPermissionRef ref) async {
  if (!ExactAlarmPermissionService.isAndroid) return null;
  return ExactAlarmPermissionService.isGranted();
}

/// Ticking clock — emits a new DateTime every second.
@Riverpod(keepAlive: true)
Stream<DateTime> clock(ClockRef ref) {
  return Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  ).asBroadcastStream();
}

/// Formatted clock string — only emits when the displayed HH:MM value changes
/// (once per minute). Downstream widgets that render the clock should watch
/// this, not [clockProvider], to avoid rebuilding every second.
@Riverpod(keepAlive: true)
Stream<String> clockDisplay(ClockDisplayRef ref) async* {
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
Future<DashboardStatsEntity> dashboardStats(DashboardStatsRef ref) async {
  final user = ref.watch(currentUserProvider);
  final sessionRepo = ref.read(sessionRepositoryProvider);

  if (user == null) {
    const guestId = SessionEntity.localGuestUserId;
    final streak = await sessionRepo.streakStats(guestId);
    final weeklyReps = await sessionRepo.weeklyReps(guestId);
    final monthlyCalories = await sessionRepo.monthlyCalories(guestId);
    return DashboardStatsEntity(
      currentStreak: streak.current,
      bestStreak: streak.best,
      weeklyReps: weeklyReps,
      monthlyCalories: monthlyCalories,
      nextAlarm: DateTime.now().add(const Duration(hours: 8)),
      nextAlarmReps: 10,
    );
  }

  final streak = await sessionRepo.streakStats(user.id);
  final weeklyReps = await sessionRepo.weeklyReps(user.id);
  final monthlyCalories = await sessionRepo.monthlyCalories(user.id);

  return DashboardStatsEntity(
    currentStreak: streak.current,
    bestStreak: streak.best,
    weeklyReps: weeklyReps,
    monthlyCalories: monthlyCalories,
    nextAlarm: DateTime.now().add(const Duration(hours: 8)),
    nextAlarmReps: 10,
  );
}

// Remaining hand-written providers (not yet migrated to @riverpod):
// - lib/features/alarm/presentation/providers/alarm_schedule_providers.dart
// - lib/features/sessions/presentation/providers/session_providers.dart
// - lib/features/territory/presentation/providers/territory_providers.dart
