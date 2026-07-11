import 'package:flutter/foundation.dart';

/// Live progress snapshot for a single squad mate during an active alarm
/// session. Sourced from the `squad_alarms` Supabase table via Realtime.
@immutable
class SquadMateProgress {
  const SquadMateProgress({
    required this.userId,
    required this.displayName,
    required this.repCount,
    required this.requiredReps,
    required this.exerciseType,
  });

  final String userId;
  final String displayName;
  final int repCount;
  final int requiredReps;

  /// e.g. "squats", "push_ups", "jumping_jacks"
  final String exerciseType;

  /// Progress fraction in [0.0, 1.0].
  double get progress =>
      requiredReps > 0 ? (repCount / requiredReps).clamp(0.0, 1.0) : 0.0;

  bool get isComplete => repCount >= requiredReps;

  factory SquadMateProgress.fromRow(Map<String, dynamic> row) {
    final uid = row['user_id'] as String;
    final short = uid.length >= 4 ? uid.substring(0, 4).toUpperCase() : uid;
    return SquadMateProgress(
      userId: uid,
      displayName: (row['display_name'] as String?) ?? short,
      repCount: (row['rep_count'] as num?)?.toInt() ?? 0,
      requiredReps: (row['required_reps'] as num?)?.toInt() ?? 10,
      exerciseType: (row['exercise_type'] as String?) ?? 'squats',
    );
  }

  SquadMateProgress copyWith({
    int? repCount,
    int? requiredReps,
    String? exerciseType,
  }) {
    return SquadMateProgress(
      userId: userId,
      displayName: displayName,
      repCount: repCount ?? this.repCount,
      requiredReps: requiredReps ?? this.requiredReps,
      exerciseType: exerciseType ?? this.exerciseType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SquadMateProgress &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          repCount == other.repCount;

  @override
  int get hashCode => Object.hash(userId, repCount);
}
