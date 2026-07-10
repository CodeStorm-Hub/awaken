import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Primary run HUD signal: progress toward closing the current loop.
class LoopClosureProgressBar extends StatelessWidget {
  const LoopClosureProgressBar({
    super.key,
    required this.metersToStart,
    required this.closureRadiusMeters,
  });

  final double metersToStart;
  final double closureRadiusMeters;

  @override
  Widget build(BuildContext context) {
    final progress = (1.0 -
            (metersToStart / AppConstants.loopClosureGraceMeters).clamp(0.0, 1.0))
        .clamp(0.0, 1.0);
    final canClose = metersToStart <= closureRadiusMeters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          canClose
              ? 'LOOP READY — CLOSE IT'
              : '${metersToStart.round()} m TO CLOSE',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: canClose ? AppColors.success : AppColors.mutedForeground,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.secondary,
            color: canClose ? AppColors.success : AppColors.primary,
          ),
        ),
      ],
    );
  }
}
