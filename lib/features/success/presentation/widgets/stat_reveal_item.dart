import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Single stat row that floats up with a staggered delay on the success screen.
class StatRevealItem extends StatelessWidget {
  const StatRevealItem({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.delay,
    this.accentColor = AppColors.primary,
  });

  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Duration delay;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;

    return RepaintBoundary(
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(width: 14),

          // Label
          Expanded(
            child: Text(
              label,
              style: tt.statLabel.copyWith(fontSize: 13),
            ),
          ),

          // Value + unit
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: tt.statValue.copyWith(fontSize: 22, color: accentColor),
                ),
                TextSpan(text: ' $unit', style: tt.statLabel),
              ],
            ),
          ),
        ],
      )
          .animate(delay: delay)
          .fadeIn(duration: 400.ms)
          .slideY(
            begin: 0.25,
            end: 0,
            duration: 400.ms,
            curve: Curves.easeOutCubic,
          ),
    );
  }
}
