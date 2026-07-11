import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/services/geo_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeoUtils.densifyPath', () {
    test('inserts points so consecutive gaps stay under the max', () {
      final start = DateTime.utc(2026, 7, 11);
      // ~222 m north (~0.002 deg lat)
      final points = [
        GeoPointEntity(latitude: 40.0, longitude: -74.0, timestamp: start),
        GeoPointEntity(
          latitude: 40.002,
          longitude: -74.0,
          timestamp: start.add(const Duration(seconds: 30)),
        ),
      ];

      final densified = GeoUtils.densifyPath(points, maxGapMeters: 70);
      expect(densified.length, greaterThan(points.length));

      for (var i = 1; i < densified.length; i++) {
        expect(
          GeoUtils.haversineMeters(densified[i - 1], densified[i]),
          lessThanOrEqualTo(70.01),
        );
      }
    });

    test('leaves already-dense paths unchanged', () {
      final start = DateTime.utc(2026, 7, 11);
      final points = [
        GeoPointEntity(latitude: 40.0, longitude: -74.0, timestamp: start),
        GeoPointEntity(
          latitude: 40.0003,
          longitude: -74.0,
          timestamp: start.add(const Duration(seconds: 5)),
        ),
      ];
      final densified = GeoUtils.densifyPath(points, maxGapMeters: 70);
      expect(densified, hasLength(2));
    });
  });
}
