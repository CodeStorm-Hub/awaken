import 'dart:ui';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Glassmorphic floating stats card (distance, time, live area) shown
/// during an active run — `BackdropFilter` blur per the plan's "floating
/// UI" requirement, with Impeller assumed enabled for blur performance.
class RunStatsSheet extends StatelessWidget {
  const RunStatsSheet({
    super.key,
    required this.distanceMeters,
    required this.elapsed,
    this.isOverSpeed = false,
  });

  final double distanceMeters;
  final Duration elapsed;
  final bool isOverSpeed;

  @override
  Widget build(BuildContext context) {
    final hud = Theme.of(context).extension<AwakenTypography>()!;
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _Stat(label: 'DISTANCE', value: '${(distanceMeters / 1000).toStringAsFixed(2)} km', hud: hud),
              _Stat(label: 'TIME', value: '$minutes:$seconds', hud: hud),
              if (isOverSpeed)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SPEED', style: hud.statLabel),
                    const SizedBox(height: 2),
                    Text(
                      'TOO FAST',
                      style: hud.statValue.copyWith(color: AppColors.destructive, fontSize: 16),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.hud});

  final String label;
  final String value;
  final AwakenTypography hud;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: hud.statLabel),
        const SizedBox(height: 2),
        Text(value, style: hud.statValue),
      ],
    );
  }
}
