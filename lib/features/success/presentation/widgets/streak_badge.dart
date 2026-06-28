import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// "Streak +1" pop-in badge.
/// Animates with a scale overshoot (easeOutBack) + fade-in on first build.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glowing checkmark circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.successGlow,
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: 40,
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 200.ms),

          const SizedBox(height: 20),

          // Streak counter
          Text.rich(
            TextSpan(
              style: tt.hudRepCounter.copyWith(fontSize: 56),
              children: const [
                TextSpan(
                  text: ' 🔥',
                  style: TextStyle(color: AppColors.success),
                ),
              ],
            ),
          )
              .animate(delay: 250.ms)
              .fadeIn(duration: 400.ms)
              .slideY(
                begin: 0.2,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOut,
              ),

          const SizedBox(height: 8),

          Text(
            'DAY STREAK',
            style: tt.eyebrow.copyWith(
              color: AppColors.success,
              letterSpacing: 4,
            ),
          ).animate(delay: 350.ms).fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}
