import 'package:awaken/features/alarm/presentation/widgets/pose_overlay_painter.dart';
import 'package:awaken/features/alarm/presentation/widgets/scan_line_animation.dart';
import 'package:awaken/features/alarm/presentation/widgets/skeleton_wireframe.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Full-screen HUD compositing camera + pose overlay + scan line.
///
/// Layer order (bottom → top):
///   1. Camera preview (black box while initialising / no permission)
///   2. Radial vignette
///   3. Live pose skeleton (or static wireframe when ML Kit hasn't fired yet)
///   4. Scan line animation
class CameraHudOverlay extends StatelessWidget {
  const CameraHudOverlay({
    super.key,
    this.cameraController,
    this.pose,
    this.imageSize,
    this.rotation,
    this.isFrontCamera = true,
    this.isSquatting = false,
  });

  final CameraController? cameraController;
  final Pose? pose;
  final Size? imageSize;
  final InputImageRotation? rotation;
  final bool isFrontCamera;
  final bool isSquatting;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Layer 1: Camera or black placeholder ──────────────────────
        _CameraLayer(controller: cameraController),

        // ── Layer 2: Vignette ─────────────────────────────────────────
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.35),
              ],
            ),
          ),
        ),

        // ── Layer 3: Live skeleton or static fallback ─────────────────
        if (pose != null && imageSize != null && rotation != null)
          RepaintBoundary(
            child: CustomPaint(
              size: Size.infinite,
              painter: PoseOverlayPainter(
                pose: pose!,
                imageSize: imageSize!,
                rotation: rotation!,
                isSquatting: isSquatting,
                isFrontCamera: isFrontCamera,
              ),
            ),
          )
        else
          const SkeletonWireframe(),

        // ── Layer 4: Scan line ────────────────────────────────────────
        const RepaintBoundary(child: ScanLineAnimation()),
      ],
    );
  }
}

// ── Private camera layer ────────────────────────────────────────────────────

class _CameraLayer extends StatelessWidget {
  const _CameraLayer({required this.controller});

  final CameraController? controller;

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }

    // Cover-fill by treating previewSize in portrait terms.
    // previewSize is reported in sensor-native (landscape) orientation so swap w/h.
    final preview = controller!.value.previewSize;
    if (preview == null) return CameraPreview(controller!);

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: preview.height, // swapped: sensor orientation is landscape
          height: preview.width,
          child: CameraPreview(controller!),
        ),
      ),
    );
  }
}
