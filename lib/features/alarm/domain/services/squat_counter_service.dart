import 'dart:math' as math;

import 'package:awaken/core/constants/app_constants.dart';
import 'package:flutter/painting.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Result of processing a single pose frame through [SquatCounterService].
class SquatProcessResult {
  const SquatProcessResult({
    this.repCompleted = false,
    this.badForm = false,
    this.depthRatio,
    this.hasPose = false,
  });

  final bool repCompleted;
  final bool badForm;
  final double? depthRatio;
  final bool hasPose;
}

/// Two-state machine that counts full squat repetitions from ML Kit poses.
///
/// A rep is complete when:
///   1. The knee angle drops below [squatThresholdDeg] (going down).
///   2. The user reaches sufficient hip-to-knee depth during the squat phase.
///   3. The knee angle rises back above [standThresholdDeg] (returning to stand).
///
/// Uses the average of both knee angles when both sides are confident.
class SquatCounterService {
  static const double squatThresholdDeg = 100.0;
  static const double standThresholdDeg = 150.0;
  static const double minConfidence = 0.5;

  _SquatPhase _phase = _SquatPhase.standing;
  double? _standingHipKneeGap;
  double _deepestDepthRatio = 0.0;
  double? _deepestSquatAngle;

  bool get isInSquat => _phase == _SquatPhase.squatting;

  /// Processes a detected pose and returns squat state for this frame.
  SquatProcessResult processPose(Pose pose) {
    final angle = _combinedKneeAngle(pose);
    if (angle == null) {
      return const SquatProcessResult(hasPose: false);
    }

    final depthRatio = _currentDepthRatio(pose);

    switch (_phase) {
      case _SquatPhase.standing:
        final standingGap = _hipKneeGap(pose);
        if (standingGap != null) {
          _standingHipKneeGap = standingGap;
        }

        if (angle < squatThresholdDeg) {
          _phase = _SquatPhase.squatting;
          _deepestDepthRatio = depthRatio ?? 0.0;
          _deepestSquatAngle = angle;
        }
      case _SquatPhase.squatting:
        if (depthRatio != null && depthRatio > _deepestDepthRatio) {
          _deepestDepthRatio = depthRatio;
        }
        if (_deepestSquatAngle == null || angle < _deepestSquatAngle!) {
          _deepestSquatAngle = angle;
        }

        if (angle > standThresholdDeg) {
          final achievedDepth = _deepestDepthRatio;
          _resetSquatTracking();

          if (achievedDepth >= AppConstants.squatDepthThreshold) {
            return SquatProcessResult(
              repCompleted: true,
              depthRatio: achievedDepth,
              hasPose: true,
            );
          }

          return SquatProcessResult(
            badForm: true,
            depthRatio: achievedDepth,
            hasPose: true,
          );
        }
    }

    return SquatProcessResult(
      depthRatio: depthRatio ?? _deepestDepthRatio,
      hasPose: true,
    );
  }

  void reset() {
    _phase = _SquatPhase.standing;
    _resetSquatTracking();
  }

  // ── Internals ──────────────────────────────────────────────────────

  void _resetSquatTracking() {
    _phase = _SquatPhase.standing;
    _standingHipKneeGap = null;
    _deepestDepthRatio = 0.0;
    _deepestSquatAngle = null;
  }

  /// Hip-to-knee depth ratio: 0 at standing height, 1 when hip reaches knee level.
  double? _currentDepthRatio(Pose pose) {
    final gap = _hipKneeGap(pose);
    if (gap == null) return null;

    final reference = _standingHipKneeGap ?? gap;
    if (reference <= 0) return null;

    return (1.0 - (gap / reference)).clamp(0.0, 1.0);
  }

  double? _hipKneeGap(Pose pose) {
    final hipY = _avgLandmarkY(
      pose,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    );
    final kneeY = _avgLandmarkY(
      pose,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
    );
    if (hipY == null || kneeY == null) return null;
    return kneeY - hipY;
  }

  double? _avgLandmarkY(
    Pose pose,
    PoseLandmarkType leftType,
    PoseLandmarkType rightType,
  ) {
    final left = pose.landmarks[leftType];
    final right = pose.landmarks[rightType];

    if (left != null &&
        left.likelihood >= minConfidence &&
        right != null &&
        right.likelihood >= minConfidence) {
      return (left.y + right.y) / 2;
    }
    if (left != null && left.likelihood >= minConfidence) return left.y;
    if (right != null && right.likelihood >= minConfidence) return right.y;
    return null;
  }

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
