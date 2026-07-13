import 'package:awaken/features/alarm/domain/services/exercise_counter.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Arms-up + feet-out state machine for jumping jacks.
class JumpingJackCounterService implements ExerciseCounter {
  static const double minConfidence = 0.45;
  static const double feetOutRatio = 1.35;

  _JackPhase _phase = _JackPhase.closed;
  bool _isCalibrated = false;
  int _calibrationFrames = 0;
  int _asymmetryFrames = 0;
  double? _standingAnkleGap;
  static const int requiredCalibrationFrames = 6;

  /// Arms/feet naturally desynchronize for a few frames mid-jump; only a
  /// mismatch held this long (~0.7s at 15 FPS) is bad form.
  static const int badFormAsymmetryFrames = 10;

  final DoubleEMAFilter _gapFilter = DoubleEMAFilter(alpha: 0.35);

  @override
  bool get isCalibrated => _isCalibrated;

  @override
  bool get isInActivePhase => _phase == _JackPhase.open;

  @override
  void reset() {
    _phase = _JackPhase.closed;
    _isCalibrated = false;
    _calibrationFrames = 0;
    _asymmetryFrames = 0;
    _standingAnkleGap = null;
    _gapFilter.reset();
  }

  @override
  ExerciseProcessResult processPose(Pose pose) {
    // Check joint presence and confidence specifically for ankles, wrists, nose, hips
    final lw = pose.landmarks[PoseLandmarkType.leftWrist];
    final rw = pose.landmarks[PoseLandmarkType.rightWrist];
    final la = pose.landmarks[PoseLandmarkType.leftAnkle];
    final ra = pose.landmarks[PoseLandmarkType.rightAnkle];
    final lh = pose.landmarks[PoseLandmarkType.leftHip];
    final rh = pose.landmarks[PoseLandmarkType.rightHip];
    final nose = pose.landmarks[PoseLandmarkType.nose];

    final hasAnkles = la != null && ra != null && la.likelihood >= minConfidence && ra.likelihood >= minConfidence;
    final hasOthers = lw != null &&
        rw != null &&
        lh != null &&
        rh != null &&
        nose != null &&
        lw.likelihood >= minConfidence &&
        rw.likelihood >= minConfidence &&
        lh.likelihood >= minConfidence &&
        rh.likelihood >= minConfidence &&
        nose.likelihood >= minConfidence;

    if (!hasAnkles) {
      return const ExerciseProcessResult(
        hasPose: false,
        cue: 'STEP BACK — FEET OUT OF FRAME',
      );
    }
    if (!hasOthers) {
      return const ExerciseProcessResult(
        hasPose: false,
        cue: 'STEP BACK — FULL BODY IN FRAME',
      );
    }

    final metrics = _metrics(pose);
    if (metrics == null) {
      return const ExerciseProcessResult(
        hasPose: false,
        cue: 'STEP BACK — FULL BODY IN FRAME',
      );
    }

    final filteredGap = _gapFilter.filter(metrics.ankleGap);

    if (!_isCalibrated) {
      if (!metrics.armsUp && filteredGap > 0) {
        _calibrationFrames++;
        _standingAnkleGap = filteredGap;
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

    final baseGap = _standingAnkleGap ?? filteredGap;
    final feetOut = baseGap > 0 && filteredGap >= baseGap * feetOutRatio;

    switch (_phase) {
      case _JackPhase.closed:
        if (metrics.armsUp && feetOut) {
          _phase = _JackPhase.open;
          _asymmetryFrames = 0;
          return const ExerciseProcessResult(
            hasPose: true,
            depthRatio: 1.0,
            cue: 'RETURN',
          );
        }
        if (metrics.armsUp != feetOut) {
          _asymmetryFrames++;
          if (_asymmetryFrames >= badFormAsymmetryFrames) {
            _asymmetryFrames = 0;
            return const ExerciseProcessResult(
              hasPose: true,
              badForm: true,
              depthRatio: 0.4,
              cue: 'ARMS AND FEET TOGETHER',
            );
          }
          return const ExerciseProcessResult(
            hasPose: true,
            depthRatio: 0.4,
            cue: 'ARMS AND FEET TOGETHER',
          );
        }
        _asymmetryFrames = 0;
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
