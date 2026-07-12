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

/// Exponential Moving Average filter to smooth micro-jitter of raw coordinates or metrics.
class DoubleEMAFilter {
  DoubleEMAFilter({required this.alpha});
  final double alpha;
  double? _currentValue;

  double filter(double newValue) {
    if (_currentValue == null) {
      _currentValue = newValue;
    } else {
      _currentValue = (_currentValue! * (1.0 - alpha)) + (newValue * alpha);
    }
    return _currentValue!;
  }

  void reset() {
    _currentValue = null;
  }
}
