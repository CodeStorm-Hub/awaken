import 'dart:math' as math;

import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';

/// Pure spatial math shared by run validation, RDP simplification, and the
/// territory map UI. No Flutter/platform dependencies — safe to run in an
/// isolate via `compute()`.
abstract final class GeoUtils {
  static const double _earthRadiusMeters = 6371000.0;

  /// Great-circle distance between two points, in meters.
  static double haversineMeters(GeoPointEntity a, GeoPointEntity b) {
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLon = _toRadians(b.longitude - a.longitude);

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return _earthRadiusMeters * c;
  }

  /// Instantaneous speed between two consecutive fixes, in km/h.
  /// Returns 0 if the points share a timestamp (avoids divide-by-zero).
  static double speedKmh(GeoPointEntity a, GeoPointEntity b) {
    final seconds = b.timestamp.difference(a.timestamp).inMilliseconds / 1000.0;
    if (seconds <= 0) return 0;
    final meters = haversineMeters(a, b);
    return (meters / seconds) * 3.6;
  }

  /// Cumulative path length over an ordered list of fixes.
  static double pathDistanceMeters(List<GeoPointEntity> points) {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += haversineMeters(points[i - 1], points[i]);
    }
    return total;
  }

  /// Ray-casting point-in-polygon test (even-odd rule). `ring` is treated as
  /// a closed loop — the first/last point need not be duplicated. Approximate
  /// but sufficient for lat/lng at the scale of a single territory: no
  /// projection is applied, matching how territory rings are stored and
  /// rendered elsewhere in this feature.
  static bool isPointInPolygon(GeoPointEntity point, List<GeoPointEntity> ring) {
    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = ring[i].longitude;
      final yi = ring[i].latitude;
      final xj = ring[j].longitude;
      final yj = ring[j].latitude;

      final crossesRay = (yi > point.latitude) != (yj > point.latitude) &&
          point.longitude < (xj - xi) * (point.latitude - yi) / (yj - yi) + xi;
      if (crossesRay) inside = !inside;
    }
    return inside;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;
}
