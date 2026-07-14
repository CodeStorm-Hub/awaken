import 'dart:math' as math;

import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';

/// Ramer-Douglas-Peucker vertex reduction on a GPS path, treating lat/lng as
/// a flat plane (fine at the epsilon scale — a few meters — this runs at).
///
/// Pure function, safe to run via `compute()` off the UI thread per the
/// implementation plan's "heavy client-side spatial work" requirement.
abstract final class RdpSimplifier {
  static List<GeoPointEntity> simplify(
    List<GeoPointEntity> points,
    double epsilonMeters,
  ) {
    if (points.length < 3) return points;

    var maxDistance = 0.0;
    var maxIndex = 0;
    final first = points.first;
    final last = points.last;

    for (var i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistanceMeters(points[i], first, last);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    if (maxDistance <= epsilonMeters) {
      return [first, last];
    }

    final left = simplify(points.sublist(0, maxIndex + 1), epsilonMeters);
    final right = simplify(points.sublist(maxIndex), epsilonMeters);
    return [...left.sublist(0, left.length - 1), ...right];
  }

  /// Approximates lat/lng as a local equirectangular plane (meters) — valid
  /// at the short distances a single run covers, avoids full great-circle
  /// projection math for a per-point simplification pass.
  static double _perpendicularDistanceMeters(
    GeoPointEntity point,
    GeoPointEntity lineStart,
    GeoPointEntity lineEnd,
  ) {
    final latRad = lineStart.latitude * math.pi / 180.0;
    const metersPerDegreeLat = 111320.0;
    final metersPerDegreeLon = 111320.0 * math.cos(latRad);

    final x = (point.longitude - lineStart.longitude) * metersPerDegreeLon;
    final y = (point.latitude - lineStart.latitude) * metersPerDegreeLat;
    final endX = (lineEnd.longitude - lineStart.longitude) * metersPerDegreeLon;
    final endY = (lineEnd.latitude - lineStart.latitude) * metersPerDegreeLat;

    final lineLengthSq = endX * endX + endY * endY;
    if (lineLengthSq == 0) {
      return math.sqrt(x * x + y * y);
    }

    final t = ((x * endX + y * endY) / lineLengthSq).clamp(0.0, 1.0);
    final projX = t * endX;
    final projY = t * endY;
    final dx = x - projX;
    final dy = y - projY;
    return math.sqrt(dx * dx + dy * dy);
  }
}
