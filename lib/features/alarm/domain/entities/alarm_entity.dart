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
  });

  final String id;
  final DateTime scheduledTime;

  /// Number of reps (squats) required to dismiss this alarm
  final int requiredReps;

  final bool isActive;
  final String? label;

  AlarmEntity copyWith({
    String? id,
    DateTime? scheduledTime,
    int? requiredReps,
    bool? isActive,
    String? label,
  }) {
    return AlarmEntity(
      id: id ?? this.id,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      requiredReps: requiredReps ?? this.requiredReps,
      isActive: isActive ?? this.isActive,
      label: label ?? this.label,
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
          label == other.label;

  @override
  int get hashCode => Object.hash(id, scheduledTime, requiredReps, isActive, label);
}
