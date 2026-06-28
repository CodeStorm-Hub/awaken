import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/alarm/presentation/widgets/scan_line_animation.dart';
import 'package:awaken/features/alarm/presentation/widgets/skeleton_wireframe.dart';
import 'package:flutter/material.dart';

/// Full-screen camera HUD stack.
///
/// Layer order (bottom → top):
///   1. Solid black — camera feed placeholder (Phase 4: replace with CameraPreview)
///   2. Vignette gradient — darkens edges for cinematic depth
///   3. SkeletonWireframe — glowing stick figure
///   4. ScanLineAnimation — sweeping gradient line
class CameraHudOverlay extends StatelessWidget {
  const CameraHudOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Camera feed placeholder ────────────────────────────────
        const ColoredBox(color: AppColors.background),

        // ── Vignette edges ─────────────────────────────────────────
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.1,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.55),
              ],
            ),
          ),
        ),

        // ── Skeleton wireframe ─────────────────────────────────────
        const SkeletonWireframe(),

        // ── Scan line ──────────────────────────────────────────────
        const ScanLineAnimation(),
      ],
    );
  }
}
