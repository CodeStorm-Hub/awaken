import 'package:awaken/features/sessions/data/datasources/pending_session_queue.dart';
import 'package:awaken/features/sessions/data/repositories/composite_session_repository.dart';
import 'package:awaken/features/sessions/data/repositories/local_session_repository.dart';
import 'package:awaken/features/sessions/data/repositories/supabase_session_repository.dart';
import 'package:awaken/features/sessions/domain/entities/session_entity.dart';
import 'package:awaken/features/sessions/domain/services/session_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeRemoteSessionRepository extends SupabaseSessionRepository {
  FakeRemoteSessionRepository({this.failNext = 0});

  int failNext;
  final List<SessionEntity> recorded = [];

  @override
  Future<void> recordSession(SessionEntity session) async {
    if (failNext > 0) {
      failNext--;
      throw Exception('network unavailable');
    }
    recorded.add(session);
  }

  @override
  Future<int> weeklyReps(String userId, {int days = 7}) async => 0;

  @override
  Future<int> monthlyCalories(String userId, {int days = 30}) async => 0;

  @override
  Future<({int current, int best})> streakStats(String userId) async =>
      (current: 0, best: 0);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const queue = PendingSessionQueue();
  const local = LocalSessionRepository();

  SessionEntity sampleSession() => SessionEntity(
        userId: 'user-1',
        completedAt: DateTime.utc(2026, 7, 3, 8, 0),
        repsCompleted: 12,
        durationSeconds: 60,
        caloriesBurned: 4,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('remote failure enqueues session for later sync', () async {
    final remote = FakeRemoteSessionRepository(failNext: 1);
    final repository = CompositeSessionRepository(
      remote: remote,
      local: local,
      queue: queue,
    );
    final session = sampleSession();

    await repository.recordSession(session);

    expect(remote.recorded, isEmpty);
    final pending = await queue.peek();
    expect(pending, hasLength(1));
    expect(pending.first.repsCompleted, session.repsCompleted);
  });

  test('flushPendingSessions syncs queued sessions when remote succeeds', () async {
    final remote = FakeRemoteSessionRepository();
    final session = sampleSession();

    await queue.enqueue(session);

    final syncService = SessionSyncService(
      queue: queue,
      remote: remote,
    );

    await syncService.flushPendingSessions();

    expect(remote.recorded, hasLength(1));
    expect(remote.recorded.first.userId, session.userId);
    expect(await queue.peek(), isEmpty);
  });

  test('flushPendingSessions keeps failed sessions in the queue', () async {
    final remote = FakeRemoteSessionRepository(failNext: 1);
    final session = sampleSession();

    await queue.enqueue(session);

    final syncService = SessionSyncService(
      queue: queue,
      remote: remote,
    );

    await syncService.flushPendingSessions();

    expect(remote.recorded, isEmpty);
    expect(await queue.peek(), hasLength(1));
  });

  test('offline to online flow syncs after remote recovery', () async {
    final remote = FakeRemoteSessionRepository(failNext: 1);
    final repository = CompositeSessionRepository(
      remote: remote,
      local: local,
      queue: queue,
    );
    final syncService = SessionSyncService(
      queue: queue,
      remote: remote,
    );
    final session = sampleSession();

    await repository.recordSession(session);
    expect(await queue.peek(), hasLength(1));

    await syncService.flushPendingSessions();

    expect(remote.recorded, hasLength(1));
    expect(await queue.peek(), isEmpty);
  });
}
