import 'dart:ui';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Compact rep-trend tile — one bar per week (oldest → current) with a
/// week-over-week delta chip, matching the glassmorphic [StatCard] look.
class WeekTrendCard extends StatelessWidget {
  const WeekTrendCard({super.key, required this.repsTrend});

  /// Reps per week, oldest first; last entry is the current partial week.
  final List<int> repsTrend;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;

    final maxReps =
        repsTrend.fold<int>(0, (max, v) => v > max ? v : max);
    final (deltaLabel, deltaColor) = _weekOverWeekDelta();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text('REP TREND', style: tt.eyebrow),
                  const Spacer(),
                  if (deltaLabel != null)
                    Text(
                      deltaLabel,
                      style: tt.statLabel.copyWith(
                        color: deltaColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < repsTrend.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: _TrendBar(
                          // Zero-rep weeks keep a faint stub so the week
                          // still reads as present rather than missing.
                          heightFactor: maxReps == 0
                              ? 0.08
                              : (repsTrend[i] / maxReps).clamp(0.08, 1.0),
                          isCurrentWeek: i == repsTrend.length - 1,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${repsTrend.length}W AGO', style: tt.statLabel.copyWith(fontSize: 9)),
                  Text('NOW', style: tt.statLabel.copyWith(fontSize: 9)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Current week vs the previous full week, e.g. `+18%`. Null when there is
  /// no previous-week baseline to compare against.
  (String?, Color) _weekOverWeekDelta() {
    if (repsTrend.length < 2) return (null, AppColors.mutedForeground);
    final current = repsTrend.last;
    final previous = repsTrend[repsTrend.length - 2];
    if (previous == 0) {
      return current > 0
          ? ('+$current reps', AppColors.success)
          : (null, AppColors.mutedForeground);
    }
    final pct = ((current - previous) / previous * 100).round();
    if (pct == 0) return ('EVEN', AppColors.mutedForeground);
    return (
      '${pct > 0 ? '+' : ''}$pct% vs last week',
      pct > 0 ? AppColors.success : AppColors.destructive,
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({required this.heightFactor, required this.isCurrentWeek});

  final double heightFactor;
  final bool isCurrentWeek;

  @override
  Widget build(BuildContext context) {
    final color = isCurrentWeek
        ? AppColors.primary
        : AppColors.primary.withValues(alpha: 0.35);

    return FractionallySizedBox(
      alignment: Alignment.bottomCenter,
      heightFactor: heightFactor,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
          boxShadow: isCurrentWeek
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
