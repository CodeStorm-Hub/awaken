import 'dart:async';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:awaken/features/territory/domain/entities/run_track_entity.dart';
import 'package:awaken/features/territory/domain/services/geo_utils.dart';
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

// ── Follow-me state ─────────────────────────────────────────────────────────

/// True while the map camera should auto-follow the user position.
/// Disabled by the user manually panning the map.
final _followMeProvider = StateProvider<bool>((ref) => true);

// ── Screen ───────────────────────────────────────────────────────────────────

/// Full-screen territory map + run tracking.
///
/// Design pillars:
/// - CartoDB Dark Matter tiles, consistent with the app dark-only theme.
/// - Neon-glow territory polygons via [TerritoryPolygonLayer].
/// - Real-time path drawn in two passes (glow + core), plus distinct start/
///   current markers.
/// - Zoom +/- buttons and a Follow-Me toggle on the right rail.
/// - Run HUD (time / distance / loop closure) glassmorphic card over the map.
/// - Start / Stop control pinned to the thumb zone.
class TerritoryRunScreen extends ConsumerStatefulWidget {
  const TerritoryRunScreen({super.key});

  @override
  ConsumerState<TerritoryRunScreen> createState() => _TerritoryRunScreenState();
}

class _TerritoryRunScreenState extends ConsumerState<TerritoryRunScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  bool _isLocating = true;
  String? _resultMessage;
  Timer? _resultMessageTimer;

  // Animation controller for the pulsing "about to close" ring
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _centerOnCurrentLocation();
  }

  @override
  void dispose() {
    _resultMessageTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Location helpers ───────────────────────────────────────────────────────

  Future<void> _centerOnCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      _animateTo(LatLng(position.latitude, position.longitude), zoom: 16.5);
    } catch (_) {
      // Location unavailable — stays at fallback center.
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  void _animateTo(LatLng center, {double? zoom}) {
    final targetZoom = zoom ?? _mapController.camera.zoom;
    // flutter_map 7.x uses move() — no built-in tween but we can manually
    // step via an AnimationController driving move() calls.
    _mapController.move(center, targetZoom);
  }

  void _zoomIn() => _mapController.move(
        _mapController.camera.center,
        (_mapController.camera.zoom + 1).clamp(2.0, 20.0),
      );

  void _zoomOut() => _mapController.move(
        _mapController.camera.center,
        (_mapController.camera.zoom - 1).clamp(2.0, 20.0),
      );

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(activeRunProvider.select((s) => s.status));
    final errorMessage = ref.watch(activeRunProvider.select((s) => s.errorMessage));
    final points = ref.watch(activeRunProvider.select((s) => s.points));
    final followMe = ref.watch(_followMeProvider);

    // Distance from current position back to start — drives the proximity ring.
    final distToStart = points.length >= 2
        ? GeoUtils.haversineMeters(points.first, points.last)
        : double.infinity;
    final isNearClose = distToStart <= AppConstants.loopClosureRadiusMeters * 4;

    // ── Listen for state transitions ──────────────────────────────────────
    ref.listen<ActiveRunState>(activeRunProvider, (previous, next) {
      // Run just finished
      if (previous?.status != RunSessionStatus.finished &&
          next.status == RunSessionStatus.finished) {
        _onRunFinished(next);
      }
      // Permission granted mid-session → re-centre
      if (previous?.status == RunSessionStatus.requestingPermission &&
          next.status == RunSessionStatus.tracking) {
        _centerOnCurrentLocation();
      }
      // Follow-me: move camera to latest GPS point
      if (next.points.isNotEmpty && ref.read(_followMeProvider)) {
        final last = next.points.last;
        _mapController.move(
          LatLng(last.latitude, last.longitude),
          _mapController.camera.zoom,
        );
      }
    });

    final isTracking =
        status == RunSessionStatus.tracking || status == RunSessionStatus.finishing;
    final isFinishing = status == RunSessionStatus.finishing;

    return PopScope(
      canPop: !isTracking,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await _confirmDiscardRun();
        if (discard) {
          ref.read(activeRunProvider.notifier).reset();
          if (!mounted) return;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // ── Map ────────────────────────────────────────────────────────
            _TerritoryMapView(
              mapController: _mapController,
              onMapMoved: () {
                // User panned manually → disable follow-me
                if (ref.read(_followMeProvider)) {
                  ref.read(_followMeProvider.notifier).state = false;
                }
              },
            ),

            // ── Locating spinner ───────────────────────────────────────────
            if (_isLocating && status == RunSessionStatus.idle)
              const Positioned.fill(
                child: IgnorePointer(
                  child: Center(child: _LocatingIndicator()),
                ),
              ),

            // ── Top bar: back arrow + title ────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () async {
                        if (!isTracking) {
                          context.pop();
                          return;
                        }
                        final discard = await _confirmDiscardRun();
                        if (discard) {
                          ref.read(activeRunProvider.notifier).reset();
                          if (!mounted) return;
                          context.pop();
                        }
                      },
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.card.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        isTracking ? 'RUNNING' : 'TERRITORY',
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isTracking && isNearClose && points.length >= 2)
                      _PulseCloseIndicator(animation: _pulseAnim),
                  ],
                ),
              ),
            ),

            // ── Right rail: zoom + follow-me ──────────────────────────────
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Follow-me toggle
                    _CircleIconButton(
                      icon: followMe
                          ? Icons.my_location_rounded
                          : Icons.location_searching_rounded,
                      onTap: () {
                        final next = !ref.read(_followMeProvider);
                        ref.read(_followMeProvider.notifier).state = next;
                        if (next && points.isNotEmpty) {
                          _animateTo(
                            LatLng(
                              points.last.latitude,
                              points.last.longitude,
                            ),
                          );
                        }
                      },
                      tint: followMe ? AppColors.primary : null,
                    ),
                    const SizedBox(height: 8),
                    // Zoom in
                    _CircleIconButton(
                      icon: Icons.add_rounded,
                      onTap: _zoomIn,
                    ),
                    const SizedBox(height: 6),
                    // Zoom out
                    _CircleIconButton(
                      icon: Icons.remove_rounded,
                      onTap: _zoomOut,
                    ),
                    const SizedBox(height: 8),
                    // Re-centre on current location
                    _CircleIconButton(
                      icon: Icons.gps_fixed_rounded,
                      onTap: () {
                        ref.read(_followMeProvider.notifier).state = true;
                        _centerOnCurrentLocation();
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats HUD ─────────────────────────────────────────────────
            if (isTracking)
              Positioned(
                left: AppConstants.screenPaddingH,
                right: 56, // clear the right rail
                bottom: 110,
              child: const _RunStatsSheetConsumer(),
              ),

            // ── Error banner ───────────────────────────────────────────────
            if (status == RunSessionStatus.error)
              Positioned(
                left: AppConstants.screenPaddingH,
                right: AppConstants.screenPaddingH,
                bottom: 110,
                child: _ErrorBanner(
                  message: errorMessage ?? 'Something went wrong.',
                ),
              ),

            // ── Result banner (post-run) ────────────────────────────────────
            if (_resultMessage != null)
              Positioned(
                left: AppConstants.screenPaddingH,
                right: AppConstants.screenPaddingH,
                bottom: 110,
                child: _ResultBanner(message: _resultMessage!),
              ),

            // ── Start / Stop control ───────────────────────────────────────
            Positioned(
              left: AppConstants.screenPaddingH,
              right: AppConstants.screenPaddingH,
              bottom: 32,
              child: SafeArea(
                top: false,
                child: RunControls(
                  isTracking: status == RunSessionStatus.tracking,
                  isFinishing: isFinishing,
                  onStart: () => _onStartPressed(context),
                  onStop: () =>
                      ref.read(activeRunProvider.notifier).finishRun(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Interaction handlers ───────────────────────────────────────────────────

  void _onStartPressed(BuildContext context) {
    if (!ref.read(isSignedInProvider)) {
      _promptSignIn(context);
      return;
    }
    ref.read(_followMeProvider.notifier).state = true;
    ref.read(activeRunProvider.notifier).startRun();
  }

  Future<void> _promptSignIn(BuildContext context) async {
    final shouldSignIn = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
        title: const Text(
          'Sign in required',
          style: TextStyle(color: AppColors.foreground),
        ),
        content: const Text(
          'Territory capture is saved to your account. Sign in to track runs and claim territory.',
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
    if (shouldSignIn == true) {
      if (!mounted) return;
      context.push(AppRoutes.auth);
    }
  }

  Future<bool> _confirmDiscardRun() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
        title: const Text(
          'Discard this run?',
          style: TextStyle(color: AppColors.foreground),
        ),
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
            child: const Text(
              'Discard',
              style: TextStyle(color: AppColors.destructive),
            ),
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
        '⚔ Territory stolen! +${capture!.claimedAreaSqMeters.toStringAsFixed(0)} m²',
      RunOutcome.territoryClaimed =>
        '✓ Territory claimed! +${capture?.claimedAreaSqMeters.toStringAsFixed(0) ?? '0'} m²',
      RunOutcome.loopNotClosed =>
        'Loop didn\'t close — run saved as workout.',
      RunOutcome.invalidatedSpeedCap =>
        '⚠ Run invalidated — too fast for a run.',
      RunOutcome.invalidatedTooSmall => 'Loop too small to claim territory.',
      RunOutcome.invalidatedTooShort => 'Run too short to count.',
      null => 'Run saved.',
    };

    if (!mounted) return;

    _resultMessageTimer?.cancel();
    setState(() => _resultMessage = message);
    _resultMessageTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _resultMessage = null);
    });

    ref.read(activeRunProvider.notifier).reset();
  }
}

// ── Map layer ─────────────────────────────────────────────────────────────────
// Isolated as its own ConsumerWidget so the per-second timer tick does not
// rebuild the full map — only the stats sheet absorbs those rebuilds.

class _TerritoryMapView extends ConsumerWidget {
  const _TerritoryMapView({
    required this.mapController,
    required this.onMapMoved,
  });

  final MapController mapController;
  final VoidCallback onMapMoved;

  static const LatLng _fallbackCenter = LatLng(43.65, -79.38); // Toronto

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final territoriesAsync = ref.watch(territoryListProvider);
    final points = ref.watch(activeRunProvider.select((s) => s.points));

    final latLngPoints =
        points.map((p) => LatLng(p.latitude, p.longitude)).toList();

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: _fallbackCenter,
        initialZoom: 14,
        minZoom: 3,
        maxZoom: 20,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
          enableMultiFingerGestureRace: true,
        ),
        onMapEvent: (event) {
          // Detect user-initiated drag → disable follow-me
          if (event is MapEventMoveStart &&
              event.source == MapEventSource.dragStart) {
            onMapMoved();
          }
          if (event is MapEventScrollWheelZoom) {
            onMapMoved();
          }
        },
      ),
      children: [
        // ── Dark tile layer ──────────────────────────────────────────────
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.awaken.app',
          retinaMode: RetinaMode.isHighDensity(context),
          tileProvider: NetworkTileProvider(),
        ),

        // ── Territory polygons ───────────────────────────────────────────
        territoriesAsync.when(
          data: (territories) =>
              TerritoryPolygonLayer(territories: territories),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // ── Active run trail: glow pass (wide soft) ──────────────────────
        if (latLngPoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: latLngPoints,
                color: AppColors.accent.withValues(alpha: 0.35),
                strokeWidth: 14,
                borderStrokeWidth: 0,
              ),
            ],
          ),

        // ── Active run trail: core pass (thin bright) ────────────────────
        if (latLngPoints.length > 1)
          PolylineLayer(
            polylines: [
              Polyline(
                points: latLngPoints,
                color: AppColors.accent,
                strokeWidth: 3.5,
                borderStrokeWidth: 0,
              ),
            ],
          ),

        // ── Start marker ─────────────────────────────────────────────────
        if (latLngPoints.isNotEmpty)
          MarkerLayer(
            markers: [
              Marker(
                point: latLngPoints.first,
                width: 22,
                height: 22,
                child: _StartMarker(),
              ),
            ],
          ),

        // ── Current position marker ───────────────────────────────────────
        if (latLngPoints.length > 1)
          MarkerLayer(
            markers: [
              Marker(
                point: latLngPoints.last,
                width: 20,
                height: 20,
                child: _CurrentPositionMarker(),
              ),
            ],
          ),
      ],
    );
  }
}

