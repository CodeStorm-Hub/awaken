import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Streak badge with optional previous→current delta (e.g. "4 → 5").
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.streak, this.previousStreak});

  final int streak;
  final int? previousStreak;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;
    final showDelta =
        previousStreak != null &&
        previousStreak! >= 0 &&
        previousStreak! < streak;
    final streakLabel = showDelta ? '$previousStreak → $streak' : '$streak';

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              for (int i = 0; i < 3; i++)
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                )
                .animate(delay: (i * 150).ms)
                .scale(
                  begin: const Offset(0.3, 0.3),
                  end: const Offset(1.8, 1.8),
                  duration: 800.ms,
                  curve: Curves.easeOutCubic,
                )
                .fadeOut(duration: 800.ms),

              RotatedBox(
                quarterTurns: 1,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success,
                      width: 2.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.successGlow,
                        blurRadius: 28,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                  child: const RotatedBox(
                    quarterTurns: 3,
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: AppColors.success,
                      size: 28,
                    ),
                  ),
                ),
              )
              .animate()
              .scale(
                begin: const Offset(0.0, 0.0),
                end: const Offset(1.0, 1.0),
                duration: 600.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 200.ms),
            ],
          ),

          const SizedBox(height: 20),

          Text.rich(
                TextSpan(
                  style: tt.hudRepCounter.copyWith(fontSize: 48),
                  children: [
                    TextSpan(text: streakLabel),
                    const TextSpan(
                      text: ' 🔥',
                      style: TextStyle(color: AppColors.success, fontSize: 36),
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
