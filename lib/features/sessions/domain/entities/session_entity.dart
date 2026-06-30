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

  final String? id; // UUID assigned by Supabase; null before save
  final String userId;
  final String? alarmId;
  final DateTime completedAt;
  final int repsCompleted;
  final int durationSeconds;
  final int caloriesBurned;

  static int estimateCalories(int reps) => (reps * 0.35).round().clamp(1, 999);
}
