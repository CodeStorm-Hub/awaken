import 'dart:ui';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/territory/presentation/providers/active_run_providers.dart'
    show GpsQuality, gpsQualityFromAccuracy;
import 'package:flutter/material.dart';

/// Compact HUD card shown during an active run.
/// Shows distance, elapsed time, optional speed warning, GPS fix quality,
/// loop count, and how far the runner is from closing the active segment.
class RunStatsSheet extends StatelessWidget {
  const RunStatsSheet({
    super.key,
    required this.distanceMeters,
    required this.elapsed,
    this.isOverSpeed = false,
    this.distToSegmentStartMeters,
    this.gpsAccuracyMeters,
    this.pendingLoopCount = 0,
  });

  final double distanceMeters;
  final Duration elapsed;
  final bool isOverSpeed;

  /// Distance back to the active segment anchor in meters.
  final double? distToSegmentStartMeters;

  final double? gpsAccuracyMeters;
  final int pendingLoopCount;

  @override
  Widget build(BuildContext context) {
    final hud = Theme.of(context).extension<AwakenTypography>()!;

    final minutes =
        elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    final distKm = (distanceMeters / 1000).toStringAsFixed(2);
    final closureLabel = _closureLabel(distToSegmentStartMeters);

    final guidance = isOverSpeed
        ? 'Vehicle speed detected — this run will not be claimed.'
        : pendingLoopCount > 0
            ? '$pendingLoopCount loop${pendingLoopCount == 1 ? '' : 's'} ready — keep running or stop to claim.'
            : closureLabel != null
                ? 'Return to your segment start to close the loop.'
                : 'Keep moving to close the loop.';

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.68),
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 18,
                      runSpacing: 8,
                      children: [
                        _Stat(
                          label: 'Distance',
                          value: '$distKm km',
                          hud: hud,
                        ),
                        _Stat(
                          label: 'Time',
                          value: '$minutes:$seconds',
                          hud: hud,
                        ),
                        if (pendingLoopCount > 0)
                          _Stat(
                            label: 'Loops',
                            value: '$pendingLoopCount',
                            hud: hud,
                            valueColor: AppColors.success,
                          ),
                        if (isOverSpeed)
                          _Stat(
                            label: 'Speed',
                            value: 'Too fast',
                            hud: hud,
                            valueColor: AppColors.destructive,
                          )
                        else if (closureLabel != null)
                          _Stat(
                            label: 'To segment',
                            value: closureLabel,
                            hud: hud,
                            valueColor: _closureColor(distToSegmentStartMeters),
                          ),
                      ],
                    ),
                  ),
                  _GpsQualityChip(
                    quality: gpsQualityFromAccuracy(gpsAccuracyMeters),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                guidance,
                style: hud.statLabel.copyWith(
                  color: isOverSpeed
                      ? AppColors.destructive
                      : AppColors.mutedForeground,
                  fontSize: 10,
                  letterSpacing: 0.8,
                ),
              ),
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

/// Colored-dot chip showing live GPS fix quality (good/fair/poor), derived
/// from `Position.accuracy`. A quiet signal for why a run's path might look
/// jagged or why loop closure is being finicky — never blocks anything on
/// its own.
class _GpsQualityChip extends StatelessWidget {
  const _GpsQualityChip({required this.quality});

  final GpsQuality quality;

  @override
  Widget build(BuildContext context) {
    if (quality == GpsQuality.unknown) return const SizedBox.shrink();

    final (label, color) = switch (quality) {
      GpsQuality.good => ('GPS good', AppColors.success),
      GpsQuality.fair => ('GPS fair', AppColors.primary),
      GpsQuality.poor => ('GPS poor', AppColors.destructive),
      GpsQuality.unknown => ('', AppColors.mutedForeground),
    };

    return Padding(
      padding: const EdgeInsets.only(left: 10, top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
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
        Text(
          label,
          style: hud.statLabel.copyWith(
            color: AppColors.mutedForeground,
            fontSize: 10,
            letterSpacing: 1.1,
          ),
        ),
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
