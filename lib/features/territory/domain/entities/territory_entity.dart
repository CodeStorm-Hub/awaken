import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:flutter/foundation.dart';

/// A single ring (closed loop of lat/lng vertices) of a territory polygon.
typedef PolygonRing = List<GeoPointEntity>;

/// One player's owned land, possibly made of several disjoint polygons
/// (a `MultiPolygon` from PostGIS) after merges and steals.
@immutable
class TerritoryEntity {
  const TerritoryEntity({
    required this.id,
    required this.userId,
    required this.ownerDisplayName,
    required this.polygons,
    required this.areaSqMeters,
    required this.lastDefendedAt,
    required this.isOwnedByCurrentUser,
  });

  final String id;
  final String userId;
  final String? ownerDisplayName;

  /// Each entry is one polygon's outer ring; PostGIS holes are not modeled
  /// client-side since territory shapes here are never expected to contain
  /// donut holes (only unions/differences of capture loops).
  final List<PolygonRing> polygons;

  final double areaSqMeters;
  final DateTime lastDefendedAt;
  final bool isOwnedByCurrentUser;
}
