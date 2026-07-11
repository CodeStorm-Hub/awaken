import 'dart:async';
import 'dart:ui';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/territory/domain/entities/capture_result_entity.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:awaken/features/territory/presentation/widgets/distance_format.dart';
import 'package:awaken/features/territory/presentation/widgets/territory_vector_tile_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

/// Rich, non-auto-dismissing result surface shown after a run claims (or
/// steals) territory — opens with a cinematic flyover, then reveals stats.
class CaptureResultSheet extends ConsumerStatefulWidget {
  const CaptureResultSheet({
    super.key,
    required this.sessionCaptureResult,
    required this.runPoints,
    this.distanceMeters = 0,
    this.elapsed = Duration.zero,
  });

  final SessionCaptureResultEntity sessionCaptureResult;
  final List<GeoPointEntity> runPoints;
  final double distanceMeters;
  final Duration elapsed;

  static Future<void> show(
    BuildContext context, {
    required SessionCaptureResultEntity sessionCaptureResult,
    required List<GeoPointEntity> runPoints,
    double distanceMeters = 0,
    Duration elapsed = Duration.zero,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CaptureResultSheet(
        sessionCaptureResult: sessionCaptureResult,
        runPoints: runPoints,
        distanceMeters: distanceMeters,
        elapsed: elapsed,
      ),
    );
  }

  @override
  ConsumerState<CaptureResultSheet> createState() => _CaptureResultSheetState();
}

