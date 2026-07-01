import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/leaderboard_entry_entity.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

class TerritoryLeaderboardScreen extends ConsumerStatefulWidget {
  const TerritoryLeaderboardScreen({super.key});

  @override
  ConsumerState<TerritoryLeaderboardScreen> createState() => _TerritoryLeaderboardScreenState();
}

class _TerritoryLeaderboardScreenState extends ConsumerState<TerritoryLeaderboardScreen> {
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
      // No location available — provider falls back to the global view.
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.foreground),
          onPressed: () => context.pop(),
        ),
        title: Text('LEADERBOARD', style: hud.eyebrow),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.screenPaddingH),
        child: Column(
          children: [
            const SizedBox(height: 8),
            _ModeSegmentedControl(
              mode: mode,
              onChanged: (m) => ref.read(leaderboardModeProvider.notifier).state = m,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: leaderboardAsync.when(
                data: (entries) => _LeaderboardList(entries: entries, mode: mode),
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (error, stackTrace) => const Center(
                  child: Text(
                    'Could not load leaderboard.',
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

class _ModeSegmentedControl extends StatelessWidget {
  const _ModeSegmentedControl({required this.mode, required this.onChanged});

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
                  borderRadius: BorderRadius.circular(AppConstants.chipRadius - 4),
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

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({required this.entries, required this.mode});

  final List<LeaderboardEntryEntity> entries;
  final LeaderboardMode mode;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text(
          mode == LeaderboardMode.nearby
              ? 'No territory claimed near you yet.\nBe the first to run a loop!'
              : 'No territory claimed yet.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.mutedForeground),
        ),
      );
    }

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _LeaderboardTile(entry: entries[index]),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.entry});

  final LeaderboardEntryEntity entry;

  @override
  Widget build(BuildContext context) {
    final hud = Theme.of(context).extension<AwakenTypography>()!;
    final areaKm2 = entry.totalAreaSqMeters / 1000000;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: entry.rank <= 3 ? Border.all(color: AppColors.accent.withValues(alpha: 0.4)) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '#${entry.rank}',
              style: hud.statValue.copyWith(
                fontSize: 16,
                color: entry.rank <= 3 ? AppColors.accent : AppColors.mutedForeground,
              ),
            ),
          ),
          const SizedBox(width: 8),
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
