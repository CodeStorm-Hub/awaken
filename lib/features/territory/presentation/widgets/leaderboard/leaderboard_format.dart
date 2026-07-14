import 'dart:math' as math;

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
    return CustomPaint(
      painter: DecagonBorderPainter(
        color: medal.withValues(alpha: 0.55),
        strokeWidth: 1.5,
      ),
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(2),
        child: ClipPath(
          clipper: const DecagonClipper(),
          child: ColoredBox(
            color: medal.withValues(alpha: 0.14),
            child: Align(
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
            ),
          ),
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
                    colors: [color.withValues(alpha: 0.55), color],
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

class DecagonClipper extends CustomClipper<Path> {
  const DecagonClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 2;

    for (int i = 0; i < 10; i++) {
      final angle = (i * 2 * math.pi / 10) - (math.pi / 2);
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class DecagonBorderPainter extends CustomPainter {
  const DecagonBorderPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = (size.width - strokeWidth) / 2;

    for (int i = 0; i < 10; i++) {
      final angle = (i * 2 * math.pi / 10) - (math.pi / 2);
      final x = centerX + radius * math.cos(angle);
      final y = centerY + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
