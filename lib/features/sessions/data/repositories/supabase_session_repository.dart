import 'package:awaken/features/sessions/domain/entities/session_entity.dart';
import 'package:awaken/features/sessions/domain/repositories/session_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSessionRepository implements SessionRepository {
  const SupabaseSessionRepository();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<void> recordSession(SessionEntity session) async {
    await _client.from('sessions').insert({
      'user_id': session.userId,
      if (session.alarmId != null) 'alarm_id': session.alarmId,
      'completed_at': session.completedAt.toUtc().toIso8601String(),
      'reps_completed': session.repsCompleted,
      'duration_seconds': session.durationSeconds,
      'calories_burned': session.caloriesBurned,
    });

    // Update streak after recording a successful session
    await _updateStreak(session.userId, session.completedAt);
  }

  @override
  Future<int> weeklyReps(String userId, {int days = 7}) async {
    final since = DateTime.now().subtract(Duration(days: days)).toUtc().toIso8601String();
    final data = await _client
        .from('sessions')
        .select('reps_completed')
        .eq('user_id', userId)
        .gte('completed_at', since);
    return (data as List)
        .fold<int>(0, (sum, row) => sum + (row['reps_completed'] as int));
  }

  @override
  Future<int> monthlyCalories(String userId, {int days = 30}) async {
    final since = DateTime.now().subtract(Duration(days: days)).toUtc().toIso8601String();
    final data = await _client
        .from('sessions')
        .select('calories_burned')
        .eq('user_id', userId)
        .gte('completed_at', since);
    return (data as List)
        .fold<int>(0, (sum, row) => sum + (row['calories_burned'] as int));
  }

  @override
  Future<List<int>> weeklyRepsTrend(String userId, {int weeks = 4}) async {
    final now = DateTime.now();
    final since =
        now.subtract(Duration(days: weeks * 7)).toUtc().toIso8601String();
    final data = await _client
        .from('sessions')
        .select('reps_completed, completed_at')
        .eq('user_id', userId)
        .gte('completed_at', since);

    final buckets = List<int>.filled(weeks, 0);
    for (final row in data as List) {
      final r = row as Map<String, dynamic>;
      final completedAt = DateTime.parse(r['completed_at'] as String).toLocal();
      final ageDays = now.difference(completedAt).inDays;
      if (ageDays < 0 || ageDays >= weeks * 7) continue;
      buckets[weeks - 1 - ageDays ~/ 7] += r['reps_completed'] as int;
    }
    return buckets;
  }

  @override
  Future<({int current, int best})> streakStats(String userId) async {
    final row = await _client
        .from('streaks')
        .select('current_streak, best_streak')
        .eq('user_id', userId)
        .maybeSingle();
    return (
      current: (row?['current_streak'] as int?) ?? 0,
      best: (row?['best_streak'] as int?) ?? 0,
    );
  }

  // ── Streak logic ──────────────────────────────────────────────────────────

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Future<void> _updateStreak(String userId, DateTime sessionDate) async {
    final today = _dateOnly(sessionDate.toLocal());

    // Fetch current streak row
    final existing = await _client
        .from('streaks')
        .select('current_streak, best_streak, last_completed_date')
        .eq('user_id', userId)
        .maybeSingle();

    int current = 0;
    int best = 0;
    DateTime? lastDate;

    if (existing != null) {
      current = (existing['current_streak'] as int?) ?? 0;
      best = (existing['best_streak'] as int?) ?? 0;
      final lastStr = existing['last_completed_date'] as String?;
      if (lastStr != null) lastDate = DateTime.parse(lastStr);
    }

    // Already counted today — nothing to update
    if (lastDate != null && _dateOnly(lastDate) == today) return;

    final yesterday = today.subtract(const Duration(days: 1));
    if (lastDate != null && _dateOnly(lastDate) == yesterday) {
      // Continues the streak
      current += 1;
    } else {
      // Gap or first session ever
      current = 1;
    }

    best = current > best ? current : best;

    await _client.from('streaks').upsert({
      'user_id': userId,
      'current_streak': current,
      'best_streak': best,
      'last_completed_date': today.toIso8601String().substring(0, 10),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
