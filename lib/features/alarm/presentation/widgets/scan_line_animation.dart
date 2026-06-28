import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Horizontal gradient line that sweeps top-to-bottom on a 2-second loop.
/// Wrapped in [RepaintBoundary] — composited on its own GPU layer.
class ScanLineAnimation extends StatelessWidget {
  const ScanLineAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            return Align(
              alignment: Alignment.topCenter,
              child: const _ScanLine()
                  .animate(onPlay: (c) => c.repeat())
                  .moveY(
                    begin: 0,
                    end: height,
                    duration: AppConstants.scanLineDuration,
                    curve: Curves.linear,
                  ),
            );
          },
        ),
      ),
    );
  }
}

class _ScanLine extends StatelessWidget {
  const _ScanLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.primary.withValues(alpha: 0.5),
            AppColors.primary.withValues(alpha: 0.9),
            AppColors.primary.withValues(alpha: 0.5),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.6),
            blurRadius: AppConstants.glowBlurRadius,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
