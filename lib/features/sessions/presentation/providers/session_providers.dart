import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:awaken/features/sessions/data/datasources/pending_session_queue.dart';
import 'package:awaken/features/sessions/data/repositories/composite_session_repository.dart';
import 'package:awaken/features/sessions/data/repositories/local_session_repository.dart';
import 'package:awaken/features/sessions/data/repositories/supabase_session_repository.dart';
import 'package:awaken/features/sessions/domain/repositories/session_repository.dart';
import 'package:awaken/features/sessions/domain/services/session_sync_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pendingSessionQueueProvider = Provider<PendingSessionQueue>((ref) {
  return const PendingSessionQueue();
});

final sessionSyncServiceProvider = Provider<SessionSyncService>((ref) {
  return SessionSyncService(
    queue: ref.watch(pendingSessionQueueProvider),
    remote: const SupabaseSessionRepository(),
  );
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return CompositeSessionRepository(
    remote: const SupabaseSessionRepository(),
    local: const LocalSessionRepository(),
    queue: ref.watch(pendingSessionQueueProvider),
  );
});

/// Flushes the pending session queue whenever the user signs in.
final sessionSyncOnSignInProvider = Provider<void>((ref) {
  ref.listen(authStateProvider, (previous, next) {
    next.whenData((state) {
      if (state.session != null) {
        ref.read(sessionSyncServiceProvider).flushPendingSessions();
      }
    });
  });
});
