import 'dart:convert';
import 'package:awaken/features/sessions/domain/entities/session_entity.dart';
import 'package:awaken/features/sessions/domain/repositories/session_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalSessionRepository implements SessionRepository {
  const LocalSessionRepository();

  static const String _sessionsKey = 'awaken_local_sessions';

  Future<List<SessionEntity>> _getSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_sessionsKey) ?? [];
    return jsonList
        .map(
          (jsonStr) => SessionEntity.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> _saveSessions(List<SessionEntity> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_sessionsKey, jsonList);
  }

  @override
  Future<void> recordSession(SessionEntity session) async {
    final sessions = await _getSessions();
    sessions.add(session);
    await _saveSessions(sessions);
  }

  @override
  Future<int> weeklyReps(String userId, {int days = 7}) async {
    final sessions = await _getSessions();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    int total = 0;
    for (final s in sessions) {
      if (s.userId == userId && s.completedAt.isAfter(cutoff)) {
        total += s.repsCompleted;
      }
    }
    return total;
  }

  @override
  Future<int> monthlyCalories(String userId, {int days = 30}) async {
    final sessions = await _getSessions();
    final cutoff = DateTime.now().subtract(Duration(days: days));
    int total = 0;
    for (final s in sessions) {
      if (s.userId == userId && s.completedAt.isAfter(cutoff)) {
        total += s.caloriesBurned;
      }
    }
    return total;
  }

  @override
  Future<List<int>> weeklyRepsTrend(String userId, {int weeks = 4}) async {
    final sessions = await _getSessions();
    final now = DateTime.now();
    final buckets = List<int>.filled(weeks, 0);
    for (final s in sessions) {
      if (s.userId != userId) continue;
      final ageDays = now.difference(s.completedAt).inDays;
      if (ageDays < 0 || ageDays >= weeks * 7) continue;
      buckets[weeks - 1 - ageDays ~/ 7] += s.repsCompleted;
    }
    return buckets;
  }

  @override
  Future<({int current, int best})> streakStats(String userId) async {
    final sessions = await _getSessions();
    final days =
        sessions
            .where((s) => s.userId == userId)
            .map(
              (s) => DateTime(
                s.completedAt.year,
                s.completedAt.month,
                s.completedAt.day,
              ),
            )
            .toSet()
            .toList()
          ..sort();

    if (days.isEmpty) return (current: 0, best: 0);

    var best = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      final gap = days[i].difference(days[i - 1]).inDays;
      if (gap == 1) {
        run++;
        if (run > best) best = run;
      } else if (gap > 1) {
        run = 1;
      }
    }

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterday = todayDate.subtract(const Duration(days: 1));
    final last = days.last;

    var current = 0;
    if (last == todayDate || last == yesterday) {
      current = 1;
      for (var i = days.length - 1; i > 0; i--) {
        if (days[i].difference(days[i - 1]).inDays == 1) {
          current++;
        } else {
          break;
        }
      }
    }

    return (current: current, best: best);
  }

  /// All locally stored sessions (used when migrating guest workouts on sign-in).
  Future<List<SessionEntity>> getAllSessions() => _getSessions();
}
