import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/features/alarm/domain/services/exercise_counter.dart';
import 'package:awaken/features/alarm/domain/services/joint_angle.dart';
import 'package:flutter/painting.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Result of processing a single pose frame through [SquatCounterService].
class SquatProcessResult {
  const SquatProcessResult({
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
  final String? cue;
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
  double? _standingNormalizedGap;
  double _deepestDepthRatio = 0.0;
  double? _deepestSquatAngle;

  bool _isCalibrated = false;
  int _calibrationFrames = 0;
  static const int requiredCalibrationFrames = 8;

  final EmaFilter _angleFilter = EmaFilter(alpha: 0.35);
  final EmaFilter _depthFilter = EmaFilter(alpha: 0.35);

  bool get isInSquat => _phase == _SquatPhase.squatting;
  bool get isCalibrated => _isCalibrated;

  /// Processes a detected pose and returns squat state for this frame.
  SquatProcessResult processPose(Pose pose) {
    // Check joint presence and confidence specifically for ankles
    final la = pose.landmarks[PoseLandmarkType.leftAnkle];
    final ra = pose.landmarks[PoseLandmarkType.rightAnkle];
    final lh = pose.landmarks[PoseLandmarkType.leftHip];
    final rh = pose.landmarks[PoseLandmarkType.rightHip];
    final lk = pose.landmarks[PoseLandmarkType.leftKnee];
    final rk = pose.landmarks[PoseLandmarkType.rightKnee];

    final hasAnkles =
        (la != null && la.likelihood >= minConfidence) ||
        (ra != null && ra.likelihood >= minConfidence);
    final hasHips =
        (lh != null && lh.likelihood >= minConfidence) ||
        (rh != null && rh.likelihood >= minConfidence);
    final hasKnees =
        (lk != null && lk.likelihood >= minConfidence) ||
        (rk != null && rk.likelihood >= minConfidence);

    if (!hasAnkles) {
      return const SquatProcessResult(
        hasPose: false,
        cue: 'STEP BACK — FEET OUT OF FRAME',
      );
    }
    if (!hasHips || !hasKnees) {
      return const SquatProcessResult(
        hasPose: false,
        cue: 'STEP BACK — FULL BODY IN FRAME',
      );
    }

    final rawAngle = _combinedKneeAngle(pose);
    if (rawAngle == null) {
      return const SquatProcessResult(
        hasPose: false,
        cue: 'STEP BACK — FULL BODY IN FRAME',
      );
    }
    final angle = _angleFilter.filter(rawAngle);

    final torso = _torsoHeight(pose);
    final currentGap = _hipKneeGap(pose);
    if (torso == null || currentGap == null) {
      return const SquatProcessResult(
        hasPose: false,
        cue: 'STEP BACK — FULL BODY IN FRAME',
      );
    }
    final normalizedGap = currentGap / torso;

    // ── Calibration Phase ────────────────────────────────────────────
    if (!_isCalibrated) {
      if (angle >= 160.0) {
        _calibrationFrames++;
        if (_calibrationFrames >= requiredCalibrationFrames) {
          _standingNormalizedGap = normalizedGap;
          _isCalibrated = true;
        }
      } else {
        _calibrationFrames = 0;
      }
      return const SquatProcessResult(
        hasPose: true,
        depthRatio: 0.0,
        cue: 'STAND TALL — HOLD TO CALIBRATE',
      );
    }

    final standingRef = _standingNormalizedGap ?? normalizedGap;
    final rawDepthRatio = standingRef <= 0
        ? 0.0
        : (1.0 - (normalizedGap / standingRef)).clamp(0.0, 1.0);
    final depthRatio = _depthFilter.filter(rawDepthRatio);

    switch (_phase) {
      case _SquatPhase.standing:
        if (angle < squatThresholdDeg) {
          _phase = _SquatPhase.squatting;
          _deepestDepthRatio = depthRatio;
          _deepestSquatAngle = angle;
        }
      case _SquatPhase.squatting:
        if (depthRatio > _deepestDepthRatio) {
          _deepestDepthRatio = depthRatio;
        }
        if (_deepestSquatAngle == null || angle < _deepestSquatAngle!) {
          _deepestSquatAngle = angle;
        }

        if (angle > standThresholdDeg) {
          final achievedDepth = _deepestDepthRatio;
          final tilted = _hasExcessiveShoulderTilt(pose);
          _resetSquatTracking();

          if (tilted) {
            return SquatProcessResult(
              badForm: true,
              depthRatio: achievedDepth,
              hasPose: true,
              cue: 'KEEP SHOULDERS LEVEL',
            );
          }

          if (achievedDepth >= AppConstants.squatDepthThreshold) {
            return SquatProcessResult(
              repCompleted: true,
              depthRatio: achievedDepth,
              hasPose: true,
              cue: 'PERFECT REP',
            );
          }

          return SquatProcessResult(
            badForm: true,
            depthRatio: achievedDepth,
            hasPose: true,
            cue: 'GO DEEPER',
          );
        }
    }

    return SquatProcessResult(
      depthRatio: depthRatio,
      hasPose: true,
      cue: _phase == _SquatPhase.squatting ? 'PRESS UP' : 'SQUAT DOWN',
    );
  }

  void reset() {
    _phase = _SquatPhase.standing;
    _isCalibrated = false;
    _calibrationFrames = 0;
    _standingNormalizedGap = null;
    _angleFilter.reset();
    _depthFilter.reset();
    _resetSquatTracking();
  }

  double? getLeftKneeAngle(Pose pose) => _kneeAngle(
    pose,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.leftAnkle,
  );

  double? getRightKneeAngle(Pose pose) => _kneeAngle(
    pose,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.rightAnkle,
  );

  // ── Internals ──────────────────────────────────────────────────────

  void _resetSquatTracking() {
    _phase = _SquatPhase.standing;
    _deepestDepthRatio = 0.0;
    _deepestSquatAngle = null;
  }

  double? _torsoHeight(Pose pose) {
    final shoulderY = _avgLandmarkY(
      pose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
    );
    final hipY = _avgLandmarkY(
      pose,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    );
    if (shoulderY == null || hipY == null) return null;
    final val = (hipY - shoulderY).abs();
    return val > 1 ? val : null;
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

  /// Flags leaning / collapsing form when shoulders are uneven relative to torso.
  bool _hasExcessiveShoulderTilt(Pose pose) {
    final left = pose.landmarks[PoseLandmarkType.leftShoulder];
    final right = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    if (left == null ||
        right == null ||
        leftHip == null ||
        rightHip == null ||
        left.likelihood < minConfidence ||
        right.likelihood < minConfidence ||
        leftHip.likelihood < minConfidence ||
        rightHip.likelihood < minConfidence) {
      return false;
    }

    final torso = (((leftHip.y + rightHip.y) / 2) - ((left.y + right.y) / 2))
        .abs();
    if (torso < 1) return false;

    final tilt = (left.y - right.y).abs() / torso;
    return tilt > AppConstants.maxShoulderTiltRatio;
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
    return JointAngle.between(
      Offset(hip.x, hip.y),
      Offset(knee.x, knee.y),
      Offset(ankle.x, ankle.y),
    );
  }
}

enum _SquatPhase { standing, squatting }
