import 'package:awaken/core/theme/app_colors.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/territory_entity.dart';
import 'package:awaken/features/territory/presentation/widgets/territory_map_palette.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TerritoryEntity territory({
    required String userId,
    required bool owned,
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
    );
  }

  test('owned territory uses aurora teal paint', () {
    final style = TerritoryPaintStyle.forTerritory(
      territory(userId: 'me', owned: true),
    );
    expect(style.fill, AppColors.territoryOwned);
    expect(style.fillAlpha, greaterThan(0.2));
  });

  test('rival colors are stable per user id and not owned teal', () {
    final a = TerritoryPaintStyle.rivalColorForUserId('user-aaa');
    final b = TerritoryPaintStyle.rivalColorForUserId('user-aaa');
    final c = TerritoryPaintStyle.rivalColorForUserId('user-bbb');
    expect(a, b);
    expect(a, isNot(AppColors.territoryOwned));
    // Different ids usually differ; if hash collides, still must be palette.
    expect(AppColors.territoryRivalPalette.contains(a), isTrue);
    expect(AppColors.territoryRivalPalette.contains(c), isTrue);
  });
}
