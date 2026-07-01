import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/leaderboard_entry_entity.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class TerritoryLeaderboardScreen extends ConsumerStatefulWidget {
  const TerritoryLeaderboardScreen({super.key});

  @override
  ConsumerState<TerritoryLeaderboardScreen> createState() =>
      _TerritoryLeaderboardScreenState();
}

class _TerritoryLeaderboardScreenState
    extends ConsumerState<TerritoryLeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureViewerLocation());
  }

  Future<void> _ensureViewerLocation() async {
    if (ref.read(viewerLocationProvider) != null) return;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 6));
      if (!mounted) return;
      ref.read(viewerLocationProvider.notifier).state = GeoPointEntity(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      // No location — falls back to global view.
    }
  }

  @override
  Widget build(BuildContext context) {
    final hud = Theme.of(context).extension<AwakenTypography>()!;
    final mode = ref.watch(leaderboardModeProvider);
    final leaderboardAsync = ref.watch(leaderboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Text('LEADERBOARD', style: hud.eyebrow),
        centerTitle: true,
        actions: [
          // Refresh
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.mutedForeground, size: 20),
            onPressed: () => ref.invalidate(leaderboardProvider),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.screenPaddingH),
        child: Column(
          children: [
            const SizedBox(height: 4),
            // ── Mode selector ──────────────────────────────────────────────
            _ModeSegmentedControl(
              mode: mode,
              onChanged: (m) =>
                  ref.read(leaderboardModeProvider.notifier).state = m,
            ),
            const SizedBox(height: 20),
            // ── List ───────────────────────────────────────────────────────
            Expanded(
              child: leaderboardAsync.when(
                data: (entries) =>
                    _LeaderboardContent(entries: entries, mode: mode),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (_, _) => const Center(
                  child: Text(
                    'Could not load leaderboard.\nCheck your connection.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.mutedForeground),
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

// ── Mode tab ──────────────────────────────────────────────────────────────────

class _ModeSegmentedControl extends StatelessWidget {
  const _ModeSegmentedControl(
      {required this.mode, required this.onChanged});

  final LeaderboardMode mode;
  final ValueChanged<LeaderboardMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(AppConstants.chipRadius),
      ),
      child: Row(
        children: LeaderboardMode.values.map((m) {
          final selected = m == mode;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(m),
              child: AnimatedContainer(
                duration: AppConstants.shortAnim,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(AppConstants.chipRadius - 4),
                ),
                alignment: Alignment.center,
                child: Text(
                  m == LeaderboardMode.nearby ? 'NEARBY' : 'GLOBAL',
                  style: TextStyle(
                    color: selected ? Colors.black : AppColors.mutedForeground,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Content ───────────────────────────────────────────────────────────────────

class _LeaderboardContent extends StatelessWidget {
  const _LeaderboardContent(
      {required this.entries, required this.mode});

  final List<LeaderboardEntryEntity> entries;
  final LeaderboardMode mode;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.map_outlined,
                  color: AppColors.mutedForeground, size: 48),
              const SizedBox(height: 16),
              Text(
                mode == LeaderboardMode.nearby
                    ? 'No territory claimed near you yet.\nBe the first to run a loop!'
                    : 'No territory claimed yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.mutedForeground, height: 1.6),
              ),
            ],
          ),
        ),
      );
    }

    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return ListView(
      children: [
        // ── Podium ──────────────────────────────────────────────────────
        if (top3.isNotEmpty) ...[
          _Podium(entries: top3),
          const SizedBox(height: 20),
        ],
        // ── Remaining ranks ──────────────────────────────────────────────
        if (rest.isNotEmpty)
          ...rest.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LeaderboardTile(entry: e),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Podium ────────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  const _Podium({required this.entries});

  final List<LeaderboardEntryEntity> entries;

  @override
  Widget build(BuildContext context) {
    // Podium order: 2nd | 1st | 3rd
    final first = entries.isNotEmpty ? entries[0] : null;
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    final podiumEntries = [second, first, third];
    final heights = [90.0, 120.0, 70.0];
    final medals = ['🥈', '🥇', '🥉'];
    final colors = [
      const Color(0xFF9E9E9E), // silver
      const Color(0xFFFFD700), // gold
      const Color(0xFFCD7F32), // bronze
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          final entry = podiumEntries[i];
          if (entry == null) return const Expanded(child: SizedBox.shrink());
          return Expanded(
            child: _PodiumSlot(
              entry: entry,
              barHeight: heights[i],
              medal: medals[i],
              color: colors[i],
            ),
          );
        }),
      ),
    );
  }
}

class _PodiumSlot extends StatelessWidget {
  const _PodiumSlot({
    required this.entry,
    required this.barHeight,
    required this.medal,
    required this.color,
  });

  final LeaderboardEntryEntity entry;
  final double barHeight;
  final String medal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final hud = Theme.of(context).extension<AwakenTypography>()!;
    final areaKm2 = entry.totalAreaSqMeters / 1_000_000;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Medal emoji
        Text(medal, style: const TextStyle(fontSize: 28)),
        const SizedBox(height: 4),
        // Name
        Text(
          entry.displayName ?? 'Runner',
          style: const TextStyle(
            color: AppColors.foreground,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        // Area
        Text(
          '${areaKm2.toStringAsFixed(3)} km²',
          style: hud.statValue.copyWith(fontSize: 11, color: color),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Podium bar
        Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          alignment: Alignment.center,
          child: Text(
            '#${entry.rank}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Rank tile ─────────────────────────────────────────────────────────────────

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.entry});

  final LeaderboardEntryEntity entry;

  @override
  Widget build(BuildContext context) {
    final hud = Theme.of(context).extension<AwakenTypography>()!;
    final areaKm2 = entry.totalAreaSqMeters / 1_000_000;

    final isTopRank = entry.rank <= 3;
    final rankColor = isTopRank ? AppColors.accent : AppColors.mutedForeground;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: isTopRank
            ? Border.all(color: AppColors.accent.withValues(alpha: 0.3))
            : Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              '#${entry.rank}',
              style: hud.statValue.copyWith(
                fontSize: 16,
                color: rankColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Avatar placeholder (initials circle)
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              (entry.displayName ?? 'R').substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.displayName ?? 'Runner',
              style: const TextStyle(
                color: AppColors.foreground,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${areaKm2.toStringAsFixed(3)} km²',
            style: hud.statValue.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
