import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/territory/domain/entities/leaderboard_entry_entity.dart';
import 'package:awaken/features/territory/presentation/widgets/leaderboard/leaderboard_format.dart';
import 'package:flutter/material.dart';

/// Top-three spotlight: claim-meter pillars with medal rings (2 | 1 | 3).
class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({
    super.key,
    required this.entries,
    required this.onEntryTap,
  });

  final List<LeaderboardEntryEntity> entries;
  final ValueChanged<LeaderboardEntryEntity> onEntryTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    if (entries.length == 1) {
      return _SoloChampion(
        entry: entries.first,
        onTap: () => onEntryTap(entries.first),
      );
    }

    final first = entries[0];
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;
    final maxArea = first.totalAreaSqMeters;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.10),
            AppColors.card,
          ],
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: second == null
                ? const SizedBox.shrink()
                : _PodiumColumn(
                    entry: second,
                    maxArea: maxArea,
                    pillarHeight: 72,
                    onTap: () => onEntryTap(second),
                  ),
          ),
          Expanded(
            flex: 2,
            child: _PodiumColumn(
              entry: first,
              maxArea: maxArea,
              pillarHeight: 108,
              featured: true,
              onTap: () => onEntryTap(first),
            ),
          ),
          Expanded(
            child: third == null
                ? const SizedBox.shrink()
                : _PodiumColumn(
                    entry: third,
                    maxArea: maxArea,
                    pillarHeight: 56,
                    onTap: () => onEntryTap(third),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SoloChampion extends StatelessWidget {
  const _SoloChampion({required this.entry, required this.onTap});

  final LeaderboardEntryEntity entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final medal = medalColorForRank(entry.rank);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              medal.withValues(alpha: 0.18),
              AppColors.card,
              AppColors.primary.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(color: medal.withValues(alpha: 0.45)),
        ),
        child: Column(
          children: [
            LeaderboardAvatar(
              displayName: entry.displayName,
              rank: entry.rank,
              size: 64,
            ),
            const SizedBox(height: 12),
            Text(
              'RANK #${entry.rank}',
              style: TextStyle(
                color: medal,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              entry.displayName ?? 'Runner',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.foreground,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            LeaderboardAreaLabel(
              areaSqMeters: entry.totalAreaSqMeters,
              color: medal,
              fontSize: 22,
            ),
            const SizedBox(height: 14),
            LeaderboardClaimMeter(
              fraction: 1,
              color: medal,
              height: 8,
            ),
          ],
        ),
      ),
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.entry,
    required this.maxArea,
    required this.pillarHeight,
    required this.onTap,
    this.featured = false,
  });

  final LeaderboardEntryEntity entry;
  final double maxArea;
  final double pillarHeight;
  final VoidCallback onTap;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final medal = medalColorForRank(entry.rank);
    final fraction = entry.claimFractionAgainst(maxArea);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LeaderboardAvatar(
            displayName: entry.displayName,
            rank: entry.rank,
            size: featured ? 52 : 40,
          ),
          const SizedBox(height: 8),
          Text(
            entry.displayName ?? 'Runner',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.foreground,
              fontWeight: featured ? FontWeight.w800 : FontWeight.w600,
              fontSize: featured ? 13 : 11,
            ),
          ),
          const SizedBox(height: 4),
          LeaderboardAreaLabel(
            areaSqMeters: entry.totalAreaSqMeters,
            color: medal,
            fontSize: featured ? 13 : 11,
          ),
          const SizedBox(height: 10),
          Container(
            height: pillarHeight,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              color: medal.withValues(alpha: featured ? 0.22 : 0.12),
              border: Border.all(color: medal.withValues(alpha: 0.45)),
              boxShadow: featured
                  ? [
                      BoxShadow(
                        color: medal.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              children: [
                Text(
                  '#${entry.rank}',
                  style: TextStyle(
                    color: medal,
                    fontWeight: FontWeight.w900,
                    fontSize: featured ? 20 : 15,
                  ),
                ),
                const Spacer(),
                LeaderboardClaimMeter(
                  fraction: fraction,
                  color: medal,
                  height: featured ? 7 : 5,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
