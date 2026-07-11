/// Dismiss-exercise types for the active alarm.
enum AlarmExerciseType {
  squats,
  pushUps,
  jumpingJacks,
  highKnees,
  sitUps,
}

extension AlarmExerciseTypeX on AlarmExerciseType {
  String get label => switch (this) {
        AlarmExerciseType.squats => 'Squats',
        AlarmExerciseType.pushUps => 'Push-ups',
        AlarmExerciseType.jumpingJacks => 'Jumping Jacks',
        AlarmExerciseType.highKnees => 'High Knees',
        AlarmExerciseType.sitUps => 'Sit-ups',
      };

  String get taxStampLabel => switch (this) {
        AlarmExerciseType.squats => 'SQUATS',
        AlarmExerciseType.pushUps => 'PUSH-UPS',
        AlarmExerciseType.jumpingJacks => 'JUMPING JACKS',
        AlarmExerciseType.highKnees => 'HIGH KNEES',
        AlarmExerciseType.sitUps => 'SIT-UPS',
      };

  String get wireName => name;

  /// Camera-verified exercises available in Tax Roulette / fixed mode.
  bool get isImplemented => switch (this) {
        AlarmExerciseType.squats ||
        AlarmExerciseType.pushUps ||
        AlarmExerciseType.jumpingJacks ||
        AlarmExerciseType.highKnees =>
          true,
        AlarmExerciseType.sitUps => false,
      };

  static AlarmExerciseType? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final value in AlarmExerciseType.values) {
      if (value.name == raw) return value;
    }
    return null;
  }

  static const implemented = <AlarmExerciseType>[
    AlarmExerciseType.squats,
    AlarmExerciseType.pushUps,
    AlarmExerciseType.jumpingJacks,
    AlarmExerciseType.highKnees,
  ];
}

/// How the wake-up tax exercise is chosen.
enum AlarmExerciseMode {
  fixed,
  roulette,
}

extension AlarmExerciseModeX on AlarmExerciseMode {
  String get wireName => name;

  static AlarmExerciseMode parse(String? raw) {
    if (raw == 'roulette') return AlarmExerciseMode.roulette;
    return AlarmExerciseMode.fixed;
  }
}
