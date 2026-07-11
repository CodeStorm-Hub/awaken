import 'package:awaken/features/alarm/domain/services/exercise_counter.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Arms-up + feet-out state machine for jumping jacks.
class JumpingJackCounterService implements ExerciseCounter {
  static const double minConfidence = 0.45;
  static const double feetOutRatio = 1.35;

  _JackPhase _phase = _JackPhase.closed;
  bool _isCalibrated = false;
  int _calibrationFrames = 0;
  double? _standingAnkleGap;
  static const int requiredCalibrationFrames = 6;

  @override
  bool get isCalibrated => _isCalibrated;

  @override
  bool get isInActivePhase => _phase == _JackPhase.open;

  @override
  void reset() {
    _phase = _JackPhase.closed;
    _isCalibrated = false;
    _calibrationFrames = 0;
    _standingAnkleGap = null;
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
      if (!metrics.armsUp && metrics.ankleGap > 0) {
        _calibrationFrames++;
        _standingAnkleGap = metrics.ankleGap;
        if (_calibrationFrames >= requiredCalibrationFrames) {
          _isCalibrated = true;
        }
      } else {
        _calibrationFrames = 0;
      }
      return const ExerciseProcessResult(
        hasPose: true,
        cue: 'STAND STILL — ARMS DOWN',
      );
    }

    final baseGap = _standingAnkleGap ?? metrics.ankleGap;
    final feetOut = baseGap > 0 && metrics.ankleGap >= baseGap * feetOutRatio;

    switch (_phase) {
      case _JackPhase.closed:
        if (metrics.armsUp && feetOut) {
          _phase = _JackPhase.open;
          return const ExerciseProcessResult(
            hasPose: true,
            depthRatio: 1.0,
            cue: 'RETURN',
          );
        }
        if (metrics.armsUp != feetOut) {
          return const ExerciseProcessResult(
            hasPose: true,
            badForm: true,
            depthRatio: 0.4,
            cue: 'ARMS AND FEET TOGETHER',
          );
        }
        return const ExerciseProcessResult(
          hasPose: true,
          depthRatio: 0.0,
          cue: 'JUMP WIDE',
        );

      case _JackPhase.open:
        if (!metrics.armsUp && !feetOut) {
          _phase = _JackPhase.closed;
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
          cue: 'RETURN',
        );
    }
  }

  ({bool armsUp, double ankleGap})? _metrics(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final lw = pose.landmarks[PoseLandmarkType.leftWrist];
    final rw = pose.landmarks[PoseLandmarkType.rightWrist];
    final la = pose.landmarks[PoseLandmarkType.leftAnkle];
    final ra = pose.landmarks[PoseLandmarkType.rightAnkle];
    final lh = pose.landmarks[PoseLandmarkType.leftHip];
    final rh = pose.landmarks[PoseLandmarkType.rightHip];

    if ([nose, lw, rw, la, ra, lh, rh].any((l) => l == null)) return null;
    if ([nose!, lw!, rw!, la!, ra!, lh!, rh!].any((l) => l.likelihood < minConfidence)) {
      return null;
    }

    // Image Y grows downward — arms are "up" when wrists are at/above the nose.
    final armsUp = lw.y <= nose.y && rw.y <= nose.y;
    final ankleGap = (la.x - ra.x).abs();
    return (armsUp: armsUp, ankleGap: ankleGap);
  }
}

enum _JackPhase { closed, open }
