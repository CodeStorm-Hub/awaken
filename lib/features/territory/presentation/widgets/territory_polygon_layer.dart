import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/features/territory/domain/entities/territory_entity.dart';
import 'package:awaken/features/territory/presentation/widgets/territory_map_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Neon turf polygons on the dark run map.
///
/// Draw order per ring: soft fill → wide glow stroke → bright core stroke.
/// Owned land uses aurora teal; each rival gets a hashed night-turf hue so
/// the map reads as a game board instead of a solid wall of error-red.
///
/// At low zoom the glow ring is skipped to cut draw calls.
class TerritoryPolygonLayer extends StatelessWidget {
  const TerritoryPolygonLayer({
    super.key,
    required this.territories,
    this.mapZoom = AppConstants.territoryMapInitialZoom,
  });

  final List<TerritoryEntity> territories;
  final double mapZoom;

  @override
  Widget build(BuildContext context) {
    final polygons = <Polygon>[];
    final drawGlow = mapZoom >= AppConstants.territoryPolygonGlowMinZoom;

    // Rivals first, owned last — your turf always sits on top at seams.
    final ordered = [
      ...territories.where((t) => !t.isOwnedByCurrentUser),
      ...territories.where((t) => t.isOwnedByCurrentUser),
    ];

    for (final territory in ordered) {
      final style = TerritoryPaintStyle.forTerritory(territory);

      for (final ring in territory.polygons) {
        if (ring.length < 3) continue;
        final points =
            ring.map((p) => LatLng(p.latitude, p.longitude)).toList();

        // Soft interior wash — translucent enough for street labels.
        polygons.add(
          Polygon(
            points: points,
            color: style.fill.withValues(alpha: style.fillAlpha),
            borderColor: Colors.transparent,
            borderStrokeWidth: 0,
          ),
        );

        if (drawGlow) {
          polygons.add(
            Polygon(
              points: points,
              color: Colors.transparent,
              borderColor: style.glow,
              borderStrokeWidth: style.glowWidth,
            ),
          );
        }

        // Bright silhouette edge.
        polygons.add(
          Polygon(
            points: points,
            color: Colors.transparent,
            borderColor: style.stroke,
            borderStrokeWidth: style.strokeWidth,
          ),
        );
      }
    }

    return PolygonLayer(
      polygons: polygons,
      simplificationTolerance: mapZoom < 14 ? 0.5 : 0.0,
    );
  }
}
