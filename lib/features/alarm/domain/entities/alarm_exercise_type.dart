/// Dismiss-exercise types for the active alarm (squats today; more later).
enum AlarmExerciseType {
  squats,
  pushUps,
  sitUps,
}

extension AlarmExerciseTypeX on AlarmExerciseType {
  String get label => switch (this) {
        AlarmExerciseType.squats => 'Squats',
        AlarmExerciseType.pushUps => 'Push-ups',
        AlarmExerciseType.sitUps => 'Sit-ups',
      };

  /// Only squats are camera-verified today; others are reserved for Phase 6+.
  bool get isImplemented => this == AlarmExerciseType.squats;
}
