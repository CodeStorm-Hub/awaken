import 'package:awaken/features/alarm/domain/services/exercise_counter.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// High-knees FSM: alternating knee lift above hip height.
class HighKneesCounterService implements ExerciseCounter {
  static const double minConfidence = 0.5;
  static const double liftRatio = 0.12;

  _KneePhase _phase = _KneePhase.neutral;
  bool _expectLeft = true;
  bool _isCalibrated = false;
  int _calibrationFrames = 0;
  static const int requiredCalibrationFrames = 6;

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
  }

  @override
  ExerciseProcessResult processPose(Pose pose) {
    final metrics = _metrics(pose);
    if (metrics == null) {
      return const ExerciseProcessResult(
        hasPose: false,
        cue: 'FULL BODY IN FRAME',
      );
    }

    if (!_isCalibrated) {
      if (!metrics.leftUp && !metrics.rightUp) {
        _calibrationFrames++;
        if (_calibrationFrames >= requiredCalibrationFrames) {
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

    switch (_phase) {
      case _KneePhase.neutral:
        final up = _expectLeft ? metrics.leftUp : metrics.rightUp;
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
        final stillUp = _expectLeft ? metrics.leftUp : metrics.rightUp;
        if (!stillUp) {
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

  ({bool leftUp, bool rightUp})? _metrics(Pose pose) {
    final lh = pose.landmarks[PoseLandmarkType.leftHip];
    final rh = pose.landmarks[PoseLandmarkType.rightHip];
    final lk = pose.landmarks[PoseLandmarkType.leftKnee];
    final rk = pose.landmarks[PoseLandmarkType.rightKnee];
    if ([lh, rh, lk, rk].any((l) => l == null)) return null;
    if ([lh!, rh!, lk!, rk!]
        .any((l) => l.likelihood < minConfidence)) {
      return null;
    }

    final hipSpan = (lh.y - rh.y).abs() + 40;
    final threshold = hipSpan * liftRatio;
    // Image Y grows downward — knee "up" when above (smaller y than) hip.
    final leftUp = lk.y < lh.y - threshold;
    final rightUp = rk.y < rh.y - threshold;
    return (leftUp: leftUp, rightUp: rightUp);
  }
}

enum _KneePhase { neutral, lifted }
