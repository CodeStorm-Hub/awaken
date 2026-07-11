import 'dart:math' as math;

import 'package:awaken/features/alarm/domain/services/exercise_counter.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Elbow-angle FSM for push-up reps (front or angled camera).
class PushUpCounterService implements ExerciseCounter {
  static const double downElbowDeg = 90.0;
  static const double upElbowDeg = 150.0;
  static const double minConfidence = 0.5;

  _PushPhase _phase = _PushPhase.up;
  bool _isCalibrated = false;
  int _calibrationFrames = 0;
  static const int requiredCalibrationFrames = 6;

  @override
  bool get isCalibrated => _isCalibrated;

  @override
  bool get isInActivePhase => _phase == _PushPhase.down;

  @override
  void reset() {
    _phase = _PushPhase.up;
    _isCalibrated = false;
    _calibrationFrames = 0;
  }

  @override
  ExerciseProcessResult processPose(Pose pose) {
    final elbow = _combinedElbowAngle(pose);
    if (elbow == null) {
      return const ExerciseProcessResult(hasPose: false, cue: 'FULL BODY IN FRAME');
    }

    if (!_isCalibrated) {
      if (elbow >= upElbowDeg) {
        _calibrationFrames++;
        if (_calibrationFrames >= requiredCalibrationFrames) {
          _isCalibrated = true;
        }
      } else {
        _calibrationFrames = 0;
      }
      return const ExerciseProcessResult(
        hasPose: true,
        cue: 'ARMS EXTENDED — HOLD TO CALIBRATE',
      );
    }

    switch (_phase) {
      case _PushPhase.up:
        if (elbow <= downElbowDeg) {
          _phase = _PushPhase.down;
          return const ExerciseProcessResult(
            hasPose: true,
            depthRatio: 1.0,
            cue: 'PRESS UP',
          );
        }
        if (elbow > downElbowDeg && elbow < upElbowDeg - 20) {
          return const ExerciseProcessResult(
            hasPose: true,
            badForm: true,
            depthRatio: 0.3,
            cue: 'DROP LOWER',
          );
        }
        return const ExerciseProcessResult(
          hasPose: true,
          depthRatio: 0.0,
          cue: 'DROP AND PUSH',
        );

      case _PushPhase.down:
        if (elbow >= upElbowDeg) {
          _phase = _PushPhase.up;
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
          cue: 'PRESS UP',
        );
    }
  }

  double? _combinedElbowAngle(Pose pose) {
    final left = _elbowAngle(
      pose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.leftWrist,
    );
    final right = _elbowAngle(
      pose,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.rightWrist,
    );
    if (left != null && right != null) return (left + right) / 2;
    return left ?? right;
  }

  double? _elbowAngle(
    Pose pose,
    PoseLandmarkType shoulder,
    PoseLandmarkType elbow,
    PoseLandmarkType wrist,
  ) {
    final a = pose.landmarks[shoulder];
    final b = pose.landmarks[elbow];
    final c = pose.landmarks[wrist];
    if (a == null || b == null || c == null) return null;
    if (a.likelihood < minConfidence ||
        b.likelihood < minConfidence ||
        c.likelihood < minConfidence) {
      return null;
    }
    return _angle(a.x, a.y, b.x, b.y, c.x, c.y);
  }

  double _angle(
    double ax,
    double ay,
    double bx,
    double by,
    double cx,
    double cy,
  ) {
    final abx = ax - bx;
    final aby = ay - by;
    final cbx = cx - bx;
    final cby = cy - by;
    final dot = abx * cbx + aby * cby;
    final mag = math.sqrt(abx * abx + aby * aby) * math.sqrt(cbx * cbx + cby * cby);
    if (mag == 0) return 180;
    final cos = (dot / mag).clamp(-1.0, 1.0);
    return math.acos(cos) * 180 / math.pi;
  }
}

enum _PushPhase { up, down }
