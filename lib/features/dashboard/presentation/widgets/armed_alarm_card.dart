import 'dart:ui';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Armed alarm card — shows the next alarm time and the Wake Up Tax (rep count).
/// Upgraded with glassmorphism and cyan outline accents.
class ArmedAlarmCard extends StatelessWidget {
  const ArmedAlarmCard({
    super.key,
    required this.alarmTime,
    required this.requiredReps,
  });

  final DateTime alarmTime;
  final int requiredReps;

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 0.8),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Glowing alarm icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(Icons.alarm, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 16),

              // Time and status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NEXT ALARM', style: tt.eyebrow),
                    const SizedBox(height: 4),
                    Text(_formatTime(alarmTime), style: theme.textTheme.headlineSmall),
                  ],
                ),
              ),

              // Wake Up Tax chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppConstants.chipRadius),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$requiredReps',
                      style: tt.statValue.copyWith(color: AppColors.accent),
                    ),
                    Text(
                      'SQUATS',
                      style: tt.eyebrow.copyWith(
                        color: AppColors.accent,
                        letterSpacing: 1.5,
                        fontSize: 9,
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
