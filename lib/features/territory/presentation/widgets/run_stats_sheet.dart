import 'dart:ui';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Glassmorphic HUD card shown during an active run.
/// Shows distance, elapsed time, optional speed warning, and how far the
/// runner is from closing their loop back to the start.
class RunStatsSheet extends StatelessWidget {
  const RunStatsSheet({
    super.key,
    required this.distanceMeters,
    required this.elapsed,
    this.isOverSpeed = false,
    this.distToStartMeters,
  });

  final double distanceMeters;
  final Duration elapsed;
  final bool isOverSpeed;

  /// Distance back to the start point in meters. Null when not yet tracking.
  final double? distToStartMeters;

  @override
  Widget build(BuildContext context) {
    final hud = Theme.of(context).extension<AwakenTypography>()!;

    final minutes =
        elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    final distKm = (distanceMeters / 1000).toStringAsFixed(2);
    final closureLabel = _closureLabel(distToStartMeters);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Stat(
                    label: 'DISTANCE',
                    value: '$distKm km',
                    hud: hud,
                  ),
                  _Stat(
                    label: 'TIME',
                    value: '$minutes:$seconds',
                    hud: hud,
                  ),
                  if (isOverSpeed)
                    _Stat(
                      label: 'SPEED',
                      value: 'TOO FAST',
                      hud: hud,
                      valueColor: AppColors.destructive,
                    )
                  else if (closureLabel != null)
                    _Stat(
                      label: 'TO START',
                      value: closureLabel,
                      hud: hud,
                      valueColor: _closureColor(distToStartMeters),
                    ),
                ],
              ),
              if (isOverSpeed) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.destructive.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'Vehicle detected — territory will not be claimed',
                    style: hud.statLabel.copyWith(
                      color: AppColors.destructive,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String? _closureLabel(double? dist) {
    if (dist == null || dist.isInfinite) return null;
    if (dist < 1000) {
      return '${dist.toStringAsFixed(0)} m';
    }
    return '${(dist / 1000).toStringAsFixed(2)} km';
  }

  static Color _closureColor(double? dist) {
    if (dist == null || dist.isInfinite) return AppColors.mutedForeground;
    if (dist <= AppConstants.loopClosureRadiusMeters) return AppColors.success;
    if (dist <= 100) return AppColors.primary;
    return AppColors.foreground;
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.hud,
    this.valueColor,
  });

  final String label;
  final String value;
  final AwakenTypography hud;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: hud.statLabel),
        const SizedBox(height: 2),
        Text(
          value,
          style: hud.statValue.copyWith(
            fontSize: 18,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
