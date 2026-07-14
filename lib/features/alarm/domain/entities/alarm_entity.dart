import 'package:awaken/features/alarm/domain/entities/alarm_exercise_type.dart';
import 'package:flutter/foundation.dart';

/// The core alarm domain entity — immutable, no framework dependencies.
@immutable
class AlarmEntity {
  const AlarmEntity({
    required this.id,
    required this.scheduledTime,
    required this.requiredReps,
    required this.isActive,
    this.label,
    this.exerciseMode = AlarmExerciseMode.fixed,
    this.exerciseType = AlarmExerciseType.squats,
    this.penaltyMultiplier = 1,
  });

  final String id;
  final DateTime scheduledTime;

  /// Base reps before [penaltyMultiplier] is applied.
  final int requiredReps;

  final bool isActive;
  final String? label;
  final AlarmExerciseMode exerciseMode;
  final AlarmExerciseType? exerciseType;
  final int penaltyMultiplier;

  /// Effective reps for the next wake (base × penalty, min 1).
  int get effectiveRequiredReps =>
      (requiredReps * penaltyMultiplier.clamp(1, 4)).clamp(1, 99);

  AlarmEntity copyWith({
    String? id,
    DateTime? scheduledTime,
    int? requiredReps,
    bool? isActive,
    String? label,
    AlarmExerciseMode? exerciseMode,
    AlarmExerciseType? exerciseType,
    int? penaltyMultiplier,
    bool clearExerciseType = false,
  }) {
    return AlarmEntity(
      id: id ?? this.id,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      requiredReps: requiredReps ?? this.requiredReps,
      isActive: isActive ?? this.isActive,
      label: label ?? this.label,
      exerciseMode: exerciseMode ?? this.exerciseMode,
      exerciseType: clearExerciseType
          ? null
          : (exerciseType ?? this.exerciseType),
      penaltyMultiplier: penaltyMultiplier ?? this.penaltyMultiplier,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          scheduledTime == other.scheduledTime &&
          requiredReps == other.requiredReps &&
          isActive == other.isActive &&
          label == other.label &&
          exerciseMode == other.exerciseMode &&
          exerciseType == other.exerciseType &&
          penaltyMultiplier == other.penaltyMultiplier;

  @override
  int get hashCode => Object.hash(
    id,
    scheduledTime,
    requiredReps,
    isActive,
    label,
    exerciseMode,
    exerciseType,
    penaltyMultiplier,
  );
}
