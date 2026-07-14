import 'package:awaken/core/theme/hud_theme.dart';
import 'package:awaken/features/alarm/presentation/widgets/pose_overlay_painter.dart';
import 'package:awaken/features/alarm/presentation/widgets/scan_line_animation.dart';
import 'package:awaken/features/alarm/presentation/widgets/skeleton_wireframe.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Full-screen HUD compositing camera + pose overlay + scan line.
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
    final hud = Theme.of(context).extension<HudTheme>() ?? HudTheme.cyan;

    return Stack(
      fit: StackFit.expand,
      children: [
        _CameraLayer(controller: cameraController),
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
        // Theme-tinted edge vignette
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: hud.primary.withValues(alpha: 0.18),
              width: 2,
            ),
          ),
        ),
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
                accentColor: hud.primary,
              ),
            ),
          )
        else
          SkeletonWireframe(accentColor: hud.primary),
        RepaintBoundary(child: ScanLineAnimation(accentColor: hud.primary)),
      ],
    );
  }
}

class _CameraLayer extends StatelessWidget {
  const _CameraLayer({required this.controller});

  final CameraController? controller;

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }

    final preview = controller!.value.previewSize;
    if (preview == null) return CameraPreview(controller!);

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: preview.height,
          height: preview.width,
          child: CameraPreview(controller!),
        ),
      ),
    );
  }
}
