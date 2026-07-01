import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/territory/domain/entities/run_track_entity.dart';
import 'package:awaken/features/territory/presentation/providers/active_run_providers.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:awaken/features/territory/presentation/widgets/run_controls.dart';
import 'package:awaken/features/territory/presentation/widgets/run_stats_sheet.dart';
import 'package:awaken/features/territory/presentation/widgets/territory_polygon_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

/// Full-screen territory map + run tracking — flutter_map over a dark tile
/// server, live trail, every player's territory polygons, and the
/// Start/Stop controls in the thumb zone.
class TerritoryRunScreen extends ConsumerStatefulWidget {
  const TerritoryRunScreen({super.key});

  @override
  ConsumerState<TerritoryRunScreen> createState() => _TerritoryRunScreenState();
}

class _TerritoryRunScreenState extends ConsumerState<TerritoryRunScreen> {
  final MapController _mapController = MapController();
  static const LatLng _fallbackCenter = LatLng(0, 0);

  @override
  void initState() {
    super.initState();
    _centerOnCurrentLocation();
  }

  Future<void> _centerOnCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 6));
      if (!mounted) return;
      _mapController.move(LatLng(position.latitude, position.longitude), 16);
    } catch (_) {
      // Permission not yet granted or location unavailable — stays at
      // the fallback center until the user starts a run.
    }
  }

  @override
  Widget build(BuildContext context) {
    final territoriesAsync = ref.watch(territoryListProvider);
    final runState = ref.watch(activeRunProvider);

    ref.listen(activeRunProvider, (previous, next) {
      if (previous?.status != RunSessionStatus.finished &&
          next.status == RunSessionStatus.finished) {
        _onRunFinished(next);
      }
      if (next.points.isNotEmpty) {
        final last = next.points.last;
        _mapController.move(LatLng(last.latitude, last.longitude), _mapController.camera.zoom);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(initialCenter: _fallbackCenter, initialZoom: 2),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.awaken.app',
              ),
              territoriesAsync.when(
                data: (territories) => TerritoryPolygonLayer(territories: territories),
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
              if (runState.points.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: runState.points
                          .map((p) => LatLng(p.latitude, p.longitude))
                          .toList(),
                      color: AppColors.accent,
                      strokeWidth: 4,
                    ),
                  ],
                ),
              if (runState.points.isNotEmpty)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(runState.points.last.latitude, runState.points.last.longitude),
                      width: 18,
                      height: 18,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Top bar: back + leaderboard ───────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _CircleIconButton(icon: Icons.arrow_back, onTap: () => context.pop()),
                  _CircleIconButton(
                    icon: Icons.leaderboard_rounded,
                    onTap: () => context.push(AppRoutes.territoryLeaderboard),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom: stats + controls (thumb zone) ─────────────────────
          if (runState.status == RunSessionStatus.tracking ||
              runState.status == RunSessionStatus.finishing)
            Positioned(
              left: AppConstants.screenPaddingH,
              right: AppConstants.screenPaddingH,
              bottom: 110,
              child: RunStatsSheet(
                distanceMeters: runState.distanceMeters,
                elapsed: runState.elapsed,
                isOverSpeed: runState.isOverSpeed,
              ),
            ),
          Positioned(
            left: AppConstants.screenPaddingH,
            right: AppConstants.screenPaddingH,
            bottom: 32,
            child: SafeArea(
              top: false,
              child: RunControls(
                isTracking: runState.status == RunSessionStatus.tracking,
                onStart: () => ref.read(activeRunProvider.notifier).startRun(),
                onStop: () => ref.read(activeRunProvider.notifier).finishRun(),
              ),
            ),
          ),

          if (runState.status == RunSessionStatus.error)
            Positioned(
              left: AppConstants.screenPaddingH,
              right: AppConstants.screenPaddingH,
              bottom: 110,
              child: _ErrorBanner(message: runState.errorMessage ?? 'Something went wrong.'),
            ),
        ],
      ),
    );
  }

  void _onRunFinished(ActiveRunState state) {
    final outcome = state.result?.outcome;
    final capture = state.captureResult;

    if (capture != null) {
      if (capture.stoleFromRival) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }

    final message = switch (outcome) {
      RunOutcome.territoryClaimed when capture?.stoleFromRival == true =>
        'Territory stolen! +${capture!.claimedAreaSqMeters.toStringAsFixed(0)} m²',
      RunOutcome.territoryClaimed =>
        'Territory claimed! +${capture?.claimedAreaSqMeters.toStringAsFixed(0) ?? '0'} m²',
      RunOutcome.loopNotClosed => 'Run saved — loop didn\'t close, no territory claimed.',
      RunOutcome.invalidatedSpeedCap => 'Run invalidated — moving too fast for a run.',
      RunOutcome.invalidatedTooSmall => 'Loop too small to claim territory.',
      RunOutcome.invalidatedTooShort => 'Run too short to count.',
      null => 'Run saved.',
    };

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    ref.read(activeRunProvider.notifier).reset();
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card.withValues(alpha: 0.7),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.foreground, size: 22),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Text(message, style: const TextStyle(color: Colors.white)),
    );
  }
}
