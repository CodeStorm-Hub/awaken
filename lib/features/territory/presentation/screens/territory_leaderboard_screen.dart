import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/leaderboard_entry_entity.dart';
import 'package:awaken/features/territory/domain/entities/territory_entity.dart';
import 'package:awaken/features/territory/domain/services/location_permission_helper.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

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
      // Must run before getCurrentPosition — see LocationPermissionHelper's
      // doc comment for why skipping this means the OS prompt never shows.
      await LocationPermissionHelper.ensureLocationAccess(
        serviceDisabledMessage: 'Turn on location services to see nearby rivals.',
        permissionDeniedMessage: 'Allow location access to see nearby rivals.',
      );
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
      // Denied, timed out, or services off — falls back to global view.
    }
  }

  /// Jumps the run-screen map to [entry]'s territory, if it's currently on
  /// the live shared map (`territoryListProvider`). Leaderboard entries
  /// carry no location of their own — see `territoryMapFocusProvider`'s
  /// doc comment for why this doesn't need a backend change, unlike the
  /// time-window filters below.
  void _onEntryTap(LeaderboardEntryEntity entry) {
    final territories = ref.read(territoryListProvider).valueOrNull ?? const [];
    TerritoryEntity? match;
    for (final t in territories) {
      if (t.userId == entry.userId) {
        match = t;
        break;
      }
    }
    final centroid = match == null ? null : territoryApproxCentroid(match);

    if (centroid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This runner\'s territory isn\'t on the live map right now.'),
        ),
      );
      return;
    }

    ref.read(territoryMapFocusProvider.notifier).state = centroid;
    context.go(AppRoutes.territory);
  }

  @override
  Widget build(BuildContext context) {
    final hud = Theme.of(context).extension<AwakenTypography>()!;
    final mode = ref.watch(leaderboardModeProvider);
    final window = ref.watch(leaderboardWindowProvider);
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
            _LeaderboardHeader(mode: mode, window: window),
            const SizedBox(height: 20),
            // ── Mode selector ──────────────────────────────────────────────
            _ModeSegmentedControl(
              mode: mode,
              onChanged: (m) =>
                  ref.read(leaderboardModeProvider.notifier).state = m,
            ),
            const SizedBox(height: 10),
            // ── Time window selector ─────────────────────────────────────────
            _WindowSegmentedControl(
              window: window,
              onChanged: (w) =>
                  ref.read(leaderboardWindowProvider.notifier).state = w,
            ),
            const SizedBox(height: 10),
            _ModeHint(mode: mode, window: window),
            const SizedBox(height: 16),
            // ── List ───────────────────────────────────────────────────────
            Expanded(
              child: leaderboardAsync.when(
                data: (entries) => _LeaderboardContent(
                  entries: entries,
                  mode: mode,
                  window: window,
                  onEntryTap: _onEntryTap,
                ),
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
                  m == LeaderboardMode.nearby ? 'Nearby' : 'Global',
                  style: TextStyle(
                    color: selected ? Colors.black : AppColors.mutedForeground,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.2,
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

// ── Window tab ────────────────────────────────────────────────────────────────

/// Smaller, secondary pill row beneath the Nearby/Global toggle — 24H/7D
/// rank by area *captured* in that window (momentum), ALL ranks by current
/// total ownership. See [LeaderboardWindow]'s doc comment for the distinction.
class _WindowSegmentedControl extends StatelessWidget {
  const _WindowSegmentedControl({required this.window, required this.onChanged});

  final LeaderboardWindow window;
  final ValueChanged<LeaderboardWindow> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: LeaderboardWindow.values.map((w) {
        final selected = w == window;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(w),
            child: AnimatedContainer(
              duration: AppConstants.shortAnim,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accent.withValues(alpha: 0.16)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(AppConstants.chipRadius),
                border: Border.all(
                  color: selected
                      ? AppColors.accent.withValues(alpha: 0.5)
                      : AppColors.border,
                ),
              ),
              child: Text(
                switch (w) {
                  LeaderboardWindow.day => '24H',
                  LeaderboardWindow.week => '7D',
                  LeaderboardWindow.allTime => 'ALL',
                },
                style: TextStyle(
                  color: selected ? AppColors.accent : AppColors.mutedForeground,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Content ───────────────────────────────────────────────────────────────────

class _LeaderboardContent extends StatelessWidget {
  const _LeaderboardContent({
    required this.entries,
    required this.mode,
    required this.window,
    required this.onEntryTap,
  });

  final List<LeaderboardEntryEntity> entries;
  final LeaderboardMode mode;
  final LeaderboardWindow window;
  final ValueChanged<LeaderboardEntryEntity> onEntryTap;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      final windowedEmpty = switch (window) {
        LeaderboardWindow.day => 'Nobody has captured territory in the last 24 hours yet.\nBe the first.',
        LeaderboardWindow.week => 'Nobody has captured territory in the last 7 days yet.\nBe the first.',
        LeaderboardWindow.allTime => mode == LeaderboardMode.nearby
            ? 'No nearby territory yet.\nRun a loop to seed this board.'
            : 'No territory claimed yet.\nRun a loop to join the board.',
      };
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
                windowedEmpty,
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

    final top3 = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return ListView(
      children: [
        // ── Podium ──────────────────────────────────────────────────────
        if (top3.isNotEmpty) ...[
          _Podium(entries: top3, onEntryTap: onEntryTap),
          const SizedBox(height: 20),
        ],
        // ── Remaining ranks ──────────────────────────────────────────────
        if (rest.isNotEmpty)
          ...rest.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _LeaderboardTile(entry: e, onTap: () => onEntryTap(e)),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }
}

// ── Podium ────────────────────────────────────────────────────────────────────

class _Podium extends StatelessWidget {
  const _Podium({required this.entries, required this.onEntryTap});

  final List<LeaderboardEntryEntity> entries;
  final ValueChanged<LeaderboardEntryEntity> onEntryTap;

  @override
  Widget build(BuildContext context) {
    // Podium order: 2nd | 1st | 3rd
    final first = entries.isNotEmpty ? entries[0] : null;
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    final podiumEntries = [second, first, third];
    final heights = [90.0, 120.0, 70.0];
    final medals = ['2', '1', '3'];
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
              onTap: () => onEntryTap(entry),
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
    required this.onTap,
  });

  final LeaderboardEntryEntity entry;
  final double barHeight;
  final String medal;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hud = Theme.of(context).extension<AwakenTypography>()!;
    final areaKm2 = entry.totalAreaSqMeters / 1_000_000;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PodiumBadge(label: medal, color: color),
          const SizedBox(height: 8),
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
      ),
    );
  }
}

class _PodiumBadge extends StatelessWidget {
  const _PodiumBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

// ── Rank tile ─────────────────────────────────────────────────────────────────

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.entry, required this.onTap});

  final LeaderboardEntryEntity entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hud = Theme.of(context).extension<AwakenTypography>()!;
    final areaKm2 = entry.totalAreaSqMeters / 1_000_000;

    final isTopRank = entry.rank <= 3;
    final rankColor = isTopRank ? AppColors.accent : AppColors.mutedForeground;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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
            const SizedBox(width: 12),
            Text(
              '${areaKm2.toStringAsFixed(3)} km²',
              style: hud.statValue.copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardHeader extends StatelessWidget {
  const _LeaderboardHeader({required this.mode, required this.window});

  final LeaderboardMode mode;
  final LeaderboardWindow window;

  @override
  Widget build(BuildContext context) {
    final scopeLabel = mode == LeaderboardMode.nearby ? 'Nearby' : 'Global';
    final title = switch (window) {
      LeaderboardWindow.allTime => '$scopeLabel rivals',
      LeaderboardWindow.day => '$scopeLabel · Last 24h',
      LeaderboardWindow.week => '$scopeLabel · Last 7 days',
    };
    final subtitle = switch (window) {
      LeaderboardWindow.allTime => mode == LeaderboardMode.nearby
          ? 'Ranks runners near your current location.'
          : 'Ranks every runner in the network.',
      _ => mode == LeaderboardMode.nearby
          ? 'Ranks who\'s captured the most nearby, recently.'
          : 'Ranks who\'s captured the most territory, recently.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.foreground,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ModeHint extends StatelessWidget {
  const _ModeHint({required this.mode, required this.window});

  final LeaderboardMode mode;
  final LeaderboardWindow window;

  @override
  Widget build(BuildContext context) {
    final scopeText = mode == LeaderboardMode.nearby
        ? 'Nearby uses your current location to find the closest territories.'
        : 'Global ranks everyone by total area claimed.';
    final windowText = switch (window) {
      LeaderboardWindow.allTime => scopeText,
      LeaderboardWindow.day => 'Momentum board — area captured in the last 24 hours, not total land owned.',
      LeaderboardWindow.week => 'Momentum board — area captured in the last 7 days, not total land owned.',
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        windowText,
        style: const TextStyle(
          color: AppColors.mutedForeground,
          fontSize: 11,
          height: 1.3,
        ),
      ),
    );
  }
}
