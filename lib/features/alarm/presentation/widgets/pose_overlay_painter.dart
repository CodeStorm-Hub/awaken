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
    final lineColor = isSquatting
        ? AppColors.success
        : (accentColor ?? AppColors.primary);

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
      if (start.likelihood < _minConfidence ||
          end.likelihood < _minConfidence) {
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
  /// The [rotation] describes how that image was passed in (clockwise
  /// degrees). We first rotate the point into the upright (display)
  /// orientation, then apply the SAME cover-fit transform the camera preview
  /// uses (`FittedBox(fit: BoxFit.cover)` in `_CameraLayer`): uniform scale
  /// by the larger axis ratio, center-cropped. Stretching each axis
  /// independently (the previous approach) distorts the skeleton whenever
  /// the rotated image aspect ratio differs from the widget's — which is
  /// nearly always on a portrait phone with a 4:3 sensor.
  Offset _toScreen(PoseLandmark lm, Size screen) {
    final double x = lm.x;
    final double y = lm.y;
    final double iW = imageSize.width;
    final double iH = imageSize.height;

    // Rotate into upright display space. rx/ry are in pixels of the rotated
    // image, whose dimensions are rW×rH.
    final double rx, ry, rW, rH;
    switch (rotation) {
      // Captured landscape; rotated 90° CW to appear portrait on screen.
      case InputImageRotation.rotation90deg:
        rx = y;
        ry = iW - x;
        rW = iH;
        rH = iW;
      // Captured landscape; rotated 270° CW (=90° CCW) to appear portrait.
      case InputImageRotation.rotation270deg:
        rx = iH - y;
        ry = x;
        rW = iH;
        rH = iW;
      case InputImageRotation.rotation180deg:
        rx = iW - x;
        ry = iH - y;
        rW = iW;
        rH = iH;
      // 0° (iOS default portrait, or already upright).
      case InputImageRotation.rotation0deg:
        rx = x;
        ry = y;
        rW = iW;
        rH = iH;
    }

    // Cover-fit: scale uniformly so the image fills the widget, letting the
    // overflow crop symmetrically — mirroring what BoxFit.cover does to the
    // preview underneath this overlay.
    if (rW <= 0 || rH <= 0) return Offset.zero;
    final scale = (screen.width / rW) > (screen.height / rH)
        ? screen.width / rW
        : screen.height / rH;
    final cropDx = (rW * scale - screen.width) / 2;
    final cropDy = (rH * scale - screen.height) / 2;

    var sx = rx * scale - cropDx;
    final sy = ry * scale - cropDy;

    // Front camera preview is mirrored horizontally.
    if (isFrontCamera) sx = screen.width - sx;
    return Offset(sx, sy);
  }

  @override
  bool shouldRepaint(PoseOverlayPainter old) =>
      old.pose != pose ||
      old.imageSize != imageSize ||
      old.rotation != rotation ||
      old.isFrontCamera != isFrontCamera ||
      old.isSquatting != isSquatting ||
      old.accentColor != accentColor;
}
