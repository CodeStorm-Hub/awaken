import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/territory_entity.dart';
import 'package:awaken/features/territory/presentation/widgets/territory_map_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TerritoryEntity territory({
    required String userId,
    required bool owned,
    required String color,
  }) {
    return TerritoryEntity(
      id: 't-$userId',
      userId: userId,
      ownerDisplayName: userId,
      polygons: [
        [
          GeoPointEntity(
            latitude: 0,
            longitude: 0,
            timestamp: DateTime.utc(2026, 1, 1),
          ),
          GeoPointEntity(
            latitude: 0,
            longitude: 1,
            timestamp: DateTime.utc(2026, 1, 1),
          ),
          GeoPointEntity(
            latitude: 1,
            longitude: 1,
            timestamp: DateTime.utc(2026, 1, 1),
          ),
        ],
      ],
      areaSqMeters: 100,
      lastDefendedAt: DateTime.utc(2026, 1, 1),
      isOwnedByCurrentUser: owned,
      mapColorHex: color,
    );
  }

  test('paint style uses each profile map color', () {
    final mine = TerritoryPaintStyle.forTerritory(
      territory(userId: 'me', owned: true, color: '#2ee6c5'),
    );
    final rival = TerritoryPaintStyle.forTerritory(
      territory(userId: 'them', owned: false, color: '#ff7a59'),
    );
    expect(mine.fill, const Color(0xFF2EE6C5));
    expect(rival.fill, const Color(0xFFFF7A59));
    expect(mine.fillAlpha, greaterThan(rival.fillAlpha));
  });

  test('colorFromHex accepts lowercase profile colors', () {
    expect(
      TerritoryPaintStyle.colorFromHex('#abCDef'),
      const Color(0xFFABCDEF),
    );
  });
}
