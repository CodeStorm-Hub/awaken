import 'package:awaken/features/sessions/data/datasources/pending_session_queue.dart';
import 'package:awaken/features/sessions/data/repositories/local_session_repository.dart';
import 'package:awaken/features/sessions/data/repositories/supabase_session_repository.dart';
import 'package:awaken/features/sessions/domain/entities/session_entity.dart';
import 'package:awaken/features/sessions/domain/repositories/session_repository.dart';

class CompositeSessionRepository implements SessionRepository {
  const CompositeSessionRepository({
    required this.remote,
    required this.local,
    required this.queue,
  });

  final SupabaseSessionRepository remote;
  final LocalSessionRepository local;
  final PendingSessionQueue queue;

  @override
  Future<void> recordSession(SessionEntity session) async {
    // Always save locally first so we never lose it
    await local.recordSession(session);

    // Attempt remote save
    try {
      await remote.recordSession(session);
    } catch (_) {
      await queue.enqueue(session);
    }
  }

  @override
  Future<int> weeklyReps(String userId, {int days = 7}) async {
    try {
      return await remote.weeklyReps(userId, days: days);
    } catch (_) {
      return await local.weeklyReps(userId, days: days);
    }
  }

  @override
  Future<int> monthlyCalories(String userId, {int days = 30}) async {
    try {
      return await remote.monthlyCalories(userId, days: days);
    } catch (_) {
      return await local.monthlyCalories(userId, days: days);
    }
  }
}
