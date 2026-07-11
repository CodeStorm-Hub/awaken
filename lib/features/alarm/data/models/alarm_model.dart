import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_exercise_type.dart';

/// Data-layer representation of an alarm — serialises to/from JSON / Supabase.
class AlarmModel {
  const AlarmModel({
    required this.id,
    required this.scheduledTime,
    required this.requiredReps,
    required this.isActive,
    this.label,
    this.exerciseMode = AlarmExerciseMode.fixed,
    this.exerciseType = AlarmExerciseType.squats,
    this.penaltyMultiplier = 1,
  });

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'] as String,
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      requiredReps: json['required_reps'] as int,
      isActive: json['is_active'] as bool,
      label: json['label'] as String?,
      exerciseMode: AlarmExerciseModeX.parse(json['exercise_mode'] as String?),
      exerciseType: AlarmExerciseTypeX.tryParse(json['exercise_type'] as String?) ??
          AlarmExerciseType.squats,
      penaltyMultiplier: (json['penalty_multiplier'] as int?) ?? 1,
    );
  }

  factory AlarmModel.fromEntity(AlarmEntity entity) => AlarmModel(
        id: entity.id,
        scheduledTime: entity.scheduledTime,
        requiredReps: entity.requiredReps,
        isActive: entity.isActive,
        label: entity.label,
        exerciseMode: entity.exerciseMode,
        exerciseType: entity.exerciseType ?? AlarmExerciseType.squats,
        penaltyMultiplier: entity.penaltyMultiplier,
      );

  final String id;
  final DateTime scheduledTime;
  final int requiredReps;
  final bool isActive;
  final String? label;
  final AlarmExerciseMode exerciseMode;
  final AlarmExerciseType exerciseType;
  final int penaltyMultiplier;

  Map<String, dynamic> toJson() => {
        'id': id,
        'scheduled_time': scheduledTime.toIso8601String(),
        'required_reps': requiredReps,
        'is_active': isActive,
        if (label != null) 'label': label,
        'exercise_mode': exerciseMode.wireName,
        'exercise_type': exerciseType.wireName,
        'penalty_multiplier': penaltyMultiplier,
      };

  Map<String, dynamic> toSupabaseJson(String userId) => {
        'id': id,
        'user_id': userId,
        'scheduled_time': scheduledTime.toUtc().toIso8601String(),
        'required_reps': requiredReps,
        'is_active': isActive,
        if (label != null) 'label': label,
        'exercise_mode': exerciseMode.wireName,
        'exercise_type': exerciseType.wireName,
        'penalty_multiplier': penaltyMultiplier,
      };

  AlarmEntity toEntity() => AlarmEntity(
        id: id,
        scheduledTime: scheduledTime,
        requiredReps: requiredReps,
        isActive: isActive,
        label: label,
        exerciseMode: exerciseMode,
        exerciseType: exerciseType,
        penaltyMultiplier: penaltyMultiplier,
      );
}
