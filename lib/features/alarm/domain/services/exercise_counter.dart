import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Shared result from any wake-up tax exercise counter.
class ExerciseProcessResult {
  const ExerciseProcessResult({
    this.repCompleted = false,
    this.badForm = false,
    this.depthRatio,
    this.hasPose = false,
    this.cue,
  });

  final bool repCompleted;
  final bool badForm;
  final double? depthRatio;
  final bool hasPose;

  /// Optional coaching cue for the instruction bar.
  final String? cue;
}

/// Counts camera-verified reps for one exercise type.
abstract class ExerciseCounter {
  bool get isCalibrated;
  bool get isInActivePhase;

  ExerciseProcessResult processPose(Pose pose);

  void reset();
}
