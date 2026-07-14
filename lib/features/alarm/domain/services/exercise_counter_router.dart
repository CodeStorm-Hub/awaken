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
  ExerciseProcessResult processPose(Pose pose, DateTime timestamp) {
    // Squat detection has no elapsed-time-gated bad-form window, so the
    // frame timestamp isn't needed here — [SquatCounterService] keeps its
    // own (Pose)-only signature.
    final result = _inner.processPose(pose);
    return ExerciseProcessResult(
      repCompleted: result.repCompleted,
      badForm: result.badForm,
      depthRatio: result.depthRatio,
      hasPose: result.hasPose,
      cue: result.cue ??
          (result.badForm
              ? 'GO LOWER / KEEP SHOULDERS LEVEL'
              : result.repCompleted
                  ? 'PERFECT REP'
                  : null),
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
    };
  }

  void reset() => counter.reset();
}

/// FNV-1a over a string, deterministic across Dart runtimes/restarts —
/// unlike [Object.hash]/[String.hashCode], which are salted per isolate for
/// hash-flooding protection and are NOT stable across app restarts.
int _stableHash(String input) {
  var hash = 0x811c9dc5; // FNV-1a offset basis
  for (final codeUnit in input.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF; // FNV prime, masked to 32-bit
  }
  return hash;
}

/// Stable daily roulette pick: same alarm + local date → same exercise,
/// including across app restarts (see [_stableHash]).
AlarmExerciseType pickRouletteExercise({
  required String alarmId,
  DateTime? now,
}) {
  final day = now ?? DateTime.now();
  final seed = _stableHash('$alarmId|${day.year}|${day.month}|${day.day}');
  const options = AlarmExerciseTypeX.implemented;
  return options[seed % options.length];
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
