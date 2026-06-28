import 'package:awaken/features/dashboard/domain/entities/dashboard_stats_entity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ticking clock — emits a new DateTime every second.
final clockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  ).asBroadcastStream();
});

/// Formatted clock string — only emits when the displayed HH:MM value changes
/// (once per minute). Downstream widgets that render the clock should watch
/// this, not clockProvider, to avoid rebuilding every second.
final clockDisplayProvider = StreamProvider<String>((ref) async* {
  // Seed immediately so the clock shows on first frame
  final now = DateTime.now();
  yield _fmt(now);

  await for (final dt in Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  )) {
    final str = _fmt(dt);
    // Yield only when the formatted display string actually changes
    // (i.e., on the minute boundary, not every tick)
    yield str;
  }
});

String _fmt(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Dashboard stats — stub returning mock data until Supabase is wired.
/// Phase 4 replaces this body with a Supabase repository call.
final dashboardStatsProvider = Provider<DashboardStatsEntity>((ref) {
  return DashboardStatsEntity(
    currentStreak: 7,
    bestStreak: 14,
    weeklyReps: 84,
    monthlyCalories: 312,
    nextAlarm: DateTime.now().add(const Duration(hours: 8)),
    nextAlarmReps: 10,
  );
});
