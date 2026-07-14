import 'dart:convert';
import 'dart:math' as math;

import 'package:awaken/features/territory/data/repositories/territory_local_repository_impl.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/territory_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks/fake_territory_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final areaCalculator = FakeTerritoryRepository();
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  List<GeoPointEntity> rectangleLoop({
    required double startLat,
    required double startLng,
    required double widthMeters,
    required double heightMeters,
    DateTime? startTime,
  }) {
    final start = startTime ?? epoch;
    final refLatRad = startLat * math.pi / 180.0;
    const metersPerDegreeLat = 111194.9266;
    final metersPerDegreeLon = 111194.9266 * math.cos(refLatRad);

    final dLat = heightMeters / metersPerDegreeLat;
    final dLon = widthMeters / metersPerDegreeLon;

    return [
      GeoPointEntity(latitude: startLat, longitude: startLng, timestamp: start),
      GeoPointEntity(
        latitude: startLat + dLat,
        longitude: startLng,
        timestamp: start.add(const Duration(seconds: 30)),
      ),
      GeoPointEntity(
        latitude: startLat + dLat,
        longitude: startLng + dLon,
        timestamp: start.add(const Duration(seconds: 60)),
      ),
      GeoPointEntity(
        latitude: startLat,
        longitude: startLng + dLon,
        timestamp: start.add(const Duration(seconds: 90)),
      ),
    ];
  }

  String encodeTerritory(TerritoryEntity territory) {
    return jsonEncode({
      'id': territory.id,
      'user_id': territory.userId,
      'owner_display_name': territory.ownerDisplayName,
      'polygons': territory.polygons
          .map(
            (ring) => ring
                .map(
                  (point) => {
                    'latitude': point.latitude,
                    'longitude': point.longitude,
                    'timestamp': point.timestamp.toIso8601String(),
                  },
                )
                .toList(),
          )
          .toList(),
      'area_sq_meters': territory.areaSqMeters,
      'last_defended_at': territory.lastDefendedAt.toIso8601String(),
    });
  }

  Future<TerritoryLocalRepositoryImpl> repoWithRivals(
    List<TerritoryEntity> rivals,
  ) async {
    SharedPreferences.setMockInitialValues({
      'awaken_local_territories': rivals.map(encodeTerritory).toList(),
      'awaken_local_runs': <String>[],
    });
    return TerritoryLocalRepositoryImpl();
  }

  TerritoryEntity rival({
    required String id,
    required List<GeoPointEntity> polygons,
    required double areaSqMeters,
  }) {
    return TerritoryEntity(
      id: id,
      userId: 'rival-1',
      ownerDisplayName: 'Rival',
      polygons: [polygons],
      areaSqMeters: areaSqMeters,
      lastDefendedAt: DateTime.now(),
      isOwnedByCurrentUser: false,
    );
  }

  group('TerritoryLocalRepositoryImpl geometry fixtures', () {
    test('rectangle merge (ST_Union equivalent)', () async {
      final repo = TerritoryLocalRepositoryImpl();
      final loop1 = rectangleLoop(
        startLat: 40.7120,
        startLng: -74.0060,
        widthMeters: 60,
        heightMeters: 60,
      );
      final loop2 = rectangleLoop(
        startLat: 40.7123,
        startLng: -74.0060,
        widthMeters: 60,
        heightMeters: 60,
      );

      await repo.captureTerritory(loop1);
      await repo.captureTerritory(loop2);

      final territories = await repo.getAllTerritories();
      final userTerritory = territories.firstWhere(
        (t) => t.userId == 'local-user',
      );

      expect(userTerritory.polygons.length, equals(1));
      expect(
        userTerritory.areaSqMeters,
        greaterThan(areaCalculator.calculatePolygonArea(loop1)),
      );
    });

    test('overlap steal (ST_Difference equivalent)', () async {
      final rivalLoop = rectangleLoop(
        startLat: 40.7135,
        startLng: -74.0055,
        widthMeters: 100,
        heightMeters: 100,
      );
      final rivalArea = areaCalculator.calculatePolygonArea(rivalLoop);
      final repo = await repoWithRivals([
        rival(id: 'rival-t', polygons: rivalLoop, areaSqMeters: rivalArea),
      ]);

      final userLoop = rectangleLoop(
        startLat: 40.7130,
        startLng: -74.0050,
        widthMeters: 100,
        heightMeters: 100,
      );
      await repo.captureTerritory(userLoop);

      final territories = await repo.getAllTerritories();
      final updatedRival = territories.firstWhere((t) => t.userId == 'rival-1');

      expect(updatedRival.areaSqMeters, lessThan(rivalArea));
      expect(updatedRival.areaSqMeters, greaterThan(1.0));
    });

    test(
      'split rival into multiple polygons when claim cuts through middle',
      () async {
        final rivalLoop = [
          GeoPointEntity(
            latitude: 40.7120,
            longitude: -74.0060,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7130,
            longitude: -74.0060,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7150,
            longitude: -74.0060,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7170,
            longitude: -74.0060,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7180,
            longitude: -74.0060,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7180,
            longitude: -74.0058,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7170,
            longitude: -74.0058,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7150,
            longitude: -74.0058,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7130,
            longitude: -74.0058,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7120,
            longitude: -74.0058,
            timestamp: epoch,
          ),
        ];
        final repo = await repoWithRivals([
          rival(id: 'rival-t', polygons: rivalLoop, areaSqMeters: 10000),
        ]);

        final userLoop = rectangleLoop(
          startLat: 40.7140,
          startLng: -74.0065,
          widthMeters: 100,
          heightMeters: 220,
        );
        await repo.captureTerritory(userLoop);

        final territories = await repo.getAllTerritories();
        final updatedRival = territories.firstWhere(
          (t) => t.userId == 'rival-1',
        );

        expect(updatedRival.polygons.length, greaterThan(1));
      },
    );

    test('sliver cleanup keeps exactly 1.0 m² rival when untouched', () async {
      final rivalLoop = rectangleLoop(
        startLat: 40.7128,
        startLng: -74.0060,
        widthMeters: 1.0,
        heightMeters: 1.0,
      );
      final rivalArea = areaCalculator.calculatePolygonArea(rivalLoop);
      expect(rivalArea, closeTo(1.0, 0.05));

      final repo = await repoWithRivals([
        rival(id: 'rival-t', polygons: rivalLoop, areaSqMeters: rivalArea),
      ]);

      final nonOverlappingClaim = rectangleLoop(
        startLat: 40.7135,
        startLng: -74.0060,
        widthMeters: 10,
        heightMeters: 10,
      );
      await repo.captureTerritory(nonOverlappingClaim);

      final territories = await repo.getAllTerritories();
      expect(territories.any((t) => t.userId == 'rival-1'), isTrue);
    });

    test(
      'sliver cleanup deletes exactly 0.99 m² rival when fully consumed',
      () async {
        final rivalLoop = rectangleLoop(
          startLat: 40.7128,
          startLng: -74.0060,
          widthMeters: 0.99,
          heightMeters: 1.0,
        );
        final rivalArea = areaCalculator.calculatePolygonArea(rivalLoop);
        expect(rivalArea, lessThan(1.0));

        final repo = await repoWithRivals([
          rival(id: 'rival-t', polygons: rivalLoop, areaSqMeters: rivalArea),
        ]);

        final engulfingClaim = rectangleLoop(
          startLat: 40.7125,
          startLng: -74.0062,
          widthMeters: 100,
          heightMeters: 100,
        );
        await repo.captureTerritory(engulfingClaim);

        final territories = await repo.getAllTerritories();
        expect(territories.where((t) => t.userId == 'rival-1'), isEmpty);
      },
    );

    test(
      'partial cut keeps concave rival when bbox overlap equals full area',
      () async {
        // C-shaped rival: modest area but a large bbox. Old bbox math treated
        // overlap as the entire polygon and deleted it outright.
        final rivalLoop = [
          GeoPointEntity(
            latitude: 40.7120,
            longitude: -74.0060,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7120,
            longitude: -74.0050,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7135,
            longitude: -74.0050,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7135,
            longitude: -74.0056,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7125,
            longitude: -74.0056,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7125,
            longitude: -74.0054,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7135,
            longitude: -74.0054,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7135,
            longitude: -74.0060,
            timestamp: epoch,
          ),
        ];
        final rivalArea = areaCalculator.calculatePolygonArea(rivalLoop);
        final repo = await repoWithRivals([
          rival(id: 'rival-t', polygons: rivalLoop, areaSqMeters: rivalArea),
        ]);

        final userLoop = rectangleLoop(
          startLat: 40.7123,
          startLng: -74.0057,
          widthMeters: 55,
          heightMeters: 55,
        );
        await repo.captureTerritory(userLoop);

        final territories = await repo.getAllTerritories();
        expect(territories.any((t) => t.userId == 'rival-1'), isTrue);

        final updatedRival = territories.firstWhere(
          (t) => t.userId == 'rival-1',
        );
        expect(updatedRival.areaSqMeters, greaterThanOrEqualTo(1.0));
        expect(updatedRival.areaSqMeters, lessThan(rivalArea));
      },
    );

    test(
      'split fragments below 1.0 m² are dropped after partial cut',
      () async {
        // Concave C-shape: a partial cut can leave a tiny tip fragment.
        final rivalLoop = [
          GeoPointEntity(
            latitude: 40.7120,
            longitude: -74.0060,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7120,
            longitude: -74.0050,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7128,
            longitude: -74.0050,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7128,
            longitude: -74.0056,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7122,
            longitude: -74.0056,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7122,
            longitude: -74.0054,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7128,
            longitude: -74.0054,
            timestamp: epoch,
          ),
          GeoPointEntity(
            latitude: 40.7128,
            longitude: -74.0060,
            timestamp: epoch,
          ),
        ];
        final rivalArea = areaCalculator.calculatePolygonArea(rivalLoop);
        final repo = await repoWithRivals([
          rival(id: 'rival-t', polygons: rivalLoop, areaSqMeters: rivalArea),
        ]);

        final userLoop = rectangleLoop(
          startLat: 40.71215,
          startLng: -74.00555,
          widthMeters: 35,
          heightMeters: 8,
        );
        await repo.captureTerritory(userLoop);

        final territories = await repo.getAllTerritories();
        final rivalTerritories = territories
            .where((t) => t.userId == 'rival-1')
            .toList();

        for (final fragment in rivalTerritories) {
          for (final ring in fragment.polygons) {
            expect(
              areaCalculator.calculatePolygonArea(ring),
              greaterThanOrEqualTo(1.0),
            );
          }
        }
      },
    );
  });
}
