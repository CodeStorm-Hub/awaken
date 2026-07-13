import 'package:awaken/features/alarm/domain/services/exercise_counter.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// High-knees FSM: alternating knee lift above hip height.
///
/// Thresholds are normalized by the standing hip-to-knee distance captured
/// during calibration, so detection is independent of camera resolution and
/// how far the user stands from the phone.
class HighKneesCounterService implements ExerciseCounter {
  static const double minConfidence = 0.5;

  /// Knee counts as lifted when it rises to within this fraction of thigh
  /// length below hip level (0 = knee exactly at hip height).
  static const double liftFraction = 0.15;

  /// Knee counts as planted again once it drops below this fraction of thigh
  /// length under the hip — hysteresis so jitter can't double-count.
  static const double plantFraction = 0.6;

  _KneePhase _phase = _KneePhase.neutral;
  bool _expectLeft = true;
  bool _isCalibrated = false;
  int _calibrationFrames = 0;
  double _standingThigh = 0;
  static const int requiredCalibrationFrames = 6;

  final DoubleEMAFilter _leftDiffFilter = DoubleEMAFilter(alpha: 0.35);
  final DoubleEMAFilter _rightDiffFilter = DoubleEMAFilter(alpha: 0.35);

  @override
  bool get isCalibrated => _isCalibrated;

  @override
  bool get isInActivePhase => _phase == _KneePhase.lifted;

  @override
  void reset() {
    _phase = _KneePhase.neutral;
    _expectLeft = true;
    _isCalibrated = false;
    _calibrationFrames = 0;
    _standingThigh = 0;
    _leftDiffFilter.reset();
    _rightDiffFilter.reset();
  }

  @override
  ExerciseProcessResult processPose(Pose pose) {
    // Check joint presence and confidence specifically for hips and knees
    final lh = pose.landmarks[PoseLandmarkType.leftHip];
    final rh = pose.landmarks[PoseLandmarkType.rightHip];
    final lk = pose.landmarks[PoseLandmarkType.leftKnee];
    final rk = pose.landmarks[PoseLandmarkType.rightKnee];

    final hasKneesAndHips = lh != null &&
        rh != null &&
        lk != null &&
        rk != null &&
        lh.likelihood >= minConfidence &&
        rh.likelihood >= minConfidence &&
        lk.likelihood >= minConfidence &&
        rk.likelihood >= minConfidence;

    if (!hasKneesAndHips) {
      return const ExerciseProcessResult(
        hasPose: false,
        cue: 'STEP BACK — HIPS & KNEES IN FRAME',
      );
    }

    // Vertical hip→knee displacement per side; image Y grows downward, so
    // standing gives a negative diff of about one thigh length.
    final leftDiff = _leftDiffFilter.filter(lh.y - lk.y);
    final rightDiff = _rightDiffFilter.filter(rh.y - rk.y);

    if (!_isCalibrated) {
      final bothDown = leftDiff < 0 && rightDiff < 0;
      if (bothDown) {
        _calibrationFrames++;
        _standingThigh = (-leftDiff + -rightDiff) / 2;
        if (_calibrationFrames >= requiredCalibrationFrames &&
            _standingThigh > 1) {
          _isCalibrated = true;
        }
      } else {
        _calibrationFrames = 0;
      }
      return const ExerciseProcessResult(
        hasPose: true,
        cue: 'STAND TALL — READY FOR HIGH KNEES',
      );
    }

    final liftThreshold = -liftFraction * _standingThigh;
    final plantThreshold = -plantFraction * _standingThigh;
    final leftUp = leftDiff >= liftThreshold;
    final rightUp = rightDiff >= liftThreshold;
    final leftDown = leftDiff <= plantThreshold;
    final rightDown = rightDiff <= plantThreshold;

    switch (_phase) {
      case _KneePhase.neutral:
        final up = _expectLeft ? leftUp : rightUp;
        if (up) {
          _phase = _KneePhase.lifted;
          return ExerciseProcessResult(
            hasPose: true,
            depthRatio: 1.0,
            cue: _expectLeft ? 'SWITCH — RIGHT KNEE' : 'SWITCH — LEFT KNEE',
          );
        }
        return ExerciseProcessResult(
          hasPose: true,
          depthRatio: 0.0,
          cue: _expectLeft ? 'DRIVE LEFT KNEE UP' : 'DRIVE RIGHT KNEE UP',
        );

      case _KneePhase.lifted:
        final planted = _expectLeft ? leftDown : rightDown;
        if (planted) {
          _phase = _KneePhase.neutral;
          _expectLeft = !_expectLeft;
          return const ExerciseProcessResult(
            hasPose: true,
            repCompleted: true,
            depthRatio: 1.0,
            cue: 'PERFECT REP',
          );
        }
        return const ExerciseProcessResult(
          hasPose: true,
          depthRatio: 0.8,
          cue: 'PLANT AND SWITCH',
        );
    }
  }
}

enum _KneePhase { neutral, lifted }
