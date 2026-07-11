import 'package:awaken/features/alarm/domain/entities/alarm_exercise_type.dart';
import 'package:awaken/features/alarm/domain/services/exercise_counter.dart';
import 'package:awaken/features/alarm/domain/services/high_knees_counter_service.dart';
import 'package:awaken/features/alarm/domain/services/jumping_jack_counter_service.dart';
import 'package:awaken/features/alarm/domain/services/push_up_counter_service.dart';
import 'package:awaken/features/alarm/domain/services/squat_counter_service.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Adapts [SquatCounterService] to the shared [ExerciseCounter] interface.
class SquatExerciseCounter implements ExerciseCounter {
  SquatExerciseCounter([SquatCounterService? inner])
      : _inner = inner ?? SquatCounterService();

  final SquatCounterService _inner;

  SquatCounterService get inner => _inner;

  @override
  bool get isCalibrated => _inner.isCalibrated;

  @override
  bool get isInActivePhase => _inner.isInSquat;

  @override
  void reset() => _inner.reset();

  @override
  ExerciseProcessResult processPose(Pose pose) {
    final result = _inner.processPose(pose);
    return ExerciseProcessResult(
      repCompleted: result.repCompleted,
      badForm: result.badForm,
      depthRatio: result.depthRatio,
      hasPose: result.hasPose,
      cue: result.badForm
          ? 'GO LOWER / KEEP SHOULDERS LEVEL'
          : result.repCompleted
              ? 'PERFECT REP'
              : null,
    );
  }
}

/// Picks the concrete counter for the resolved wake-up tax exercise.
class ExerciseCounterRouter {
  ExerciseCounterRouter({required AlarmExerciseType type})
      : counter = _create(type),
        exerciseType = type;

  final AlarmExerciseType exerciseType;
  final ExerciseCounter counter;

  static ExerciseCounter _create(AlarmExerciseType type) {
    return switch (type) {
      AlarmExerciseType.squats => SquatExerciseCounter(),
      AlarmExerciseType.pushUps => PushUpCounterService(),
      AlarmExerciseType.jumpingJacks => JumpingJackCounterService(),
      AlarmExerciseType.highKnees => HighKneesCounterService(),
      AlarmExerciseType.sitUps => SquatExerciseCounter(), // deferred
    };
  }

  void reset() => counter.reset();
}

/// Stable daily roulette pick: same alarm + local date → same exercise.
AlarmExerciseType pickRouletteExercise({
  required String alarmId,
  DateTime? now,
}) {
  final day = now ?? DateTime.now();
  final seed = Object.hash(alarmId, day.year, day.month, day.day);
  const options = AlarmExerciseTypeX.implemented;
  return options[seed.abs() % options.length];
}

AlarmExerciseType resolveSessionExercise({
  required AlarmExerciseMode mode,
  AlarmExerciseType? fixedType,
  required String alarmId,
  DateTime? now,
}) {
  if (mode == AlarmExerciseMode.roulette) {
    return pickRouletteExercise(alarmId: alarmId, now: now);
  }
  final type = fixedType ?? AlarmExerciseType.squats;
  return type.isImplemented ? type : AlarmExerciseType.squats;
}
