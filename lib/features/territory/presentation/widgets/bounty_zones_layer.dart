import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/territory/domain/entities/bounty_zone_entity.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Map polygons + center labels for active bounty zones.
class BountyZonesLayer extends ConsumerWidget {
  const BountyZonesLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = ref.watch(bountyZonesProvider).valueOrNull ?? const [];
    if (zones.isEmpty) return const SizedBox.shrink();

    final zoom = ref.watch(territoryMapZoomProvider);
    final showFullLabel = zoom >= 14.5;

    return Stack(
      children: [
        PolygonLayer(
          polygons: [
            for (final zone in zones)
              if (zone.ring.length >= 3)
                Polygon(
                  points: zone.ring
                      .map((p) => LatLng(p.latitude, p.longitude))
                      .toList(),
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderColor: AppColors.accent.withValues(alpha: 0.35),
                  borderStrokeWidth: 1.2,
                ),
          ],
        ),
        // Bold dashed ring = the road loop to run.
        PolylineLayer(
          polylines: [
            for (final zone in zones)
              if (zone.ring.length >= 3)
                Polyline(
                  points: [
                    for (final p in zone.ring)
                      LatLng(p.latitude, p.longitude),
                  ],
                  color: AppColors.accent,
                  strokeWidth: 3.5,
                  borderStrokeWidth: 1.5,
                  borderColor: AppColors.card.withValues(alpha: 0.7),
                  pattern: StrokePattern.dashed(segments: const [14, 10]),
                ),
          ],
        ),
        MarkerLayer(
          markers: [
            for (final zone in zones)
              if (zone.ring.length >= 3)
                Marker(
                  point: _centroid(zone.ring),
                  width: showFullLabel ? 148 : 72,
                  height: showFullLabel ? 52 : 36,
                  alignment: Alignment.center,
                  child: _BountyZoneMarker(
                    zone: zone,
                    compact: !showFullLabel,
                  ),
                ),
          ],
        ),
      ],
    );
  }

  static LatLng _centroid(List<GeoPointEntity> ring) {
    var lat = 0.0;
    var lng = 0.0;
    // Skip duplicate closing vertex if present.
    final n = ring.length > 1 &&
            ring.first.latitude == ring.last.latitude &&
            ring.first.longitude == ring.last.longitude
        ? ring.length - 1
        : ring.length;
    for (var i = 0; i < n; i++) {
      lat += ring[i].latitude;
      lng += ring[i].longitude;
    }
    return LatLng(lat / n, lng / n);
  }
}

class _BountyZoneMarker extends StatelessWidget {
  const _BountyZoneMarker({
    required this.zone,
    required this.compact,
  });

  final BountyZoneEntity zone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final mult = '${zone.multiplier.toStringAsFixed(
      zone.multiplier == zone.multiplier.roundToDouble() ? 0 : 1,
    )}×';

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppConstants.chipRadius),
          border: Border.all(color: AppColors.accent, width: 1.2),
          boxShadow: const [
            BoxShadow(color: AppColors.accentGlow, blurRadius: 10),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 5 : 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: compact ? 14 : 16,
                color: AppColors.accent,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mult,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: 0.4,
                      ),
                    ),
                    if (!compact)
                      Text(
                        zone.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.foreground,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          letterSpacing: 0.3,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact explainer card so new users understand purple bounty boxes.
class BountyZonesLegendCard extends ConsumerWidget {
  const BountyZonesLegendCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zones = ref.watch(bountyZonesProvider).valueOrNull ?? const [];
    if (zones.isEmpty) return const SizedBox.shrink();

    final top = [...zones]
      ..sort((a, b) => b.multiplier.compareTo(a.multiplier));
    final preview = top.take(3).toList();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.55)),
          boxShadow: const [
            BoxShadow(color: AppColors.accentGlow, blurRadius: 16),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 16,
                  color: AppColors.accent,
                ),
                SizedBox(width: 6),
                Text(
                  'BOUNTY ZONES',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Dashed purple loops follow street blocks. Run the road route '
              'around a zone to enclose it and earn the multiplier.',
              style: TextStyle(
                color: AppColors.mutedForeground,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final z in preview)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppConstants.chipRadius),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Text(
                      '${z.multiplier.toStringAsFixed(z.multiplier == z.multiplier.roundToDouble() ? 0 : 1)}× · ${z.label}',
                      style: const TextStyle(
                        color: AppColors.foreground,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (zones.length > preview.length)
                  Text(
                    '+${zones.length - preview.length} more',
                    style: const TextStyle(
                      color: AppColors.mutedForeground,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
