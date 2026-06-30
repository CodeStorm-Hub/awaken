import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Two-state machine that counts full squat repetitions from ML Kit poses.
///
/// A rep is complete when:
///   1. The knee angle drops below [squatThresholdDeg] (going down).
///   2. The knee angle rises back above [standThresholdDeg] (returning to stand).
///
/// Uses the average of both knee angles when both sides are confident.
class SquatCounterService {
  static const double squatThresholdDeg = 100.0;
  static const double standThresholdDeg = 150.0;
  static const double minConfidence = 0.5;

  _SquatPhase _phase = _SquatPhase.standing;

  bool get isInSquat => _phase == _SquatPhase.squatting;

  /// Returns true when a complete rep is detected.
  bool processPose(Pose pose) {
    final angle = _combinedKneeAngle(pose);
    if (angle == null) return false;

    switch (_phase) {
      case _SquatPhase.standing:
        if (angle < squatThresholdDeg) {
          _phase = _SquatPhase.squatting;
        }
      case _SquatPhase.squatting:
        if (angle > standThresholdDeg) {
          _phase = _SquatPhase.standing;
          return true; // Rep complete
        }
    }
    return false;
  }

  void reset() => _phase = _SquatPhase.standing;

  // ── Internals ──────────────────────────────────────────────────────

  double? _combinedKneeAngle(Pose pose) {
    final left = _kneeAngle(
      pose,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.leftAnkle,
    );
    final right = _kneeAngle(
      pose,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.rightAnkle,
    );

    if (left == null && right == null) return null;
    if (left == null) return right;
    if (right == null) return left;
    return (left + right) / 2;
  }

  double? _kneeAngle(
    Pose pose,
    PoseLandmarkType hipType,
    PoseLandmarkType kneeType,
    PoseLandmarkType ankleType,
  ) {
    final hip = pose.landmarks[hipType];
    final knee = pose.landmarks[kneeType];
    final ankle = pose.landmarks[ankleType];
    if (hip == null || knee == null || ankle == null) return null;
    if (hip.likelihood < minConfidence ||
        knee.likelihood < minConfidence ||
        ankle.likelihood < minConfidence) {
      return null;
    }
    return _angleDeg(
      Offset(hip.x, hip.y),
      Offset(knee.x, knee.y),
      Offset(ankle.x, ankle.y),
    );
  }

  static double _angleDeg(Offset a, Offset vertex, Offset c) {
    final ba = Offset(a.dx - vertex.dx, a.dy - vertex.dy);
    final bc = Offset(c.dx - vertex.dx, c.dy - vertex.dy);
    final dot = ba.dx * bc.dx + ba.dy * bc.dy;
    final cross = (ba.dx * bc.dy - ba.dy * bc.dx).abs();
    return math.atan2(cross, dot) * (180.0 / math.pi);
  }
}

enum _SquatPhase { standing, squatting }
