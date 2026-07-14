import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/territory/domain/entities/nemesis_entity.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Dashboard card that surfaces the current user's nemesis — the rival with
/// the most mutual territory disputes. Only rendered when nemesis data exists.
class NemesisCard extends StatelessWidget {
  const NemesisCard({super.key, required this.nemesis});

  final NemesisEntity nemesis;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;
    final total = nemesis.totalDisputedSqMeters;
    final myFraction = total > 0 ? nemesis.myDisputedSqMeters / total : 0.5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(
          color: AppColors.destructive.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Eyebrow ──────────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.gps_fixed_rounded,
                color: AppColors.destructive,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'NEMESIS · @${nemesis.rivalDisplayName}',
                  style: tt.eyebrow.copyWith(
                    color: AppColors.destructive,
                    letterSpacing: 1.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${nemesis.mutualStealCount}× clash',
                style: tt.statLabel.copyWith(
                  color: AppColors.mutedForeground,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Disputed m² bar ──────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'YOU  ${_fmt(nemesis.myDisputedSqMeters)} m²',
                    style: tt.statLabel.copyWith(
                      fontSize: 10,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '${_fmt(nemesis.rivalDisputedSqMeters)} m²  THEM',
                    style: tt.statLabel.copyWith(
                      fontSize: 10,
                      color: AppColors.destructive,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 6,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final myWidth = constraints.maxWidth * myFraction;
                      return Row(
                        children: [
                          Container(width: myWidth, color: AppColors.primary),
                          Expanded(
                            child: Container(color: AppColors.destructive),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── CTA ───────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.go(AppRoutes.territory),
              icon: const Icon(Icons.map_rounded, size: 16),
              label: const Text('Hunt on map'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.destructive,
                side: BorderSide(
                  color: AppColors.destructive.withValues(alpha: 0.6),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(double sqm) {
    if (sqm >= 1_000_000) {
      return '${(sqm / 1_000_000).toStringAsFixed(2)} km²';
    }
    if (sqm >= 1000) {
      return '${(sqm / 1000).toStringAsFixed(1)}k';
    }
    return sqm.toStringAsFixed(0);
  }
}
