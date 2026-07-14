import 'dart:ui';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_exercise_type.dart';
import 'package:flutter/material.dart';

/// Armed alarm card — hero next-alarm CTA with Wake Up Tax framing.
class ArmedAlarmCard extends StatelessWidget {
  const ArmedAlarmCard({
    super.key,
    required this.alarmTime,
    required this.requiredReps,
    this.exerciseMode = AlarmExerciseMode.fixed,
    this.exerciseType = AlarmExerciseType.squats,
    this.penaltyMultiplier = 1,
  });

  final DateTime alarmTime;
  final int requiredReps;
  final AlarmExerciseMode exerciseMode;
  final AlarmExerciseType? exerciseType;
  final int penaltyMultiplier;

  String _formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;
    final theme = Theme.of(context);
    final exerciseLabel = exerciseMode == AlarmExerciseMode.roulette
        ? 'ROULETTE'
        : (exerciseType ?? AlarmExerciseType.squats).taxStampLabel;
    final effectiveReps = requiredReps * penaltyMultiplier.clamp(1, 4);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.55),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Icon(
                      Icons.alarm,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'NEXT WAKE UP TAX',
                      style: tt.eyebrow.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(
                        AppConstants.chipRadius,
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      exerciseLabel,
                      style: tt.eyebrow.copyWith(fontSize: 9, letterSpacing: 1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _formatTime(alarmTime),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.05,
                ),
              ),
              if (penaltyMultiplier > 1) ...[
                const SizedBox(height: 10),
                Text(
                  'BAILOUT · $penaltyMultiplier× TAX',
                  style: tt.eyebrow.copyWith(color: AppColors.destructive),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppConstants.chipRadius),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.45),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$effectiveReps',
                      style: tt.statValue.copyWith(
                        color: AppColors.accent,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'REPS TO DISMISS',
                      style: tt.eyebrow.copyWith(
                        color: AppColors.accent,
                        letterSpacing: 1.5,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
