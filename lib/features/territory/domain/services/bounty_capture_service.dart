import 'package:awaken/features/territory/domain/entities/bounty_zone_entity.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/services/geo_utils.dart';

/// Picks the best (highest multiplier) bounty zone whose centroid lies inside
/// any of the captured loop rings.
abstract final class BountyCaptureService {
  static ({double multiplier, String label})? evaluate({
    required List<List<GeoPointEntity>> loops,
    required List<BountyZoneEntity> zones,
  }) {
    BountyZoneEntity? best;
    for (final zone in zones) {
      if (zone.ring.length < 3) continue;
      final centroid = _centroid(zone.ring);
      for (final loop in loops) {
        if (loop.length < 3) continue;
        if (GeoUtils.isPointInPolygon(centroid, loop)) {
          if (best == null || zone.multiplier > best.multiplier) {
            best = zone;
          }
        }
      }
    }
    if (best == null) return null;
    return (multiplier: best.multiplier, label: best.label);
  }

  static GeoPointEntity _centroid(List<GeoPointEntity> ring) {
    var lat = 0.0;
    var lng = 0.0;
    for (final p in ring) {
      lat += p.latitude;
      lng += p.longitude;
    }
    return GeoPointEntity(
      latitude: lat / ring.length,
      longitude: lng / ring.length,
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
