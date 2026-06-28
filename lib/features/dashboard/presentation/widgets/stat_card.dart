import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

/// Reusable stat tile — eyebrow label, large mono value, and unit.
/// Used in the 2-up grid on the dashboard.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    this.icon,
    this.accentColor = AppColors.primary,
  });

  final String label;
  final String value;
  final String unit;
  final Widget? icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Eyebrow row
          Row(
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 6),
              ],
              Text(label.toUpperCase(), style: tt.eyebrow),
            ],
          ),
          const SizedBox(height: 10),

          // Value + unit
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: tt.statValue.copyWith(color: accentColor),
                ),
                TextSpan(
                  text: ' $unit',
                  style: tt.statLabel,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
