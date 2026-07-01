import 'dart:convert';

import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/territory_entity.dart';

/// Converts between domain GPS points and the WKT/GeoJSON wire formats
/// PostGIS speaks. PostgREST RPC parameters declared `geometry` accept EWKT
/// text directly (PostGIS's `geometry_in` parser recognizes EWKT, not just
/// WKB), so no separate geometry library dependency is needed.
abstract final class TerritoryGeoCodec {
  /// Builds an `SRID=4326;POLYGON((...))` EWKT literal from a closed-loop
  /// run path, for the `capture_territory` RPC.
  static String pointsToPolygonEwkt(List<GeoPointEntity> points) {
    final coords = points.map((p) => '${p.longitude} ${p.latitude}').toList();
    // PostGIS requires the ring to be explicitly closed.
    if (coords.isEmpty || coords.first != coords.last) {
      coords.add(coords.first);
    }
    return 'SRID=4326;POLYGON((${coords.join(', ')}))';
  }

  /// Builds an `SRID=4326;LINESTRING(...)` EWKT literal from a run path,
  /// for `runs.path` inserts and the `touch_territory_defense` RPC.
  static String pointsToLineStringEwkt(List<GeoPointEntity> points) {
    final coords = points.map((p) => '${p.longitude} ${p.latitude}').join(', ');
    return 'SRID=4326;LINESTRING($coords)';
  }

  /// Parses the `geojson` text column from `territories_geojson`
  /// (`ST_AsGeoJSON` output) into outer rings only — territory shapes here
  /// never carry meaningful holes, only unions/differences of capture loops.
  static List<PolygonRing> parseGeoJsonOuterRings(String geojson) {
    final decoded = jsonDecode(geojson) as Map<String, dynamic>;
    final type = decoded['type'] as String;
    final coordinates = decoded['coordinates'] as List<dynamic>;

    List<PolygonRing> ringsFromPolygonCoords(List<dynamic> polygonCoords) {
      if (polygonCoords.isEmpty) return const [];
      final outer = polygonCoords.first as List<dynamic>;
      return [_toRing(outer)];
    }

    switch (type) {
      case 'Polygon':
        return ringsFromPolygonCoords(coordinates);
      case 'MultiPolygon':
        return coordinates
            .cast<List<dynamic>>()
            .expand(ringsFromPolygonCoords)
            .toList();
      default:
        return const [];
    }
  }

  static PolygonRing _toRing(List<dynamic> ring) {
    return ring.map((vertex) {
      final pair = (vertex as List<dynamic>).cast<num>();
      return GeoPointEntity(
        longitude: pair[0].toDouble(),
        latitude: pair[1].toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }).toList();
  }
}
