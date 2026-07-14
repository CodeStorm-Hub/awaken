import 'package:flutter/foundation.dart';

@immutable
class SessionEntity {
  const SessionEntity({
    this.id,
    required this.userId,
    this.alarmId,
    required this.completedAt,
    required this.repsCompleted,
    required this.durationSeconds,
    required this.caloriesBurned,
  });

  /// Stable user id for workouts completed while signed out (local-only).
  static const String localGuestUserId = 'local';

  final String? id; // UUID assigned by Supabase; null before save
  final String userId;
  final String? alarmId;
  final DateTime completedAt;
  final int repsCompleted;
  final int durationSeconds;
  final int caloriesBurned;

  static int estimateCalories(int reps) => (reps * 0.35).round().clamp(1, 999);

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'alarm_id': alarmId,
    'completed_at': completedAt.toIso8601String(),
    'reps_completed': repsCompleted,
    'duration_seconds': durationSeconds,
    'calories_burned': caloriesBurned,
  };

  factory SessionEntity.fromJson(Map<String, dynamic> json) => SessionEntity(
    id: json['id'] as String?,
    userId: json['user_id'] as String,
    alarmId: json['alarm_id'] as String?,
    completedAt: DateTime.parse(json['completed_at'] as String),
    repsCompleted: json['reps_completed'] as int,
    durationSeconds: json['duration_seconds'] as int,
    caloriesBurned: json['calories_burned'] as int,
  );
}
