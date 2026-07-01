import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/territory/domain/entities/territory_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Renders every territory as a "neon tube" polygon: a wide, low-alpha
/// glow border underneath a thin, bright core border, with a translucent
/// fill — per the implementation plan's visual-aesthetics section.
///
/// Two `Polygon` entries per ring (glow drawn first, core drawn second,
/// same path) approximates a `BackdropFilter`/blur glow without needing
/// per-polygon blur, which `flutter_map`'s canvas layer doesn't support.
class TerritoryPolygonLayer extends StatelessWidget {
  const TerritoryPolygonLayer({super.key, required this.territories});

  final List<TerritoryEntity> territories;

  @override
  Widget build(BuildContext context) {
    final polygons = <Polygon>[];

    for (final territory in territories) {
      final color = territory.isOwnedByCurrentUser ? AppColors.primary : AppColors.destructive;
      final glow = territory.isOwnedByCurrentUser
          ? AppColors.primaryGlow
          : AppColors.destructiveGlow;

      for (final ring in territory.polygons) {
        if (ring.length < 3) continue;
        final points = ring.map((p) => LatLng(p.latitude, p.longitude)).toList();

        polygons.add(
          Polygon(
            points: points,
            color: Colors.transparent,
            borderColor: glow,
            borderStrokeWidth: 10,
          ),
        );
        polygons.add(
          Polygon(
            points: points,
            color: color.withValues(alpha: 0.18),
            borderColor: color,
            borderStrokeWidth: 2.5,
          ),
        );
      }
    }

    return PolygonLayer(polygons: polygons);
  }
}
