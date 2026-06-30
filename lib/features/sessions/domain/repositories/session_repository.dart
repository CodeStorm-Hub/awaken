import 'package:awaken/features/sessions/domain/entities/session_entity.dart';

abstract class SessionRepository {
  Future<void> recordSession(SessionEntity session);

  /// Returns sum of repsCompleted from sessions in the last [days] days.
  Future<int> weeklyReps(String userId, {int days = 7});

  /// Returns sum of caloriesBurned from sessions in the last [days] days.
  Future<int> monthlyCalories(String userId, {int days = 30});
}
