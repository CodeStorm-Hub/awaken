import 'dart:async';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
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

  bool _isLocating = true;
  String? _resultMessage;
  Timer? _resultMessageTimer;

  @override
  void initState() {
    super.initState();
    _centerOnCurrentLocation();
  }

  @override
  void dispose() {
    _resultMessageTimer?.cancel();
    super.dispose();
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
      // the fallback center until re-attempted (e.g. once permission is
      // granted via the Start Run flow — see the ref.listen below).
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(activeRunProvider.select((s) => s.status));
    final errorMessage = ref.watch(activeRunProvider.select((s) => s.errorMessage));

    ref.listen<ActiveRunState>(activeRunProvider, (previous, next) {
      if (previous?.status != RunSessionStatus.finished &&
          next.status == RunSessionStatus.finished) {
        _onRunFinished(next);
      }
      // Permission was granted for the first time this visit — the initial
      // initState() attempt likely failed before it existed, so retry now.
      if (previous?.status == RunSessionStatus.requestingPermission &&
          next.status == RunSessionStatus.tracking) {
        _centerOnCurrentLocation();
      }
      if (next.points.isNotEmpty) {
        final last = next.points.last;
        _mapController.move(LatLng(last.latitude, last.longitude), _mapController.camera.zoom);
      }
    });

    final isTracking =
        status == RunSessionStatus.tracking || status == RunSessionStatus.finishing;

    return PopScope(
      canPop: !isTracking,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _confirmDiscardRun();
        if (discard) {
          ref.read(activeRunProvider.notifier).reset();
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            _TerritoryMapView(mapController: _mapController),

            if (_isLocating && status == RunSessionStatus.idle)
              const Positioned.fill(
                child: IgnorePointer(child: Center(child: _LocatingIndicator())),
              ),

            // ── Top bar: back + leaderboard ───────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back,
                      onTap: () async {
                        if (!isTracking) {
                          context.pop();
                          return;
                        }
                        final discard = await _confirmDiscardRun();
                        if (discard) {
                          ref.read(activeRunProvider.notifier).reset();
                          if (context.mounted) context.pop();
                        }
                      },
                    ),
                    _CircleIconButton(
                      icon: Icons.leaderboard_rounded,
                      onTap: () => context.push(AppRoutes.territoryLeaderboard),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom: stats + controls (thumb zone) ─────────────────────
            if (isTracking)
              const Positioned(
                left: AppConstants.screenPaddingH,
                right: AppConstants.screenPaddingH,
                bottom: 110,
                child: _RunStatsSheetConsumer(),
              ),
            Positioned(
              left: AppConstants.screenPaddingH,
              right: AppConstants.screenPaddingH,
              bottom: 32,
              child: SafeArea(
                top: false,
                child: RunControls(
                  isTracking: status == RunSessionStatus.tracking,
                  onStart: () => _onStartPressed(context),
                  onStop: () => ref.read(activeRunProvider.notifier).finishRun(),
                ),
              ),
            ),

            if (status == RunSessionStatus.error)
              Positioned(
                left: AppConstants.screenPaddingH,
                right: AppConstants.screenPaddingH,
                bottom: 110,
                child: _ErrorBanner(message: errorMessage ?? 'Something went wrong.'),
              ),

            if (_resultMessage != null)
              Positioned(
                left: AppConstants.screenPaddingH,
                right: AppConstants.screenPaddingH,
                bottom: 110,
                child: _ResultBanner(message: _resultMessage!),
              ),
          ],
        ),
      ),
    );
  }

  void _onStartPressed(BuildContext context) {
    if (!ref.read(isSignedInProvider) && false) {
      _promptSignIn(context);
      return;
    }
    ref.read(activeRunProvider.notifier).startRun();
  }

  Future<void> _promptSignIn(BuildContext context) async {
    final shouldSignIn = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Sign in required', style: TextStyle(color: AppColors.foreground)),
        content: const Text(
          'Territory capture is saved to your account — sign in to track runs and claim territory.',
          style: TextStyle(color: AppColors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
    if (shouldSignIn == true && context.mounted) {
      context.push(AppRoutes.auth);
    }
  }

  Future<bool> _confirmDiscardRun() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Discard this run?', style: TextStyle(color: AppColors.foreground)),
        content: const Text(
          'Leaving now stops GPS tracking and this run will not be saved.',
          style: TextStyle(color: AppColors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep running'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard', style: TextStyle(color: AppColors.destructive)),
          ),
        ],
      ),
    );
    return discard ?? false;
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

    // Owning this banner locally (rather than ScaffoldMessenger's SnackBar)
    // guarantees it actually renders — the custom bottom-pinned RunControls
    // button previously ate the Scaffold's SnackBar slot, so the SnackBar
    // never became visible even though it technically mounted.
    _resultMessageTimer?.cancel();
    setState(() => _resultMessage = message);
    _resultMessageTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _resultMessage = null);
    });

    ref.read(activeRunProvider.notifier).reset();
  }
}

// ── Map layer (isolated so a run's per-second timer tick doesn't rebuild it) ──

class _TerritoryMapView extends ConsumerWidget {
  const _TerritoryMapView({required this.mapController});

  final MapController mapController;

  static const LatLng _fallbackCenter = LatLng(0, 0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final territoriesAsync = ref.watch(territoryListProvider);
    final points = ref.watch(activeRunProvider.select((s) => s.points));

    return FlutterMap(
      mapController: mapController,
      options: const MapOptions(initialCenter: _fallbackCenter, initialZoom: 2),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.awaken.app',
          retinaMode: RetinaMode.isHighDensity(context),
        ),
        territoriesAsync.when(
          data: (territories) => TerritoryPolygonLayer(territories: territories),
          loading: () => const SizedBox.shrink(),
          error: (error, stackTrace) => const SizedBox.shrink(),
        ),
        if (points.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: points.map((p) => LatLng(p.latitude, p.longitude)).toList(),
                color: AppColors.accent,
                strokeWidth: 4,
              ),
            ],
          ),
        if (points.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(points.last.latitude, points.last.longitude),
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
    );
  }
}

// ── Stats sheet (isolated so it — not the map — absorbs the per-second tick) ──

class _RunStatsSheetConsumer extends ConsumerWidget {
  const _RunStatsSheetConsumer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distanceMeters = ref.watch(activeRunProvider.select((s) => s.distanceMeters));
    final elapsed = ref.watch(activeRunProvider.select((s) => s.elapsed));
    final isOverSpeed = ref.watch(activeRunProvider.select((s) => s.isOverSpeed));

    return RunStatsSheet(
      distanceMeters: distanceMeters,
      elapsed: elapsed,
      isOverSpeed: isOverSpeed,
    );
  }
}

// ── Small stateless widgets ────────────────────────────────────────────────

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

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.foreground, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _LocatingIndicator extends StatelessWidget {
  const _LocatingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: AppColors.accent),
        const SizedBox(height: 12),
        Text(
          'Finding your location…',
          style: TextStyle(color: AppColors.mutedForeground.withValues(alpha: 0.9)),
        ),
      ],
    );
  }
}
