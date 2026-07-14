/// Dismiss-exercise types for the active alarm.
enum AlarmExerciseType {
  squats,
  pushUps,
  jumpingJacks,
  highKnees,
}

extension AlarmExerciseTypeX on AlarmExerciseType {
  String get label => switch (this) {
        AlarmExerciseType.squats => 'Squats',
        AlarmExerciseType.pushUps => 'Push-ups',
        AlarmExerciseType.jumpingJacks => 'Jumping Jacks',
        AlarmExerciseType.highKnees => 'High Knees',
      };

  String get taxStampLabel => switch (this) {
        AlarmExerciseType.squats => 'SQUATS',
        AlarmExerciseType.pushUps => 'PUSH-UPS',
        AlarmExerciseType.jumpingJacks => 'JUMPING JACKS',
        AlarmExerciseType.highKnees => 'HIGH KNEES',
      };

  String get wireName => name;

  /// Camera-verified exercises available in Tax Roulette / fixed mode.
  /// Every current value has a counter; kept as a defensive check for
  /// [resolveSessionExercise] in case a future value ships before its
  /// counter does.
  bool get isImplemented => true;

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
