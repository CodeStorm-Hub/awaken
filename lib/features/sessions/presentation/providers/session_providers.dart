import 'package:awaken/features/alarm/domain/services/alarm_cloud_migration.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:awaken/features/sessions/data/datasources/pending_session_queue.dart';
import 'package:awaken/features/sessions/data/repositories/composite_session_repository.dart';
import 'package:awaken/features/sessions/data/repositories/local_session_repository.dart';
import 'package:awaken/features/sessions/data/repositories/supabase_session_repository.dart';
import 'package:awaken/features/sessions/domain/entities/session_entity.dart';
import 'package:awaken/features/sessions/domain/repositories/session_repository.dart';
import 'package:awaken/features/sessions/domain/services/session_sync_service.dart';
import 'package:awaken/features/territory/domain/services/territory_cloud_migration.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pendingSessionQueueProvider = Provider<PendingSessionQueue>((ref) {
  return const PendingSessionQueue();
});

final localSessionRepositoryProvider = Provider<LocalSessionRepository>((ref) {
  return const LocalSessionRepository();
});

final sessionSyncServiceProvider = Provider<SessionSyncService>((ref) {
  return SessionSyncService(
    queue: ref.watch(pendingSessionQueueProvider),
    remote: const SupabaseSessionRepository(),
  );
});

/// Local-only when signed out; local-first + remote when signed in.
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final signedIn = ref.watch(isSignedInProvider);
  final local = ref.watch(localSessionRepositoryProvider);
  if (!signedIn) return local;
  return CompositeSessionRepository(
    remote: const SupabaseSessionRepository(),
    local: local,
    queue: ref.watch(pendingSessionQueueProvider),
  );
});

/// Flushes pending sessions, migrates guest workouts, and uploads local alarms
/// whenever the user signs in.
final sessionSyncOnSignInProvider = Provider<void>((ref) {
  ref.listen(authStateProvider, (previous, next) {
    next.whenData((state) async {
      final session = state.session;
      if (session == null) return;

      await ref.read(sessionSyncServiceProvider).flushPendingSessions();

      try {
        await const AlarmCloudMigration().migrateLocalAlarmsToCloud();
      } catch (_) {}

      try {
        await TerritoryCloudMigration().migrateLocalTerritoriesToCloud();
      } catch (_) {}

      final local = ref.read(localSessionRepositoryProvider);
      final guestSessions = (await local.getAllSessions())
          .where((s) => s.userId == SessionEntity.localGuestUserId)
          .toList();
      const remote = SupabaseSessionRepository();
      for (final guest in guestSessions) {
        try {
          await remote.recordSession(
            SessionEntity(
              userId: session.user.id,
              alarmId: guest.alarmId,
              completedAt: guest.completedAt,
              repsCompleted: guest.repsCompleted,
              durationSeconds: guest.durationSeconds,
              caloriesBurned: guest.caloriesBurned,
            ),
          );
        } catch (_) {
          await ref.read(pendingSessionQueueProvider).enqueue(
                SessionEntity(
                  userId: session.user.id,
                  alarmId: guest.alarmId,
                  completedAt: guest.completedAt,
                  repsCompleted: guest.repsCompleted,
                  durationSeconds: guest.durationSeconds,
                  caloriesBurned: guest.caloriesBurned,
                ),
              );
        }
      }
    });
  });
});
