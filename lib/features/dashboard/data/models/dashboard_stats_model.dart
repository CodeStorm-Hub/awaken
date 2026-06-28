import 'package:awaken/features/dashboard/domain/entities/dashboard_stats_entity.dart';

class DashboardStatsModel {
  const DashboardStatsModel({
    required this.currentStreak,
    required this.bestStreak,
    required this.weeklyReps,
    required this.monthlyCalories,
    this.nextAlarm,
    required this.nextAlarmReps,
  });

  factory DashboardStatsModel.fromJson(Map<String, dynamic> json) {
    return DashboardStatsModel(
      currentStreak: json['current_streak'] as int,
      bestStreak: json['best_streak'] as int,
      weeklyReps: json['weekly_reps'] as int,
      monthlyCalories: json['monthly_calories'] as int,
      nextAlarm: json['next_alarm'] != null
          ? DateTime.parse(json['next_alarm'] as String)
          : null,
      nextAlarmReps: json['next_alarm_reps'] as int? ?? 10,
    );
  }

  final int currentStreak;
  final int bestStreak;
  final int weeklyReps;
  final int monthlyCalories;
  final DateTime? nextAlarm;
  final int nextAlarmReps;

  DashboardStatsEntity toEntity() => DashboardStatsEntity(
        currentStreak: currentStreak,
        bestStreak: bestStreak,
        weeklyReps: weeklyReps,
        monthlyCalories: monthlyCalories,
        nextAlarm: nextAlarm,
        nextAlarmReps: nextAlarmReps,
      );
}