// ── Run stats (isolated so the per-second timer doesn't rebuild the map) ──────

class _RunStatsSheetConsumer extends ConsumerWidget {
  const _RunStatsSheetConsumer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distanceMeters =
        ref.watch(activeRunProvider.select((s) => s.distanceMeters));
    final elapsed =
        ref.watch(activeRunProvider.select((s) => s.elapsed));
    final isOverSpeed =
        ref.watch(activeRunProvider.select((s) => s.isOverSpeed));
    final points =
        ref.watch(activeRunProvider.select((s) => s.points));

    final distToStart = points.length >= 2
        ? GeoUtils.haversineMeters(points.first, points.last)
        : double.infinity;

    return RunStatsSheet(
      distanceMeters: distanceMeters,
      elapsed: elapsed,
      isOverSpeed: isOverSpeed,
      distToStartMeters: distToStart.isFinite ? distToStart : null,
    );
  }
}

// ── Markers ───────────────────────────────────────────────────────────────────

class _StartMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.6),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(Icons.flag_rounded, color: Colors.white, size: 11),
    );
  }
}

class _CurrentPositionMarker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.6),
            blurRadius: 10,
            spreadRadius: 3,
          ),
        ],
      ),
    );
  }
}

// ── Pulse close indicator ─────────────────────────────────────────────────────

class _PulseCloseIndicator extends StatelessWidget {
  const _PulseCloseIndicator({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) => Opacity(
        opacity: animation.value,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.success.withValues(alpha: 0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'CLOSE LOOP',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Circle icon button ────────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.tint,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final isAccented = tint != null;
    return Material(
      color: isAccented
          ? tint!.withValues(alpha: 0.15)
          : AppColors.card.withValues(alpha: 0.82),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: tint ?? AppColors.foreground,
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ── Banners & indicators ──────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).extension<AwakenTypography>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: tt.statLabel.copyWith(
          color: AppColors.foreground,
          fontSize: 14,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _LocatingIndicator extends StatelessWidget {
  const _LocatingIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              color: AppColors.accent,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Finding your location…',
            style: TextStyle(
              color: AppColors.mutedForeground.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
