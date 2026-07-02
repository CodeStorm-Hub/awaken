import 'dart:convert';

import 'package:awaken/features/sessions/domain/entities/session_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-backed queue of sessions that failed to sync remotely.
class PendingSessionQueue {
  const PendingSessionQueue();

  static const String _queueKey = 'awaken_pending_session_sync_queue';

  /// Stable key for deduplication and [remove].
  static String keyFor(SessionEntity session) =>
      session.id ?? '${session.userId}_${session.completedAt.toIso8601String()}';

  Future<List<SessionEntity>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_queueKey) ?? [];
    return jsonList
        .map(
          (jsonStr) => SessionEntity.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> _writeAll(List<SessionEntity> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_queueKey, jsonList);
  }

  Future<void> enqueue(SessionEntity session) async {
    final sessions = await _readAll();
    final id = keyFor(session);
    if (sessions.any((s) => keyFor(s) == id)) return;
    sessions.add(session);
    await _writeAll(sessions);
  }

  Future<List<SessionEntity>> peek() => _readAll();

  Future<List<SessionEntity>> dequeueAll() async {
    final sessions = await _readAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
    return sessions;
  }

  Future<void> remove(String sessionId) async {
    final sessions = await _readAll();
    sessions.removeWhere((s) => keyFor(s) == sessionId);
    await _writeAll(sessions);
  }
}
