import 'package:flutter/foundation.dart';

/// Aggregated stats shown on the dashboard — immutable value object.
@immutable
class DashboardStatsEntity {
  const DashboardStatsEntity({
    required this.currentStreak,
    required this.bestStreak,
    required this.weeklyReps,
    required this.monthlyCalories,
    required this.nextAlarm,
    required this.nextAlarmReps,
  });

  final int currentStreak;
  final int bestStreak;
  final int weeklyReps;
  final int monthlyCalories;

  /// The next scheduled alarm time, null if no alarm is set
  final DateTime? nextAlarm;
  final int nextAlarmReps;

  /// Streak progress as a 0.0–1.0 ratio (current / best)
  double get streakProgress =>
      bestStreak == 0 ? 0 : (currentStreak / bestStreak).clamp(0.0, 1.0);

  static const DashboardStatsEntity empty = DashboardStatsEntity(
    currentStreak: 0,
    bestStreak: 0,
    weeklyReps: 0,
    monthlyCalories: 0,
    nextAlarm: null,
    nextAlarmReps: 10,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardStatsEntity &&
          runtimeType == other.runtimeType &&
          currentStreak == other.currentStreak &&
          bestStreak == other.bestStreak &&
          weeklyReps == other.weeklyReps &&
          monthlyCalories == other.monthlyCalories &&
          nextAlarm == other.nextAlarm &&
          nextAlarmReps == other.nextAlarmReps;

  @override
  int get hashCode => Object.hash(
        currentStreak,
        bestStreak,
        weeklyReps,
        monthlyCalories,
        nextAlarm,
        nextAlarmReps,
      );
}
