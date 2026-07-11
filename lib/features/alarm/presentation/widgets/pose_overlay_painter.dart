import 'package:awaken/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Draws ML Kit pose landmarks and skeleton connections over the camera preview.
///
/// Coordinate transformation: ML Kit returns landmarks in the image's native
/// coordinate space. [rotation] describes how the image was passed to ML Kit
/// so we can correctly map back to screen coordinates.
class PoseOverlayPainter extends CustomPainter {
  const PoseOverlayPainter({
    required this.pose,
    required this.imageSize,
    required this.rotation,
    required this.isSquatting,
    this.isFrontCamera = true,
    this.accentColor,
  });

  final Pose pose;
  final Size imageSize;
  final InputImageRotation rotation;
  final bool isSquatting;
  final bool isFrontCamera;
  final Color? accentColor;

  // Skeleton connections — only stable full-body landmarks
  static const _connections = <(PoseLandmarkType, PoseLandmarkType)>[
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
    (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
    (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
    (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
    (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
    (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
  ];

  static const double _minConfidence = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    final lineColor =
        isSquatting ? AppColors.success : (accentColor ?? AppColors.primary);

    final glowPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.35)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    final sharpPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final innerDotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final outerRingPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw connections
    for (final (startType, endType) in _connections) {
      final start = pose.landmarks[startType];
      final end = pose.landmarks[endType];
      if (start == null || end == null) continue;
      if (start.likelihood < _minConfidence || end.likelihood < _minConfidence) {
        continue;
      }

      final pStart = _toScreen(start, size);
      final pEnd = _toScreen(end, size);
      canvas.drawLine(pStart, pEnd, glowPaint);
      canvas.drawLine(pStart, pEnd, sharpPaint);
    }

    // Draw joint dots
    for (final landmark in pose.landmarks.values) {
      if (landmark.likelihood < _minConfidence) continue;
      final screenOffset = _toScreen(landmark, size);
      canvas.drawCircle(screenOffset, 2, innerDotPaint);
      canvas.drawCircle(screenOffset, 6, outerRingPaint);
    }
  }

  /// Maps a landmark from ML Kit image-space to widget screen-space.
  ///
  /// ML Kit returns coordinates in the raw image's coordinate system.
  /// The [rotation] describes how that image was passed in (clockwise degrees).
  /// We invert the rotation to get screen-space coordinates, then scale to size.
  Offset _toScreen(PoseLandmark lm, Size screen) {
    final double x = lm.x;
    final double y = lm.y;
    final double iW = imageSize.width;
    final double iH = imageSize.height;

    switch (rotation) {
      // Image was captured landscape; rotated 90° CW to appear portrait on screen
      case InputImageRotation.rotation90deg:
        // After 90° CW: new_x = y, new_y = imageWidth - x
        final sx = y / iH * screen.width;
        final sy = (iW - x) / iW * screen.height;
        return Offset(sx, sy);

      // Image was captured landscape; rotated 270° CW (=90° CCW) to appear portrait
      case InputImageRotation.rotation270deg:
        // After 270° CW: new_x = imageHeight - y, new_y = x
        double sx = (iH - y) / iH * screen.width;
        final sy = x / iW * screen.height;
        // Front camera mirrors horizontally
        if (isFrontCamera) sx = screen.width - sx;
        return Offset(sx, sy);

      case InputImageRotation.rotation180deg:
        return Offset(
          (iW - x) / iW * screen.width,
          (iH - y) / iH * screen.height,
        );

      // 0° (iOS default portrait, or already upright)
      case InputImageRotation.rotation0deg:
        double finalX = x;
        if (isFrontCamera) finalX = iW - x; // Mirror front camera
        return Offset(
          finalX / iW * screen.width,
          y / iH * screen.height,
        );
    }
  }

  @override
  bool shouldRepaint(PoseOverlayPainter old) =>
      old.pose != pose ||
      old.isSquatting != isSquatting ||
      old.accentColor != accentColor;
}
