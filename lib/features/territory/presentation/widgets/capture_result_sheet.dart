import 'dart:ui';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/territory/domain/entities/capture_result_entity.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/presentation/widgets/territory_vector_tile_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

/// Rich, non-auto-dismissing result surface shown after a run claims (or
/// steals) territory — replaces the plain `_ResultBanner` for successful
/// captures specifically, since a claim/steal is the feature's core payoff
/// moment and deserves more than five seconds of small text.
class CaptureResultSheet extends StatelessWidget {
  const CaptureResultSheet({
    super.key,
    required this.captureResult,
    required this.runPoints,
  });

  final CaptureResultEntity captureResult;
  final List<GeoPointEntity> runPoints;

  static Future<void> show(
    BuildContext context, {
    required CaptureResultEntity captureResult,
    required List<GeoPointEntity> runPoints,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CaptureResultSheet(
        captureResult: captureResult,
        runPoints: runPoints,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stole = captureResult.stoleFromRival;
    final accent = stole ? AppColors.destructive : AppColors.success;

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
                const SizedBox(height: 20),
                Icon(
                  stole ? Icons.flash_on_rounded : Icons.flag_rounded,
                  color: accent,
                  size: 36,
                ),
                const SizedBox(height: 10),
                Text(
                  stole ? 'Territory stolen!' : 'Territory claimed!',
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
                    captureResult.rivalsAffected == 1
                        ? 'Cut into 1 rival territory'
                        : 'Cut into ${captureResult.rivalsAffected} rival territories',
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                if (runPoints.length >= 3)
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadius),
                    child: SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: _CaptureMinimap(
                        points: runPoints,
                        accent: accent,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _StatBlock(
                        label: 'Claimed',
                        value:
                            '${captureResult.claimedAreaSqMeters.toStringAsFixed(0)} m²',
                        valueColor: accent,
                      ),
                    ),
                    Expanded(
                      child: _StatBlock(
                        label: 'Total owned',
                        value:
                            '${captureResult.totalOwnedAreaSqMeters.toStringAsFixed(0)} m²',
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
                        icon: const Icon(Icons.ios_share_rounded, size: 18),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.foreground,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                          Navigator.of(context).pop();
                          context.push(AppRoutes.leaderboard);
                        },
                        icon: const Icon(Icons.leaderboard_rounded, size: 18),
                        label: const Text('Leaderboard'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
      ),
    );
  }

  void _shareResult(BuildContext context) {
    final text = captureResult.stoleFromRival
        ? 'I just stole ${captureResult.claimedAreaSqMeters.toStringAsFixed(0)} m² of territory on Awaken! 🏃⚔️'
        : 'I just claimed ${captureResult.claimedAreaSqMeters.toStringAsFixed(0)} m² of territory on Awaken! 🏃🚩';
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

/// Small, non-interactive map thumbnail zoomed to the just-completed loop.
/// Reuses the same branded vector basemap as the run screen rather than a
/// static image export, so it stays visually consistent and needs no extra
/// image-rendering dependency.
class _CaptureMinimap extends StatelessWidget {
  const _CaptureMinimap({required this.points, required this.accent});

  final List<GeoPointEntity> points;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final latLngPoints =
        points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    final bounds = LatLngBounds.fromPoints(latLngPoints);

    return IgnorePointer(
      child: FlutterMap(
        options: MapOptions(
          initialCameraFit: CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.all(24),
          ),
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          const TerritoryVectorTileLayer(),
          PolygonLayer(
            polygons: [
              Polygon(
                points: latLngPoints,
                color: accent.withValues(alpha: 0.22),
                borderColor: accent,
                borderStrokeWidth: 3,
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
