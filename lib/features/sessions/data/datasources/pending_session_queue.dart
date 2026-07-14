import 'dart:convert';
import 'dart:math' as math;

import 'package:awaken/features/sessions/domain/entities/session_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-backed queue of sessions that failed to sync remotely.
///
/// Failed flush attempts record exponential backoff metadata so resume/sign-in
/// flushes do not hammer an unreachable Supabase instance.
class PendingSessionQueue {
  const PendingSessionQueue();

  static const String _queueKey = 'awaken_pending_session_sync_queue';
  static const String _metaKey = 'awaken_pending_session_sync_meta';

  static const int _maxBackoffSeconds = 30 * 60;

  /// Stable key for deduplication and [remove].
  static String keyFor(SessionEntity session) =>
      session.id ??
      '${session.userId}_${session.completedAt.toIso8601String()}';

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

  Future<Map<String, dynamic>> _readMeta() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_metaKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return {};
    return decoded;
  }

  Future<void> _writeMeta(Map<String, dynamic> meta) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_metaKey, jsonEncode(meta));
  }

  Future<void> enqueue(SessionEntity session) async {
    final sessions = await _readAll();
    final id = keyFor(session);
    if (sessions.any((s) => keyFor(s) == id)) return;
    sessions.add(session);
    await _writeAll(sessions);
  }

  Future<List<SessionEntity>> peek() => _readAll();

  /// Sessions whose backoff window has elapsed (or never failed).
  Future<List<SessionEntity>> peekDue({DateTime? now}) async {
    final at = now ?? DateTime.now();
    final sessions = await _readAll();
    final meta = await _readMeta();
    return sessions.where((session) {
      final entry = meta[keyFor(session)];
      if (entry is! Map) return true;
      final nextRaw = entry['nextRetryAt'];
      if (nextRaw is! String || nextRaw.isEmpty) return true;
      final next = DateTime.tryParse(nextRaw);
      if (next == null) return true;
      return !next.isAfter(at);
    }).toList();
  }

  Future<void> markAttemptFailed(SessionEntity session, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final id = keyFor(session);
    final meta = await _readMeta();
    final existing = meta[id];
    final attempts = existing is Map && existing['attempts'] is int
        ? (existing['attempts'] as int) + 1
        : 1;
    final delaySeconds = math.min(
      _maxBackoffSeconds,
      30 * math.pow(2, attempts - 1).toInt(),
    );
    meta[id] = {
      'attempts': attempts,
      'nextRetryAt': at.add(Duration(seconds: delaySeconds)).toIso8601String(),
    };
    await _writeMeta(meta);
  }

  Future<List<SessionEntity>> dequeueAll() async {
    final sessions = await _readAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_queueKey);
    await prefs.remove(_metaKey);
    return sessions;
  }

  Future<void> remove(String sessionId) async {
    final sessions = await _readAll();
    sessions.removeWhere((s) => keyFor(s) == sessionId);
    await _writeAll(sessions);
    final meta = await _readMeta();
    meta.remove(sessionId);
    await _writeMeta(meta);
  }
}
