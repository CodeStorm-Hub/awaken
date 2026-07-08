import 'dart:async';
import 'dart:ui' as ui;

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/core/theme/app_typography.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/run_track_entity.dart';
import 'package:awaken/features/territory/domain/services/geo_utils.dart';
import 'package:awaken/features/territory/domain/services/location_permission_helper.dart';
import 'package:awaken/features/territory/domain/services/trail_display_utils.dart';
import 'package:awaken/features/territory/presentation/providers/active_run_providers.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:awaken/features/territory/presentation/widgets/capture_result_sheet.dart';
import 'package:awaken/features/territory/presentation/widgets/run_controls.dart';
import 'package:awaken/features/territory/presentation/widgets/run_stats_sheet.dart';
import 'package:awaken/features/territory/presentation/widgets/territory_map_status_overlay.dart';
import 'package:awaken/features/territory/presentation/widgets/territory_polygon_layer.dart';
import 'package:awaken/features/territory/presentation/widgets/territory_vector_tile_layer.dart';
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

enum _LocatingPhase { hidden, requestingPermission, acquiringFix, failed }

// ── Screen ───────────────────────────────────────────────────────────────────

/// Full-screen territory map + run tracking.
///
/// Design pillars:
/// - Branded OpenFreeMap vector tiles (see [TerritoryVectorTileLayer]),
///   themed to match the app's dark-only palette.
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

  bool _didRequestInitialCenter = false;
  bool _didAutoCenterFromStream = false;
  _LocatingPhase _locatingPhase = _LocatingPhase.acquiringFix;
  String? _locationErrorMessage;
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

    ref.listenManual<bool>(territoryMapReadyProvider, (previous, ready) {
      if (ready) _ensureInitialLocationCenter();
    }, fireImmediately: true);

    ref.listenManual<int>(territoryShellTabIndexProvider, (previous, index) {
      if (index == 1) _ensureInitialLocationCenter();
    }, fireImmediately: true);

    ref.listenManual<AsyncValue<Position?>>(myLocationProvider, (previous, next) {
      next.whenData((position) {
        if (position == null || !mounted) return;
        ref.read(mapLastKnownPositionProvider.notifier).state = position;
        if (!_didAutoCenterFromStream && ref.read(_followMeProvider)) {
          _didAutoCenterFromStream = true;
          _animateTo(
            LatLng(position.latitude, position.longitude),
            zoom: AppConstants.territoryMapUserZoom,
          );
          setState(() => _locatingPhase = _LocatingPhase.hidden);
        }
      });
    });

    // A leaderboard "tap to locate" takes priority over auto-centering on
    // the user's own GPS position — they explicitly asked to see somewhere
    // else.
    final focus = ref.read(territoryMapFocusProvider);
    if (focus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(_followMeProvider.notifier).state = false;
        _animateTo(focus, zoom: 17);
        ref.read(territoryMapFocusProvider.notifier).state = null;
        setState(() => _locatingPhase = _LocatingPhase.hidden);
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureInitialLocationCenter();
      });
    }
  }

  void _ensureInitialLocationCenter() {
    if (_didRequestInitialCenter) return;
    if (!ref.read(territoryMapReadyProvider)) return;
    if (ref.read(territoryShellTabIndexProvider) != 1) return;
    if (ref.read(territoryMapFocusProvider) != null) return;
    _didRequestInitialCenter = true;
    unawaited(_centerOnCurrentLocation());
  }

  @override
  void dispose() {
    _resultMessageTimer?.cancel();
    _pulseCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Location helpers ───────────────────────────────────────────────────────

  Future<void> _centerOnCurrentLocation({bool userInitiated = false}) async {
    if (mounted) {
      setState(() {
        _locatingPhase = _LocatingPhase.requestingPermission;
        _locationErrorMessage = null;
      });
    }

    try {
      await LocationPermissionHelper.ensureLocationAccess(
        serviceDisabledMessage: 'Turn on location services to see your position on the map.',
        permissionDeniedMessage: 'Allow location access to see your position on the map.',
      );
    } on LocationAccessException catch (e) {
      if (mounted) {
        setState(() {
          _locatingPhase = _LocatingPhase.failed;
          _locationErrorMessage = e.message;
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() => _locatingPhase = _LocatingPhase.acquiringFix);

    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        ref.read(mapLastKnownPositionProvider.notifier).state = lastKnown;
        _animateTo(
          LatLng(lastKnown.latitude, lastKnown.longitude),
          zoom: AppConstants.territoryMapUserZoom,
        );
        _didAutoCenterFromStream = true;
        setState(() => _locatingPhase = _LocatingPhase.hidden);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      ).timeout(const Duration(seconds: 8));
      if (!mounted) return;
      ref.read(mapLastKnownPositionProvider.notifier).state = position;
      _animateTo(
        LatLng(position.latitude, position.longitude),
        zoom: AppConstants.territoryMapUserZoom,
      );
      _didAutoCenterFromStream = true;
      setState(() => _locatingPhase = _LocatingPhase.hidden);
    } catch (_) {
      if (!mounted) return;
      if (_locatingPhase != _LocatingPhase.hidden) {
        setState(() {
          _locatingPhase = _LocatingPhase.failed;
          _locationErrorMessage =
              'Could not get a GPS fix. Try again outdoors with a clear sky view.';
        });
      }
    } finally {
      if (userInitiated && mounted && _locatingPhase == _LocatingPhase.acquiringFix) {
        setState(() => _locatingPhase = _LocatingPhase.hidden);
      }
    }
  }

  void _animateTo(LatLng center, {double? zoom}) {
    final targetZoom = zoom ?? _mapController.camera.zoom;
    // flutter_map 7.x uses move() — no built-in tween but we can manually
    // step via an AnimationController driving move() calls.
    _mapController.move(center, targetZoom);
  }

  void _zoomIn() {
    final next = (_mapController.camera.zoom + 1).clamp(
      AppConstants.territoryMapMinZoom,
      AppConstants.territoryMapMaxZoom,
    );
    if (next <= _mapController.camera.zoom) return;
    _mapController.move(_mapController.camera.center, next);
    ref.read(territoryMapZoomProvider.notifier).state = next;
  }

  void _zoomOut() {
    final next = (_mapController.camera.zoom - 1).clamp(
      AppConstants.territoryMapMinZoom,
      AppConstants.territoryMapMaxZoom,
    );
    _mapController.move(_mapController.camera.center, next);
    ref.read(territoryMapZoomProvider.notifier).state = next;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(activeRunProvider.select((s) => s.status));
    final errorMessage = ref.watch(activeRunProvider.select((s) => s.errorMessage));
    final points = ref.watch(activeRunProvider.select((s) => s.points));
    final anchorIndex =
        ref.watch(activeRunProvider.select((s) => s.currentSegmentAnchorIndex));
    final pendingLoopCount =
        ref.watch(activeRunProvider.select((s) => s.pendingLoops.length));
    final followMe = ref.watch(_followMeProvider);
    final rivalConflict = ref.watch(rivalConflictProvider);
    final mapZoom = ref.watch(territoryMapZoomProvider);
    final atMaxZoom = mapZoom >= AppConstants.territoryMapMaxZoom - 0.01;
    final atMinZoom = mapZoom <= AppConstants.territoryMapMinZoom + 0.01;
    final mapVisible = ref.watch(territoryShellTabIndexProvider) == 1 ||
        ref.watch(territoryRunGpsKeepAliveProvider);

    // Distance from current position back to active segment anchor.
    final distToSegmentStart = points.length >= 2 &&
            anchorIndex < points.length
        ? GeoUtils.haversineMeters(points[anchorIndex], points.last)
        : double.infinity;
    final isNearClose =
        distToSegmentStart <= AppConstants.loopClosureRadiusMeters * 4;

    // ── Listen for state transitions ──────────────────────────────────────
    ref.listen<ActiveRunState>(activeRunProvider, (previous, next) {
      // Run just finished
      if (previous?.status != RunSessionStatus.finished &&
          next.status == RunSessionStatus.finished) {
        _onRunFinished(next);
      }
      // Live loop closure — haptic feedback when a new segment closes.
      if (next.pendingLoops.length > (previous?.pendingLoops.length ?? 0)) {
        HapticFeedback.mediumImpact();
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
          if (!context.mounted) return;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // ── Map ────────────────────────────────────────────────────────
            Visibility(
              visible: mapVisible,
              maintainState: true,
              maintainAnimation: true,
              child: _TerritoryMapView(
                mapController: _mapController,
                onMapMoved: () {
                  if (ref.read(_followMeProvider)) {
                    ref.read(_followMeProvider.notifier).state = false;
                  }
                },
                onZoomChanged: (zoom) {
                  ref.read(territoryMapZoomProvider.notifier).state = zoom;
                },
              ),
            ),

            // ── Locating overlay (GPS only — map loading is separate) ─────
            if (_locatingPhase != _LocatingPhase.hidden &&
                status == RunSessionStatus.idle)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: _locatingPhase != _LocatingPhase.failed,
                  child: Center(
                    child: _LocatingIndicator(
                      phase: _locatingPhase,
                      errorMessage: _locationErrorMessage,
                      onRetry: () => _centerOnCurrentLocation(userInitiated: true),
                    ),
                  ),
                ),
              ),

            // ── Map style/tile load failure ────────────────────────────────
            const Positioned.fill(child: TerritoryMapStatusOverlay()),

            // ── Top bar: back arrow + title ────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                              if (!context.mounted) return;
                              context.pop();
                            }
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RunHeader(
                            status: status,
                            isTracking: isTracking,
                            hasPoints: points.isNotEmpty,
                          ),
                        ),
                        if (isTracking && pendingLoopCount > 0) ...[
                          const SizedBox(width: 8),
                          _LoopClosedPill(count: pendingLoopCount),
                        ],
                        if (isTracking && isNearClose && points.length >= 2) ...[
                          const SizedBox(width: 12),
                          _PulseCloseIndicator(animation: _pulseAnim),
                        ],
                        if (!isTracking) ...[
                          const SizedBox(width: 12),
                          _CircleIconButton(
                            icon: Icons.bar_chart_rounded,
                            onTap: () => context.push(AppRoutes.territoryOverview),
                          ),
                        ],
                      ],
                    ),
                    if (isTracking && rivalConflict) ...[
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.only(left: 48),
                        child: _ConflictPill(),
                      ),
                    ],
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
                    _CircleIconButton(
                      icon: followMe
                          ? Icons.my_location_rounded
                          : Icons.location_searching_rounded,
                      onTap: () {
                        final next = !ref.read(_followMeProvider);
                        ref.read(_followMeProvider.notifier).state = next;
                        if (!next) return;
                        if (points.isNotEmpty && isTracking) {
                          _animateTo(
                            LatLng(
                              points.last.latitude,
                              points.last.longitude,
                            ),
                          );
                        } else {
                          unawaited(_centerOnCurrentLocation(userInitiated: true));
                        }
                      },
                      tint: followMe ? AppColors.primary : null,
                    ),
                    const SizedBox(height: 8),
                    _CircleIconButton(
                      icon: Icons.add_rounded,
                      onTap: atMaxZoom ? null : _zoomIn,
                      enabled: !atMaxZoom,
                    ),
                    const SizedBox(height: 6),
                    _CircleIconButton(
                      icon: Icons.remove_rounded,
                      onTap: atMinZoom ? null : _zoomOut,
                      enabled: !atMinZoom,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'z${mapZoom.toStringAsFixed(1)}',
                      style: const TextStyle(
                        color: AppColors.mutedForeground,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats HUD ─────────────────────────────────────────────────
            if (isTracking)
              const Positioned(
                left: AppConstants.screenPaddingH,
                right: 56, // clear the right rail
                bottom: 110,
                child: _RunStatsSheetConsumer(),
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
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
        title: const Text(
          'Sign in to sync this run',
          style: TextStyle(color: AppColors.foreground),
        ),
        content: const Text(
          'Sign in to sync your territory to the cloud and show up on the global leaderboard. Continue offline to save this run only on this device.',
          style: TextStyle(color: AppColors.mutedForeground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('offline'),
            child: const Text('Continue offline'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('signin'),
            child: const Text('Sign in'),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (result == 'signin') {
      context.push(AppRoutes.auth);
    } else if (result == 'offline') {
      ref.read(_followMeProvider.notifier).state = true;
      ref.read(activeRunProvider.notifier).startRun();
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
              'Discard run',
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
    final sessionCapture = state.sessionCaptureResult;

    if (sessionCapture != null && sessionCapture.loopsCaptured > 0) {
      if (sessionCapture.stoleFromRival) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }

      if (!mounted) return;
      final runPoints = state.result?.points ?? const <GeoPointEntity>[];
      ref.read(activeRunProvider.notifier).reset();
      CaptureResultSheet.show(
        context,
        sessionCaptureResult: sessionCapture,
        runPoints: runPoints,
      );
      return;
    }

    final message = switch (outcome) {
      RunOutcome.loopNotClosed => 'Loop didn\'t close — saved as a workout.',
      RunOutcome.invalidatedSpeedCap =>
        'Run too fast to count as territory.',
      RunOutcome.invalidatedTooSmall => 'Loop too small to claim territory.',
      RunOutcome.invalidatedTooShort => 'Run too short to count.',
      RunOutcome.territoryClaimed || null => 'Run saved.',
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
// The shell widget intentionally avoids watching GPS/run state so the vector
// basemap subtree stays stable — only the overlay layer widgets below rebuild
// on position ticks, which prevents vector_map_tiles from cancelling in-flight
// tile renders on every GPS update.

class _TerritoryMapView extends StatelessWidget {
  const _TerritoryMapView({
    required this.mapController,
    required this.onMapMoved,
    required this.onZoomChanged,
  });

  final MapController mapController;
  final VoidCallback onMapMoved;
  final ValueChanged<double> onZoomChanged;

  static const LatLng _fallbackCenter = LatLng(43.65, -79.38); // Toronto

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      key: territoryFlutterMapKey,
      mapController: mapController,
      options: MapOptions(
        backgroundColor: AppColors.background,
        initialCenter: _fallbackCenter,
        initialZoom: AppConstants.territoryMapInitialZoom,
        minZoom: AppConstants.territoryMapMinZoom,
        maxZoom: AppConstants.territoryMapMaxZoom,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
          enableMultiFingerGestureRace: true,
        ),
        onMapEvent: (event) {
          if (event is MapEventMoveStart &&
              event.source == MapEventSource.dragStart) {
            onMapMoved();
          }
          if (event is MapEventScrollWheelZoom) {
            onMapMoved();
          }
          if (event is MapEventMove || event is MapEventRotate) {
            onZoomChanged(mapController.camera.zoom);
          }
        },
      ),
      children: const [
        TerritoryVectorTileLayer(key: ValueKey('territory-vector-tile-layer-widget')),
        _TerritoryPolygonsLayer(),
        _PendingLoopLayer(),
        _RunTrailGlowLayer(),
        _RunTrailCoreLayer(),
        _RunStartMarkerLayer(),
        _MyLocationMarkerLayer(),
        RichAttributionWidget(
          alignment: AttributionAlignment.bottomRight,
          popupBackgroundColor: AppColors.card,
          attributions: [
            TextSourceAttribution(
              '© OpenStreetMap · OpenFreeMap',
              textStyle: TextStyle(color: AppColors.mutedForeground, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

class _PendingLoopLayer extends ConsumerWidget {
  const _PendingLoopLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingLoops =
        ref.watch(activeRunProvider.select((s) => s.pendingLoops));
    if (pendingLoops.isEmpty) return const SizedBox.shrink();

    final polygons = <Polygon>[];
    for (final segment in pendingLoops) {
      if (segment.points.length < 3) continue;
      final ring = segment.points
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
      if (ring.first != ring.last) {
        ring.add(ring.first);
      }
      polygons.add(
        Polygon(
          points: ring,
          color: AppColors.success.withValues(alpha: 0.22),
          borderColor: AppColors.success.withValues(alpha: 0.75),
          borderStrokeWidth: 2,
        ),
      );
    }

    if (polygons.isEmpty) return const SizedBox.shrink();

    return RepaintBoundary(
      child: PolygonLayer(polygons: polygons),
    );
  }
}

class _TerritoryPolygonsLayer extends ConsumerWidget {
  const _TerritoryPolygonsLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final territoriesAsync = ref.watch(territoryListProvider);
    final mapZoom = ref.watch(territoryMapZoomProvider);
    return territoriesAsync.when(
      data: (territories) => TerritoryPolygonLayer(
        territories: territories,
        mapZoom: mapZoom,
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _RunTrailGlowLayer extends ConsumerWidget {
  const _RunTrailGlowLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(activeRunProvider.select((s) => s.points));
    if (points.length < 2) return const SizedBox.shrink();

    final displayPoints = decimateTrailForDisplay(points);
    final latLngPoints =
        displayPoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
    return RepaintBoundary(
      child: PolylineLayer(
        polylines: [
          Polyline(
            points: latLngPoints,
            color: AppColors.accent.withValues(alpha: 0.35),
            strokeWidth: 14,
            borderStrokeWidth: 0,
          ),
        ],
      ),
    );
  }
}

class _RunTrailCoreLayer extends ConsumerWidget {
  const _RunTrailCoreLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(activeRunProvider.select((s) => s.points));
    if (points.length < 2) return const SizedBox.shrink();

    final displayPoints = decimateTrailForDisplay(points);
    final latLngPoints =
        displayPoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
    return RepaintBoundary(
      child: PolylineLayer(
        polylines: [
          Polyline(
            points: latLngPoints,
            color: AppColors.accent,
            strokeWidth: 3.5,
            borderStrokeWidth: 0,
          ),
        ],
      ),
    );
  }
}

class _RunStartMarkerLayer extends ConsumerWidget {
  const _RunStartMarkerLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(activeRunProvider.select((s) => s.points));
    final anchorIndex =
        ref.watch(activeRunProvider.select((s) => s.currentSegmentAnchorIndex));
    if (points.isEmpty || anchorIndex >= points.length) {
      return const SizedBox.shrink();
    }

    final anchor = points[anchorIndex];
    return MarkerLayer(
      markers: [
        Marker(
          point: LatLng(anchor.latitude, anchor.longitude),
          width: 22,
          height: 22,
          child: _StartMarker(),
        ),
      ],
    );
  }
}

class _MyLocationMarkerLayer extends ConsumerWidget {
  const _MyLocationMarkerLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(activeRunProvider.select((s) => s.status));
    final isTracking =
        status == RunSessionStatus.tracking || status == RunSessionStatus.finishing;

    LatLng? point;
    double? heading;

    if (isTracking) {
      final points = ref.watch(activeRunProvider.select((s) => s.points));
      if (points.isNotEmpty) {
        final last = points.last;
        point = LatLng(last.latitude, last.longitude);
      }
    }

    // Idle map, or run just started before the first GPS path point arrives.
    if (point == null) {
      final myLocation = ref.watch(myLocationProvider).valueOrNull ??
          ref.watch(mapLastKnownPositionProvider);
      if (myLocation != null) {
        point = LatLng(myLocation.latitude, myLocation.longitude);
        heading = myLocation.heading;
      }
    }

    if (point == null) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: MarkerLayer(
        markers: [
          Marker(
            point: point,
            width: 44,
            height: 44,
            child: _MyLocationMarker(heading: heading),
          ),
        ],
      ),
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
    final anchorIndex =
        ref.watch(activeRunProvider.select((s) => s.currentSegmentAnchorIndex));
    final pendingLoopCount =
        ref.watch(activeRunProvider.select((s) => s.pendingLoops.length));
    final gpsAccuracyMeters =
        ref.watch(activeRunProvider.select((s) => s.gpsAccuracyMeters));

    final distToSegmentStart = points.length >= 2 &&
            anchorIndex < points.length
        ? GeoUtils.haversineMeters(points[anchorIndex], points.last)
        : double.infinity;

    return RunStatsSheet(
      distanceMeters: distanceMeters,
      elapsed: elapsed,
      isOverSpeed: isOverSpeed,
      distToSegmentStartMeters:
          distToSegmentStart.isFinite ? distToSegmentStart : null,
      gpsAccuracyMeters: gpsAccuracyMeters,
      pendingLoopCount: pendingLoopCount,
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

/// Google Maps-style "blue dot": a heading wedge (when moving) plus a
/// pulsing accuracy halo behind a solid center dot. Self-contained
/// animation so it can be dropped into the map's [MarkerLayer] without the
/// parent screen owning another `AnimationController`.
class _MyLocationMarker extends StatefulWidget {
  const _MyLocationMarker({this.heading});

  /// Degrees clockwise from true north; `0` (or GPS-unavailable) hides the
  /// heading wedge rather than pointing it arbitrarily north.
  final double? heading;

  @override
  State<_MyLocationMarker> createState() => _MyLocationMarkerState();
}

class _MyLocationMarkerState extends State<_MyLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  static const _blue = Color(0xFF4285F4);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        final t = _pulseCtrl.value;
        return SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Expanding, fading accuracy halo.
              Opacity(
                opacity: (1 - t).clamp(0.0, 1.0) * 0.35,
                child: Container(
                  width: 16 + (28 * t),
                  height: 16 + (28 * t),
                  decoration: const BoxDecoration(
                    color: _blue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Heading wedge — only when a real heading is available.
              if (widget.heading != null && widget.heading! >= 0)
                Transform.rotate(
                  angle: widget.heading! * (3.14159265 / 180),
                  child: Transform.translate(
                    offset: const Offset(0, -13),
                    child: const CustomPaint(
                      size: Size(18, 18),
                      painter: _HeadingWedgePainter(color: _blue),
                    ),
                  ),
                ),
              // Solid center dot.
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeadingWedgePainter extends CustomPainter {
  const _HeadingWedgePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    final path = ui.Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HeadingWedgePainter oldDelegate) =>
      oldDelegate.color != color;
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
              'Close loop',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoopClosedPill extends StatelessWidget {
  const _LoopClosedPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Text(
        count == 1 ? '1 loop ready' : '$count loops ready',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// "Crossing rival territory" cue shown while the runner's live position is
/// inside a rival's owned polygon — see `rivalConflictProvider`. Purely
/// informational: the actual steal/contest outcome is decided server-side
/// on loop closure, not here.
class _ConflictPill extends StatelessWidget {
  const _ConflictPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.destructive.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.destructive.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.destructive, size: 12),
          SizedBox(width: 6),
          Text(
            'Crossing rival territory',
            style: TextStyle(
              color: AppColors.destructive,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _RunHeader extends StatelessWidget {
  const _RunHeader({
    required this.status,
    required this.isTracking,
    required this.hasPoints,
  });

  final RunSessionStatus status;
  final bool isTracking;
  final bool hasPoints;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = switch (status) {
      RunSessionStatus.requestingPermission =>
        ('Waiting for permission', 'Allow location to begin tracking.'),
      RunSessionStatus.tracking when hasPoints =>
        ('Tracking run', 'Close your loop to claim territory.'),
      RunSessionStatus.tracking =>
        ('Ready to move', 'Start walking or running to draw your path.'),
      RunSessionStatus.finishing =>
        ('Saving run', 'We are finishing your territory check now.'),
      RunSessionStatus.finished =>
        ('Run complete', 'Your result is being saved.'),
      RunSessionStatus.error =>
        ('Run blocked', 'Fix the permission or location issue to continue.'),
      RunSessionStatus.idle when isTracking =>
        ('Tracking run', 'Close your loop to claim territory.'),
      RunSessionStatus.idle =>
        ('Territory run', 'Start a loop, return to it, and claim the area.'),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.foreground,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

// ── Circle icon button ────────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.tint,
    this.enabled = true,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? tint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isAccented = tint != null;
    final effectiveTint = enabled ? tint : AppColors.mutedForeground;
    return Material(
      color: isAccented
          ? (tint ?? AppColors.primary).withValues(alpha: enabled ? 0.15 : 0.08)
          : AppColors.card.withValues(alpha: enabled ? 0.82 : 0.5),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            color: effectiveTint ?? AppColors.foreground,
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
      child: Row(
        children: [
          const Icon(Icons.location_off_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
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
  const _LocatingIndicator({
    required this.phase,
    this.errorMessage,
    this.onRetry,
  });

  final _LocatingPhase phase;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, showSpinner) = switch (phase) {
      _LocatingPhase.requestingPermission => (
          'Allow location access',
          'We need your permission to center the map on you.',
          true,
        ),
      _LocatingPhase.acquiringFix => (
          'Finding your location…',
          'We’ll center the map as soon as GPS is ready.',
          true,
        ),
      _LocatingPhase.failed => (
          'Couldn’t get your location',
          errorMessage ?? 'Check that location services are on and try again.',
          false,
        ),
      _LocatingPhase.hidden => ('', '', false),
    };

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner) ...[
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            const Icon(
              Icons.location_off_outlined,
              color: AppColors.mutedForeground,
              size: 28,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            title,
            style: TextStyle(
              color: AppColors.mutedForeground.withValues(alpha: 0.95),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.mutedForeground.withValues(alpha: 0.8),
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
          if (phase == _LocatingPhase.failed && onRetry != null) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
