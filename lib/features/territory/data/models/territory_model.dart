import 'package:awaken/features/territory/data/models/territory_geo_codec.dart';
import 'package:awaken/features/territory/domain/entities/territory_entity.dart';

class TerritoryModel {
  const TerritoryModel({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.geojson,
    required this.areaSqMeters,
    required this.lastDefendedAt,
  });

  factory TerritoryModel.fromJson(Map<String, dynamic> json) {
    return TerritoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      geojson: json['geojson'] as String,
      areaSqMeters: (json['area_sqm'] as num).toDouble(),
      lastDefendedAt: DateTime.parse(json['last_defended_at'] as String),
    );
  }

  final String id;
  final String userId;
  final String? displayName;
  final String geojson;
  final double areaSqMeters;
  final DateTime lastDefendedAt;

  TerritoryEntity toEntity({required String currentUserId}) {
    return TerritoryEntity(
      id: id,
      userId: userId,
      ownerDisplayName: displayName,
      polygons: TerritoryGeoCodec.parseGeoJsonOuterRings(geojson),
      areaSqMeters: areaSqMeters,
      lastDefendedAt: lastDefendedAt,
      isOwnedByCurrentUser: userId == currentUserId,
    );
  }
}
