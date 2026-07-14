import 'package:awaken/features/sessions/data/datasources/pending_session_queue.dart';
import 'package:awaken/features/sessions/data/repositories/supabase_session_repository.dart';

/// Retries syncing sessions that were saved locally while offline.
class SessionSyncService {
  const SessionSyncService({required this.queue, required this.remote});

  final PendingSessionQueue queue;
  final SupabaseSessionRepository remote;

  Future<void> flushPendingSessions() async {
    final pending = await queue.peekDue();
    for (final session in pending) {
      try {
        await remote.recordSession(session);
        await queue.remove(PendingSessionQueue.keyFor(session));
      } catch (_) {
        // Leave in queue with exponential backoff for the next flush.
        await queue.markAttemptFailed(session);
      }
    }
  }
}
