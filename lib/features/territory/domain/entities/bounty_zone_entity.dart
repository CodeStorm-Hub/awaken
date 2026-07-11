import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:flutter/foundation.dart';

/// A time-limited bounty zone on the territory map.
/// The ring is parsed from the first coordinate ring of a GeoJSON Polygon
/// returned by the `list_active_bounty_zones` RPC.
@immutable
class BountyZoneEntity {
  const BountyZoneEntity({
    required this.id,
    required this.label,
    required this.multiplier,
    required this.expiresAt,
    required this.ring,
  });

  final String id;
  final String label;

  /// Score multiplier applied when capturing inside this zone.
  final double multiplier;

  final DateTime expiresAt;

  /// Polygon outer ring — at least 3 points to form a valid polygon.
  final List<GeoPointEntity> ring;

  /// Parses a row returned by `list_active_bounty_zones`.
  ///
  /// The `geojson` field is a JSON string produced by `ST_AsGeoJSON`, e.g.:
  /// `{"type":"Polygon","coordinates":[[[lng,lat],…]]}`.
  factory BountyZoneEntity.fromRpc(Map<String, dynamic> row) {
    final id = row['id'] as String;
    final label = (row['label'] as String?) ?? '';
    final multiplier = (row['multiplier'] as num?)?.toDouble() ?? 1.0;
    final expiresAt = DateTime.parse(row['expires_at'] as String);

    final geoJson = row['geojson'] as Map<String, dynamic>?;
    final ring = _parseRing(geoJson);

    return BountyZoneEntity(
      id: id,
      label: label,
      multiplier: multiplier,
      expiresAt: expiresAt,
      ring: ring,
    );
  }

  static List<GeoPointEntity> _parseRing(Map<String, dynamic>? geoJson) {
    if (geoJson == null) return const [];
    final coordinates = geoJson['coordinates'];
    if (coordinates is! List || coordinates.isEmpty) return const [];
    final outer = coordinates[0];
    if (outer is! List) return const [];

    final now = DateTime.now();
    return [
      for (final coord in outer)
        if (coord is List && coord.length >= 2)
          GeoPointEntity(
            latitude: (coord[1] as num).toDouble(),
            longitude: (coord[0] as num).toDouble(),
            timestamp: now,
          ),
    ];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BountyZoneEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
