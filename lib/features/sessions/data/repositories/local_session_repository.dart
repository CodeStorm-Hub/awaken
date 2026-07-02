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
    return jsonList.map((jsonStr) => SessionEntity.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>)).toList();
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
}
