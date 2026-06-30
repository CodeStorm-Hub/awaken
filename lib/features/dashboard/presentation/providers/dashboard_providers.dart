import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:awaken/features/dashboard/domain/entities/dashboard_stats_entity.dart';
import 'package:awaken/features/sessions/presentation/providers/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  final now = DateTime.now();
  yield _fmt(now);

  await for (final dt in Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  )) {
    yield _fmt(dt);
  }
});

String _fmt(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Dashboard stats — reads from Supabase when signed in, falls back to stubs.
final dashboardStatsProvider = FutureProvider<DashboardStatsEntity>((ref) async {
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    // Not signed in — return stub data
    return DashboardStatsEntity(
      currentStreak: 0,
      bestStreak: 0,
      weeklyReps: 0,
      monthlyCalories: 0,
      nextAlarm: DateTime.now().add(const Duration(hours: 8)),
      nextAlarmReps: 10,
    );
  }

  final client = Supabase.instance.client;
  final sessionRepo = ref.read(sessionRepositoryProvider);

  // Run all three queries in parallel using explicit futures
  final streakFuture = client
      .from('streaks')
      .select('current_streak, best_streak')
      .eq('user_id', user.id)
      .maybeSingle();
  final weeklyRepsFuture = sessionRepo.weeklyReps(user.id);
  final monthlyCalsFuture = sessionRepo.monthlyCalories(user.id);

  final streakRow = await streakFuture;
  final weeklyReps = await weeklyRepsFuture;
  final monthlyCalories = await monthlyCalsFuture;

  return DashboardStatsEntity(
    currentStreak: (streakRow?['current_streak'] as int?) ?? 0,
    bestStreak: (streakRow?['best_streak'] as int?) ?? 0,
    weeklyReps: weeklyReps,
    monthlyCalories: monthlyCalories,
    nextAlarm: DateTime.now().add(const Duration(hours: 8)),
    nextAlarmReps: 10,
  );
});
