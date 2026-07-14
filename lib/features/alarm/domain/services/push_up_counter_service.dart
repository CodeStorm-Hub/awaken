import 'dart:ui' show Offset;

import 'package:awaken/features/alarm/domain/services/exercise_counter.dart';
import 'package:awaken/features/alarm/domain/services/joint_angle.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Elbow-angle FSM for push-up reps (front or angled camera).
class PushUpCounterService implements ExerciseCounter {
  static const double downElbowDeg = 90.0;
  static const double upElbowDeg = 150.0;
  static const double minConfidence = 0.5;

  /// Elbow angle below which a descent is considered started (for shallow-rep
  /// detection) without yet reaching [downElbowDeg].
  static const double descentStartDeg = 130.0;

  _PushPhase _phase = _PushPhase.up;
  bool _descending = false;
  bool _isCalibrated = false;
  int _calibrationFrames = 0;
  static const int requiredCalibrationFrames = 6;

  final EmaFilter _elbowFilter = EmaFilter(alpha: 0.35);

  @override
  bool get isCalibrated => _isCalibrated;

  @override
  bool get isInActivePhase => _phase == _PushPhase.down;

  @override
  void reset() {
    _phase = _PushPhase.up;
    _descending = false;
    _isCalibrated = false;
    _calibrationFrames = 0;
    _elbowFilter.reset();
  }

  @override
  ExerciseProcessResult processPose(Pose pose, DateTime timestamp) {
    // No elapsed-time-gated bad-form window here (shallow-rep detection is
    // an angle-transition state machine, not frame-count-based) — timestamp
    // is unused but required by the shared ExerciseCounter interface.
    // Check joint presence and confidence specifically for shoulders, elbows, wrists
    final ls = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rs = pose.landmarks[PoseLandmarkType.rightShoulder];
    final le = pose.landmarks[PoseLandmarkType.leftElbow];
    final re = pose.landmarks[PoseLandmarkType.rightElbow];
    final lw = pose.landmarks[PoseLandmarkType.leftWrist];
    final rw = pose.landmarks[PoseLandmarkType.rightWrist];

    final hasUpperBody = ls != null &&
        rs != null &&
        le != null &&
        re != null &&
        lw != null &&
        rw != null &&
        ls.likelihood >= minConfidence &&
        rs.likelihood >= minConfidence &&
        le.likelihood >= minConfidence &&
        re.likelihood >= minConfidence &&
        lw.likelihood >= minConfidence &&
        rw.likelihood >= minConfidence;

    if (!hasUpperBody) {
      return const ExerciseProcessResult(
        hasPose: false,
        cue: 'STEP BACK — UPPER BODY IN FRAME',
      );
    }

    final rawElbow = _combinedElbowAngle(pose);
    if (rawElbow == null) {
      return const ExerciseProcessResult(
        hasPose: false,
        cue: 'STEP BACK — UPPER BODY IN FRAME',
      );
    }
    final elbow = _elbowFilter.filter(rawElbow);

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
          _descending = false;
          return const ExerciseProcessResult(
            hasPose: true,
            depthRatio: 1.0,
            cue: 'PRESS UP',
          );
        }
        // A dip that starts but returns to full extension without reaching
        // [downElbowDeg] is one shallow rep — flag it once at the top, not
        // on every mid-descent frame.
        if (elbow < descentStartDeg) {
          _descending = true;
          return const ExerciseProcessResult(
            hasPose: true,
            depthRatio: 0.3,
            cue: 'DROP LOWER',
          );
        }
        if (_descending && elbow >= upElbowDeg) {
          _descending = false;
          return const ExerciseProcessResult(
            hasPose: true,
            badForm: true,
            depthRatio: 0.3,
            cue: 'TOO SHALLOW — CHEST TO FLOOR',
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
    return JointAngle.between(
      Offset(a.x, a.y),
      Offset(b.x, b.y),
      Offset(c.x, c.y),
    );
  }
}

enum _PushPhase { up, down }
