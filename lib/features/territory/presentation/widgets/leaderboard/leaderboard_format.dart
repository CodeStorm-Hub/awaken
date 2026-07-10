import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/territory/domain/entities/leaderboard_entry_entity.dart';
import 'package:flutter/material.dart';

/// Formats territory area for HUD display.
String formatLeaderboardAreaKm2(double areaSqMeters) {
  final km2 = areaSqMeters / 1_000_000;
  if (km2 >= 10) return '${km2.toStringAsFixed(1)} km²';
  if (km2 >= 0.01) return '${km2.toStringAsFixed(3)} km²';
  if (areaSqMeters >= 1) return '${areaSqMeters.round()} m²';
  return '0 m²';
}

String leaderboardInitials(String? displayName) {
  final name = (displayName ?? 'R').trim();
  if (name.isEmpty) return 'R';
  final parts = name.split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  return name.substring(0, 1).toUpperCase();
}

Color medalColorForRank(int rank) {
  return switch (rank) {
    1 => AppColors.medalGold,
    2 => AppColors.medalSilver,
    3 => AppColors.medalBronze,
    _ => AppColors.mutedForeground,
  };
}

class LeaderboardAvatar extends StatelessWidget {
  const LeaderboardAvatar({
    super.key,
    required this.displayName,
    this.rank,
    this.size = 40,
  });

  final String? displayName;
  final int? rank;
  final double size;

  @override
  Widget build(BuildContext context) {
    final medal = rank != null ? medalColorForRank(rank!) : AppColors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: medal.withValues(alpha: 0.14),
        border: Border.all(color: medal.withValues(alpha: 0.55), width: 1.5),
      ),
      alignment: Alignment.center,
      child: Text(
        leaderboardInitials(displayName),
        style: TextStyle(
          color: medal,
          fontSize: size * 0.32,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class LeaderboardAreaLabel extends StatelessWidget {
  const LeaderboardAreaLabel({
    super.key,
    required this.areaSqMeters,
    this.color,
    this.fontSize = 14,
  });

  final double areaSqMeters;
  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final hud = Theme.of(context).extension<AwakenTypography>()!;
    return Text(
      formatLeaderboardAreaKm2(areaSqMeters),
      style: hud.statValue.copyWith(
        fontSize: fontSize,
        color: color ?? AppColors.foreground,
      ),
    );
  }
}

/// Relative claim-fill bar used on the podium (signature visual).
class LeaderboardClaimMeter extends StatelessWidget {
  const LeaderboardClaimMeter({
    super.key,
    required this.fraction,
    required this.color,
    this.height = 6,
  });

  final double fraction;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: color.withValues(alpha: 0.15)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction.clamp(0.0, 1.0),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.55),
                      color,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension LeaderboardEntryUi on LeaderboardEntryEntity {
  double claimFractionAgainst(double maxAreaSqMeters) {
    if (maxAreaSqMeters <= 0) return 0;
    return (totalAreaSqMeters / maxAreaSqMeters).clamp(0.0, 1.0);
  }
}
