import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/territory/domain/entities/leaderboard_entry_entity.dart';
import 'package:awaken/features/territory/presentation/widgets/leaderboard/leaderboard_format.dart';
import 'package:flutter/material.dart';

class LeaderboardRankRow extends StatelessWidget {
  const LeaderboardRankRow({
    super.key,
    required this.entry,
    required this.onTap,
    this.highlight = false,
    this.maxAreaSqMeters,
  });

  final LeaderboardEntryEntity entry;
  final VoidCallback onTap;
  final bool highlight;
  final double? maxAreaSqMeters;

  @override
  Widget build(BuildContext context) {
    final medal = medalColorForRank(entry.rank);
    final isTop = entry.rank <= 3;
    final fraction = maxAreaSqMeters == null
        ? null
        : entry.claimFractionAgainst(maxAreaSqMeters!);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(
            color: highlight
                ? AppColors.primary.withValues(alpha: 0.12)
                : AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlight
                  ? AppColors.primary.withValues(alpha: 0.55)
                  : isTop
                  ? medal.withValues(alpha: 0.35)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  '${entry.rank}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isTop ? medal : AppColors.mutedForeground,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              LeaderboardAvatar(
                displayName: entry.displayName,
                rank: isTop ? entry.rank : null,
                size: 38,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.displayName ?? 'Runner',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.foreground,
                              fontWeight: highlight
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (highlight) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (fraction != null) ...[
                      const SizedBox(height: 7),
                      LeaderboardClaimMeter(
                        fraction: fraction,
                        color: isTop ? medal : AppColors.primary,
                        height: 4,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              LeaderboardAreaLabel(
                areaSqMeters: entry.totalAreaSqMeters,
                color: isTop ? medal : AppColors.foreground,
                fontSize: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LeaderboardClimbHint extends StatelessWidget {
  const LeaderboardClimbHint({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.trending_up_rounded,
            color: AppColors.success,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.success,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LeaderboardEmptyState extends StatelessWidget {
  const LeaderboardEmptyState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.35),
                ),
              ),
              child: const Icon(
                Icons.flag_rounded,
                color: AppColors.accent,
                size: 32,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.mutedForeground,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LeaderboardSectionLabel extends StatelessWidget {
  const LeaderboardSectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 10,
          letterSpacing: 1.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
