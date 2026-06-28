import 'dart:math';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Circular streak progress ring. Drawn via CustomPainter.
/// Two passes per arc: blurred glow first, sharp line on top.
class StreakRing extends StatelessWidget {
  const StreakRing({
    super.key,
    required this.progress,
    required this.currentStreak,
    required this.bestStreak,
  });

  /// 0.0–1.0 (currentStreak / bestStreak)
  final double progress;
  final int currentStreak;
  final int bestStreak;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;

    return RepaintBoundary(
      child: SizedBox(
        width: 130,
        height: 130,
        child: CustomPaint(
          painter: _StreakRingPainter(progress: progress.clamp(0.0, 1.0)),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(height: 2),
                Text('$currentStreak', style: tt.statValue),
                Text('of $bestStreak', style: tt.statLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StreakRingPainter extends CustomPainter {
  const _StreakRingPainter({required this.progress});

  final double progress;

  static const double _strokeWidth = AppConstants.ringStrokeWidth;
  static const double _startAngle = -pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - _strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // ── Track ────────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppColors.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    final sweepAngle = 2 * pi * progress;

    // ── Glow pass ────────────────────────────────────────────────
    canvas.drawArc(
      rect,
      _startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth * 2.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // ── Sharp arc ────────────────────────────────────────────────
    canvas.drawArc(
      rect,
      _startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StreakRingPainter old) => old.progress != progress;
}
