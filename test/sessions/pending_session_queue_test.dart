import 'package:awaken/features/sessions/data/datasources/pending_session_queue.dart';
import 'package:awaken/features/sessions/domain/entities/session_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const queue = PendingSessionQueue();

  SessionEntity sampleSession({String? id, DateTime? completedAt}) =>
      SessionEntity(
        id: id,
        userId: 'user-1',
        completedAt: completedAt ?? DateTime.utc(2026, 7, 3, 8, 0),
        repsCompleted: 10,
        durationSeconds: 45,
        caloriesBurned: 4,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('enqueue and peek return stored sessions', () async {
    final session = sampleSession();

    await queue.enqueue(session);

    final pending = await queue.peek();
    expect(pending, hasLength(1));
    expect(pending.first.userId, session.userId);
    expect(pending.first.repsCompleted, session.repsCompleted);
  });

  test('enqueue skips duplicate sessions', () async {
    final session = sampleSession();

    await queue.enqueue(session);
    await queue.enqueue(session);

    expect(await queue.peek(), hasLength(1));
  });

  test('remove drops a session by key', () async {
    final session = sampleSession(id: 'session-abc');

    await queue.enqueue(session);
    await queue.remove('session-abc');

    expect(await queue.peek(), isEmpty);
  });

  test('remove uses composite key when id is null', () async {
    final session = sampleSession();

    await queue.enqueue(session);
    await queue.remove(PendingSessionQueue.keyFor(session));

    expect(await queue.peek(), isEmpty);
  });

  test('dequeueAll returns all sessions and clears the queue', () async {
    final first = sampleSession(
      completedAt: DateTime.utc(2026, 7, 3, 8, 0),
    );
    final second = sampleSession(
      completedAt: DateTime.utc(2026, 7, 3, 9, 0),
    );

    await queue.enqueue(first);
    await queue.enqueue(second);

    final dequeued = await queue.dequeueAll();

    expect(dequeued, hasLength(2));
    expect(await queue.peek(), isEmpty);
  });
}
