import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';

/// Data-layer representation of an alarm — serialises to/from Supabase JSON.
class AlarmModel {
  const AlarmModel({
    required this.id,
    required this.scheduledTime,
    required this.requiredReps,
    required this.isActive,
    this.label,
  });

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'] as String,
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      requiredReps: json['required_reps'] as int,
      isActive: json['is_active'] as bool,
      label: json['label'] as String?,
    );
  }

  factory AlarmModel.fromEntity(AlarmEntity entity) => AlarmModel(
        id: entity.id,
        scheduledTime: entity.scheduledTime,
        requiredReps: entity.requiredReps,
        isActive: entity.isActive,
        label: entity.label,
      );

  final String id;
  final DateTime scheduledTime;
  final int requiredReps;
  final bool isActive;
  final String? label;

  Map<String, dynamic> toJson() => {
        'id': id,
        'scheduled_time': scheduledTime.toIso8601String(),
        'required_reps': requiredReps,
        'is_active': isActive,
        if (label != null) 'label': label,
      };

  /// Supabase upsert payload — includes user_id for RLS.
  Map<String, dynamic> toSupabaseJson(String userId) => {
        'id': id,
        'user_id': userId,
        'scheduled_time': scheduledTime.toUtc().toIso8601String(),
        'required_reps': requiredReps,
        'is_active': isActive,
        if (label != null) 'label': label,
      };

  AlarmEntity toEntity() => AlarmEntity(
        id: id,
        scheduledTime: scheduledTime,
        requiredReps: requiredReps,
        isActive: isActive,
        label: label,
      );
}
