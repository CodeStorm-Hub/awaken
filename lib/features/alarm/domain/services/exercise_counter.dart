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

  /// [timestamp] is the capture time of this frame (not processing time) —
  /// counters that gate on elapsed duration (e.g. bad-form debounce windows)
  /// must compare against this rather than [DateTime.now], so behavior stays
  /// correct under variable inference latency and is deterministically
  /// testable with synthetic timestamps.
  ExerciseProcessResult processPose(Pose pose, DateTime timestamp);

  void reset();
}

/// Exponential Moving Average filter to smooth micro-jitter of raw coordinates or metrics.
///
/// Single-pass EMA (`current = current*(1-α) + new*α`) — not a true Double
/// EMA (DEMA, `2×EMA1(x) − EMA2(EMA1(x))`), which is a different, lower-lag
/// filter. Named `EmaFilter` (not `DoubleEMAFilter`) to avoid implying more
/// sophistication than this implements.
class EmaFilter {
  EmaFilter({required this.alpha});
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
