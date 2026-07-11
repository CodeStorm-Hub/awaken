import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Horizontal gradient line that sweeps top-to-bottom on a 2-second loop.
class ScanLineAnimation extends StatelessWidget {
  const ScanLineAnimation({super.key, this.accentColor});

  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.primary;
    return RepaintBoundary(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            return Align(
              alignment: Alignment.topCenter,
              child: _ScanLine(accent: accent)
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
  const _ScanLine({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            accent.withValues(alpha: 0.5),
            accent.withValues(alpha: 0.9),
            accent.withValues(alpha: 0.5),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.6),
            blurRadius: AppConstants.glowBlurRadius,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
