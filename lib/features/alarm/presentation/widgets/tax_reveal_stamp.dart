import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_exercise_type.dart';
import 'package:flutter/material.dart';

/// Full-bleed neon stamp shown briefly when the wake-up tax is revealed.
class TaxRevealStamp extends StatelessWidget {
  const TaxRevealStamp({
    super.key,
    required this.exercise,
    required this.reps,
    this.penaltyMultiplier = 1,
  });

  final AlarmExerciseType exercise;
  final int reps;
  final int penaltyMultiplier;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.92),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (penaltyMultiplier > 1) ...[
              Text(
                'BAILOUT PENALTY · $penaltyMultiplier×',
                style: const TextStyle(
                  color: AppColors.destructive,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'TAX',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 6,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${exercise.taxStampLabel} × $reps',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.foreground,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 20),
            Container(width: 48, height: 3, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

/// Animated wrapper that fades the stamp out after [AppConstants.taxRevealDuration].
class TaxRevealOverlay extends StatefulWidget {
  const TaxRevealOverlay({
    super.key,
    required this.visible,
    required this.child,
  });

  final bool visible;
  final Widget child;

  @override
  State<TaxRevealOverlay> createState() => _TaxRevealOverlayState();
}

class _TaxRevealOverlayState extends State<TaxRevealOverlay> {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: AppConstants.mediumAnim,
        child: widget.child,
      ),
    );
  }
}