class _CaptureResultSheetState extends ConsumerState<CaptureResultSheet>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _fillCtrl;
  late final AnimationController _revealCtrl;
  bool _showStats = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _fillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _runFlyover());
  }

  Future<void> _runFlyover() async {
    if (!mounted || widget.runPoints.length < 3) {
      setState(() => _showStats = true);
      _revealCtrl.forward();
      return;
    }

    final latLngPoints = widget.runPoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();
    final bounds = LatLngBounds.fromPoints(latLngPoints);

    try {
      // Start high / wide — "approach from altitude".
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(72),
        ),
      );
    } catch (_) {
      // Map may not be ready yet — continue to pulse/stats.
    }

    if (!mounted) return;
    unawaited(_fillCtrl.forward());

    final mid = bounds.center;
    final wideZoom = _mapController.camera.zoom;
    final diveZoom = (wideZoom + 1.15).clamp(
      AppConstants.territoryMapMinZoom,
      AppConstants.territoryMapMaxZoom,
    );
    final cruiseZoom = (wideZoom + 0.55).clamp(
      AppConstants.territoryMapMinZoom,
      AppConstants.territoryMapMaxZoom,
    );

    // Waypoints along the claim path for a longer cinematic beat.
    final n = latLngPoints.length;
    final legs = <LatLng>[
      latLngPoints[0],
      latLngPoints[n ~/ 4],
      latLngPoints[n ~/ 2],
      latLngPoints[(3 * n) ~/ 4],
      mid,
    ];

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    // Dive in.
    _mapController.move(legs[0], diveZoom);
    await Future<void>.delayed(const Duration(milliseconds: 480));
    if (!mounted) return;
    for (var i = 1; i < legs.length - 1; i++) {
      _mapController.move(legs[i], cruiseZoom);
      await Future<void>.delayed(const Duration(milliseconds: 420));
      if (!mounted) return;
    }
    // Pull back to framed claim.
    _mapController.move(mid, wideZoom);
    await Future<void>.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;

    setState(() => _showStats = true);
    await _revealCtrl.forward();
  }

  @override
  void dispose() {
    _fillCtrl.dispose();
    _revealCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stole = widget.sessionCaptureResult.stoleFromRival;
    final accent = stole ? AppColors.destructive : AppColors.success;
    final loopCount = widget.sessionCaptureResult.loopsCaptured;
    final title = stole
        ? 'Territory stolen!'
        : loopCount > 1
            ? '$loopCount territories claimed!'
            : 'Territory claimed!';

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppConstants.cardRadius),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: AppColors.card.withValues(alpha: 0.94),
            border: const Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.mutedForeground.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.runPoints.length >= 3)
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                    child: SizedBox(
                      height: _showStats ? 160 : 240,
                      width: double.infinity,
                      child: AnimatedBuilder(
                        animation: _fillCtrl,
                        builder: (context, _) {
                          final t = Curves.easeInOutCubic.transform(
                            _fillCtrl.value,
                          );
                          // Fake 3D: pitch + scale as the camera "dives".
                          final dive = t < 0.45
                              ? (t / 0.45)
                              : (1.0 - ((t - 0.45) / 0.55) * 0.4);
                          final peak = t < 0.55
                              ? (t / 0.55)
                              : (1.0 - ((t - 0.55) / 0.45) * 0.35);
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.0014)
                              ..rotateX(-0.18 * dive),
                            child: Transform.scale(
                              scale: 1.0 + dive * 0.08,
                              child: _CaptureFlyoverMap(
                              controller: _mapController,
                              points: widget.runPoints,
                              accent: accent,
                              fillAlpha: 0.12 + peak * 0.38,
                              trailProgress: t,
                            ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (_showStats) ...[
                  SizeTransition(
                    sizeFactor: _revealCtrl,
                    child: FadeTransition(
                      opacity: _revealCtrl,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Icon(
                            stole
                                ? Icons.flash_on_rounded
                                : Icons.flag_rounded,
                            color: accent,
                            size: 36,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            style: TextStyle(
                              color: AppColors.foreground,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              shadows: [Shadow(color: accent, blurRadius: 18)],
                            ),
                          ),
                          if (stole) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.sessionCaptureResult.totalRivalsAffected ==
                                      1
                                  ? 'Cut into 1 rival territory'
                                  : 'Cut into ${widget.sessionCaptureResult.totalRivalsAffected} rival territories',
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 13,
                              ),
                            ),
                          ] else if (widget
                              .sessionCaptureResult.hasPartialFailure) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${widget.sessionCaptureResult.loopsRejectedTooSmall} loop(s) too small to claim',
                              style: const TextStyle(
                                color: AppColors.mutedForeground,
                                fontSize: 13,
                              ),
                            ),
                          ],
                          if (widget.sessionCaptureResult.hitBounty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(
                                  AppConstants.chipRadius,
                                ),
                                border: Border.all(color: AppColors.accent),
                              ),
                              child: Text(
                                'BOUNTY · ${widget.sessionCaptureResult.bountyLabel} · ${widget.sessionCaptureResult.bountyMultiplier.toStringAsFixed(1)}×',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _StatBlock(
                                  label: 'Distance',
                                  value: formatDistanceKm(widget.distanceMeters),
                                ),
                              ),
                              Expanded(
                                child: _StatBlock(
                                  label: 'Avg speed',
                                  value: formatSpeedKmh(
                                    averageSpeedKmh(
                                      widget.distanceMeters,
                                      widget.elapsed,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatBlock(
                                  label: loopCount > 1
                                      ? 'Claimed (total)'
                                      : 'Claimed',
                                  value:
                                      '${widget.sessionCaptureResult.totalClaimedAreaSqMeters.toStringAsFixed(0)} m²',
                                  valueColor: accent,
                                ),
                              ),
                              Expanded(
                                child: _StatBlock(
                                  label: 'Total owned',
                                  value:
                                      '${(widget.sessionCaptureResult.totalOwnedAreaSqMeters / 1e6).toStringAsFixed(3)} km²',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _shareResult(context),
                                  icon: const Icon(
                                    Icons.ios_share_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Share'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.foreground,
                                    side: const BorderSide(
                                      color: AppColors.border,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppConstants.chipRadius,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ref.invalidate(leaderboardProvider);
                                    ref.invalidate(territoryListProvider);
                                    Navigator.of(context).pop();
                                    context.go(AppRoutes.leaderboard);
                                  },
                                  icon: const Icon(
                                    Icons.leaderboard_rounded,
                                    size: 18,
                                  ),
                                  label: const Text('Leaderboard'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accent,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppConstants.chipRadius,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _shareResult(BuildContext context) {
    final area = widget.sessionCaptureResult.totalClaimedAreaSqMeters
        .toStringAsFixed(0);
    final text = widget.sessionCaptureResult.stoleFromRival
        ? 'I just stole $area m² of territory on Awaken!'
        : 'I just claimed $area m² of territory on Awaken!';
    SharePlus.instance.share(ShareParams(text: text));
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.mutedForeground,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.foreground,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CaptureFlyoverMap extends StatelessWidget {
  const _CaptureFlyoverMap({
    required this.controller,
    required this.points,
    required this.accent,
    required this.fillAlpha,
    this.trailProgress = 1,
  });

  final MapController controller;
  final List<GeoPointEntity> points;
  final Color accent;
  final double fillAlpha;
  final double trailProgress;

  @override
  Widget build(BuildContext context) {
    final latLngPoints =
        points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final bounds = LatLngBounds.fromPoints(latLngPoints);
    final trailEnd =
        (latLngPoints.length * trailProgress.clamp(0.0, 1.0)).ceil().clamp(
              2,
              latLngPoints.length,
            );
    final trail = latLngPoints.sublist(0, trailEnd);

    return IgnorePointer(
      child: FlutterMap(
        key: territoryCaptureMinimapKey,
        mapController: controller,
        options: MapOptions(
          backgroundColor: AppColors.background,
          initialCameraFit: CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(24),
          ),
          minZoom: AppConstants.territoryMapMinZoom,
          maxZoom: AppConstants.territoryMapMaxZoom,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          const TerritoryVectorTileLayer(forceRender: true),
          PolygonLayer(
            polygons: [
              Polygon(
                points: latLngPoints,
                color: accent.withValues(alpha: fillAlpha),
                borderColor: accent,
                borderStrokeWidth: 3,
              ),
            ],
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: trail,
                color: accent.withValues(alpha: 0.9),
                strokeWidth: 3.5,
              ),
            ],
          ),
          const RichAttributionWidget(
            alignment: AttributionAlignment.bottomRight,
            permanentHeight: 16,
            popupBackgroundColor: AppColors.card,
            attributions: [
              TextSourceAttribution(
                'OpenStreetMap',
                textStyle: TextStyle(
                  color: AppColors.mutedForeground,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
