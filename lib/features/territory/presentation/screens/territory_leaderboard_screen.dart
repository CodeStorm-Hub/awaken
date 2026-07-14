import 'dart:async';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/leaderboard_entry_entity.dart';
import 'package:awaken/features/territory/domain/entities/territory_entity.dart';
import 'package:awaken/features/territory/domain/services/location_fix_service.dart';
import 'package:awaken/features/territory/domain/services/location_permission_helper.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:awaken/features/territory/presentation/widgets/leaderboard/leaderboard_filters.dart';
import 'package:awaken/features/territory/presentation/widgets/leaderboard/leaderboard_podium.dart';
import 'package:awaken/features/territory/presentation/widgets/leaderboard/leaderboard_rank_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureViewerLocation();
      ref.invalidate(leaderboardProvider);
    });
  }

  Future<void> _ensureViewerLocation({bool forceRefresh = false}) async {
    if (!forceRefresh && ref.read(viewerLocationProvider) != null) return;
    try {
      await LocationPermissionHelper.ensureLocationAccess(
        serviceDisabledMessage:
            'Turn on location services to see nearby rivals.',
        permissionDeniedMessage: 'Allow location access to see nearby rivals.',
      );
      final position = await LocationFixService.acquireForMapCentering();
      if (!mounted || position == null) return;
      ref.read(viewerLocationProvider.notifier).state = GeoPointEntity(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );
    } catch (_) {
      // Denied / timed out — nearby falls back until location is available.
    }
  }

  void _onEntryTap(LeaderboardEntryEntity entry) {
    final territories = ref.read(territoryListProvider).value ?? const [];
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
          content: Text(
            'This runner\'s territory isn\'t on the live map right now.',
          ),
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
    final viewerUserId = ref.watch(currentUserProvider)?.id;

    // IndexedStack keeps this screen alive — refresh when the Ranks tab
    // becomes visible so post-capture totals match the database.
    ref.listen<int>(territoryShellTabIndexProvider, (previous, next) {
      if (next == 2 && previous != 2) {
        ref.invalidate(leaderboardProvider);
        unawaited(_ensureViewerLocation(forceRefresh: true));
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.screenPaddingH,
                8,
                8,
                0,
              ),
              child: Row(
                children: [
                  Expanded(child: Text('RANKS', style: hud.eyebrow)),
                  IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.mutedForeground,
                      size: 20,
                    ),
                    onPressed: () => ref.invalidate(leaderboardProvider),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.card,
                onRefresh: () async {
                  ref.invalidate(leaderboardProvider);
                  await ref.read(leaderboardProvider.future);
                },
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppConstants.screenPaddingH,
                        4,
                        AppConstants.screenPaddingH,
                        0,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _LeaderboardTitle(mode: mode, window: window),
                          const SizedBox(height: 16),
                          LeaderboardScopeToggle(
                            mode: mode,
                            onChanged: (m) =>
                                ref
                                        .read(leaderboardModeProvider.notifier)
                                        .state =
                                    m,
                          ),
                          const SizedBox(height: 10),
                          LeaderboardWindowChips(
                            window: window,
                            onChanged: (w) =>
                                ref
                                        .read(
                                          leaderboardWindowProvider.notifier,
                                        )
                                        .state =
                                    w,
                          ),
                          const SizedBox(height: 12),
                          LeaderboardMetricBadge(window: window, mode: mode),
                          const SizedBox(height: 18),
                        ]),
                      ),
                    ),
                    ...leaderboardAsync.when(
                      data: (entries) => _buildBoardSlivers(
                        entries: entries,
                        mode: mode,
                        window: window,
                        viewerUserId: viewerUserId,
                      ),
                      loading: () => [
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                      error: (_, _) => [
                        const SliverFillRemaining(
                          hasScrollBody: false,
                          child: LeaderboardEmptyState(
                            message:
                                'Could not load ranks.\nPull down to try again.',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildBoardSlivers({
    required List<LeaderboardEntryEntity> entries,
    required LeaderboardMode mode,
    required LeaderboardWindow window,
    required String? viewerUserId,
  }) {
    if (entries.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: LeaderboardEmptyState(message: _emptyMessage(mode, window)),
        ),
      ];
    }

    final top = entries.take(3).toList();
    final rest = entries.length > 3
        ? entries.skip(3).toList()
        : const <LeaderboardEntryEntity>[];
    final maxArea = entries.first.totalAreaSqMeters;

    String? climbHint;
    List<LeaderboardEntryEntity> neighborhood = const [];
    if (viewerUserId != null) {
      final myIndex = entries.indexWhere((e) => e.userId == viewerUserId);
      if (myIndex >= 0) {
        const radius = AppConstants.leaderboardNeighborhoodRadius;
        final start = (myIndex - radius).clamp(0, entries.length);
        final end = (myIndex + radius + 1).clamp(0, entries.length);
        neighborhood = entries.sublist(start, end);
        if (myIndex > 0) {
          final me = entries[myIndex];
          final above = entries[myIndex - 1];
          final delta = above.totalAreaSqMeters - me.totalAreaSqMeters;
          if (delta > 0) {
            climbHint =
                'Claim ${(delta / 1e6).toStringAsFixed(3)} km² more to pass ${above.displayName ?? 'rank ${above.rank}'}';
          }
        }
      }
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.screenPaddingH,
        ),
        sliver: SliverList(
          delegate: SliverChildListDelegate([
            LeaderboardPodium(entries: top, onEntryTap: _onEntryTap),
            if (climbHint != null) ...[
              const SizedBox(height: 14),
              LeaderboardClimbHint(text: climbHint),
            ],
            if (neighborhood.isNotEmpty) ...[
              const SizedBox(height: 18),
              const LeaderboardSectionLabel('AROUND YOU'),
              const SizedBox(height: 10),
              ...neighborhood.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: LeaderboardRankRow(
                    entry: entry,
                    highlight: entry.userId == viewerUserId,
                    maxAreaSqMeters: maxArea,
                    onTap: () => _onEntryTap(entry),
                  ),
                ),
              ),
            ],
            if (rest.isNotEmpty) ...[
              const SizedBox(height: 18),
              const LeaderboardSectionLabel('FULL STANDINGS'),
            ],
          ]),
        ),
      ),
      if (rest.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.screenPaddingH,
            0,
            AppConstants.screenPaddingH,
            28,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final entry = rest[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: LeaderboardRankRow(
                  entry: entry,
                  highlight: entry.userId == viewerUserId,
                  maxAreaSqMeters: maxArea,
                  onTap: () => _onEntryTap(entry),
                ),
              );
            }, childCount: rest.length),
          ),
        )
      else
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
    ];
  }

  String _emptyMessage(LeaderboardMode mode, LeaderboardWindow window) {
    return switch (window) {
      LeaderboardWindow.day =>
        'No captures in the last 24 hours.\nClose a loop to take the board.',
      LeaderboardWindow.week =>
        'No captures in the last 7 days.\nClose a loop to take the board.',
      LeaderboardWindow.allTime =>
        mode == LeaderboardMode.nearby
            ? 'No nearby territory yet.\nRun a loop to seed this board.'
            : 'No territory claimed yet.\nRun a loop to join the board.',
    };
  }
}

class _LeaderboardTitle extends StatelessWidget {
  const _LeaderboardTitle({required this.mode, required this.window});

  final LeaderboardMode mode;
  final LeaderboardWindow window;

  @override
  Widget build(BuildContext context) {
    final scope = mode == LeaderboardMode.nearby ? 'Nearby' : 'Global';
    final title = switch (window) {
      LeaderboardWindow.allTime => '$scope rivals',
      LeaderboardWindow.day => '$scope · 24h',
      LeaderboardWindow.week => '$scope · 7 days',
    };
    final subtitle = switch (window) {
      LeaderboardWindow.allTime =>
        mode == LeaderboardMode.nearby
            ? 'Who holds the most land around you.'
            : 'Who holds the most land worldwide.',
      _ => 'Who claimed the most distinct land recently.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.foreground,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 13,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
