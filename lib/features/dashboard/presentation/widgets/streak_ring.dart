import 'dart:io';
import 'dart:math';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Circular streak progress ring. Drawn via CustomPainter.
/// Two passes per arc: blurred glow first, sharp line on top.
class StreakRing extends StatefulWidget {
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
  State<StreakRing> createState() => _StreakRingState();
}

class _StreakRingState extends State<StreakRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    if (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST')) {
      _pulseController.repeat();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;

    return SizedBox(
      width: 130,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radar Sonar sweep behind
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = _pulseController.value;
              final opacity = (1.0 - scale) * 0.18;
              return Container(
                width: 96 * scale,
                height: 96 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: opacity),
                    width: 1.2,
                  ),
                ),
              );
            },
          ),

          // Painter
          RepaintBoundary(
            child: CustomPaint(
              size: const Size(130, 130),
              painter: _StreakRingPainter(
                progress: widget.progress.clamp(0.0, 1.0),
              ),
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
                    Text('${widget.currentStreak}', style: tt.statValue),
                    Text('of ${widget.bestStreak}', style: tt.statLabel),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakRingPainter extends CustomPainter {
  const _StreakRingPainter({required this.progress});

  final double progress;

  static const double _outerStrokeWidth = AppConstants.ringStrokeWidth;
  static const double _innerStrokeWidth = 3.0;
  static const double _startAngle = -pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = (size.shortestSide / 2) - _outerStrokeWidth / 2;
    final innerRadius = outerRadius - 14.0;

    final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
    final innerRect = Rect.fromCircle(center: center, radius: innerRadius);

    // ── 1. Outer Track ───────────────────────────────────────────
    canvas.drawCircle(
      center,
      outerRadius,
      Paint()
        ..color = AppColors.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = _outerStrokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // ── 2. Inner Track (Static Grid Ring) ────────────────────────
    canvas.drawCircle(
      center,
      innerRadius,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = _innerStrokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress <= 0) return;

    final sweepAngle = 2 * pi * progress;
    final innerStartAngle = _startAngle + (progress * pi); // Spinning offset

    // ── 3. Outer Glow Pass ───────────────────────────────────────
    canvas.drawArc(
      outerRect,
      _startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = AppColors.primary.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _outerStrokeWidth * 2.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // ── 4. Outer Sharp Arc ───────────────────────────────────────
    canvas.drawArc(
      outerRect,
      _startAngle,
      sweepAngle,
      false,
      Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = _outerStrokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // ── 5. Inner Glow Pass (Accent Violet) ───────────────────────
    canvas.drawArc(
      innerRect,
      innerStartAngle,
      sweepAngle,
      false,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _innerStrokeWidth * 2.5
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // ── 6. Inner Sharp Arc (Accent Violet) ───────────────────────
    canvas.drawArc(
      innerRect,
      innerStartAngle,
      sweepAngle,
      false,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = _innerStrokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StreakRingPainter old) => old.progress != progress;
}
