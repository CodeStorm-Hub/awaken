import 'package:awaken/features/sessions/domain/entities/session_entity.dart';

abstract class SessionRepository {
  Future<void> recordSession(SessionEntity session);

  /// Returns sum of repsCompleted from sessions in the last [days] days.
  Future<int> weeklyReps(String userId, {int days = 7});

  /// Returns sum of caloriesBurned from sessions in the last [days] days.
  Future<int> monthlyCalories(String userId, {int days = 30});

  /// Consecutive calendar-day streak ending today (or yesterday if none today).
  Future<({int current, int best})> streakStats(String userId);

  /// Reps summed per 7-day bucket over the last [weeks] weeks, oldest first.
  /// The final element is the current (possibly partial) week.
  Future<List<int>> weeklyRepsTrend(String userId, {int weeks = 4});
}
