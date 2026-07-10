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
}
