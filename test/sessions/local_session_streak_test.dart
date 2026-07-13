import 'package:awaken/features/sessions/data/repositories/local_session_repository.dart';
import 'package:awaken/features/sessions/domain/entities/session_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const repo = LocalSessionRepository();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('guest sessions persist and contribute to local streak', () async {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    await repo.recordSession(
      SessionEntity(
        userId: SessionEntity.localGuestUserId,
        completedAt: yesterday,
        repsCompleted: 10,
        durationSeconds: 40,
        caloriesBurned: 4,
      ),
    );
    await repo.recordSession(
      SessionEntity(
        userId: SessionEntity.localGuestUserId,
        completedAt: today,
        repsCompleted: 12,
        durationSeconds: 50,
        caloriesBurned: 4,
      ),
    );

    final streak = await repo.streakStats(SessionEntity.localGuestUserId);
    expect(streak.current, 2);
    expect(streak.best, 2);

    final weekly = await repo.weeklyReps(SessionEntity.localGuestUserId);
    expect(weekly, 22);
  });

  test('weeklyRepsTrend buckets reps per week, oldest first', () async {
    const userId = SessionEntity.localGuestUserId;
    final now = DateTime.now();

    Future<void> record(int daysAgo, int reps) => repo.recordSession(
          SessionEntity(
            userId: userId,
            completedAt: now.subtract(Duration(days: daysAgo)),
            repsCompleted: reps,
            durationSeconds: 40,
            caloriesBurned: 4,
          ),
        );

    await record(0, 10); // current week
    await record(3, 5); // current week
    await record(8, 20); // 1 week ago
    await record(15, 30); // 2 weeks ago
    await record(29, 99); // outside the 4-week window — ignored

    final trend = await repo.weeklyRepsTrend(userId);
    expect(trend, [0, 30, 20, 15]);
  });

  test('weeklyRepsTrend ignores other users and returns zeros when empty',
      () async {
    const userId = SessionEntity.localGuestUserId;

    expect(await repo.weeklyRepsTrend(userId), [0, 0, 0, 0]);

    await repo.recordSession(
      SessionEntity(
        userId: 'someone-else',
        completedAt: DateTime.now(),
        repsCompleted: 50,
        durationSeconds: 40,
        caloriesBurned: 4,
      ),
    );
    expect(await repo.weeklyRepsTrend(userId), [0, 0, 0, 0]);
  });
}
