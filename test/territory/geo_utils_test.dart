import 'dart:math' as math;

import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/services/geo_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);

  GeoPointEntity point({
    required double lat,
    required double lng,
    DateTime? time,
  }) {
    return GeoPointEntity(
      latitude: lat,
      longitude: lng,
      timestamp: time ?? epoch,
    );
  }

  group('GeoUtils.haversineMeters', () {
    test('returns zero for identical points', () {
      final a = point(lat: 40.7128, lng: -74.0060);
      expect(GeoUtils.haversineMeters(a, a), equals(0.0));
    });

    test('computes north-south distance approximately correctly', () {
      final a = point(lat: 40.7128, lng: -74.0060);
      final b = point(lat: 40.7128 + 0.001, lng: -74.0060);
      final distance = GeoUtils.haversineMeters(a, b);
      expect(distance, closeTo(111.0, 2.0));
    });

    test('is symmetric', () {
      final a = point(lat: 40.7128, lng: -74.0060);
      final b = point(lat: 40.7138, lng: -74.0050);
      expect(
        GeoUtils.haversineMeters(a, b),
        closeTo(GeoUtils.haversineMeters(b, a), 0.001),
      );
    });
  });

  group('GeoUtils.pathDistanceMeters', () {
    test('returns zero for empty or single-point paths', () {
      final pt = point(lat: 40.7128, lng: -74.0060);
      expect(GeoUtils.pathDistanceMeters([]), equals(0.0));
      expect(GeoUtils.pathDistanceMeters([pt]), equals(0.0));
    });

    test('sums segment distances along a polyline', () {
      final pts = [
        point(lat: 40.7128, lng: -74.0060, time: epoch),
        point(lat: 40.7138, lng: -74.0060, time: epoch.add(const Duration(seconds: 1))),
        point(lat: 40.7138, lng: -74.0050, time: epoch.add(const Duration(seconds: 2))),
      ];
      final expected =
          GeoUtils.haversineMeters(pts[0], pts[1]) + GeoUtils.haversineMeters(pts[1], pts[2]);
      expect(GeoUtils.pathDistanceMeters(pts), closeTo(expected, 0.001));
    });

    test('returns zero for stationary path with multiple timestamps', () {
      final pts = [
        point(lat: 40.7128, lng: -74.0060, time: epoch),
        point(lat: 40.7128, lng: -74.0060, time: epoch.add(const Duration(seconds: 5))),
      ];
      expect(GeoUtils.pathDistanceMeters(pts), equals(0.0));
    });
  });

  group('GeoUtils.speedKmh', () {
    test('returns zero when timestamps are equal', () {
      final a = point(lat: 40.7128, lng: -74.0060, time: epoch);
      final b = point(lat: 40.7138, lng: -74.0060, time: epoch);
      expect(GeoUtils.speedKmh(a, b), equals(0.0));
    });

    test('computes speed from distance and elapsed time', () {
      final a = point(lat: 40.7128, lng: -74.0060, time: epoch);
      final b = point(
        lat: 40.7128 + 10 / 111194.9266,
        lng: -74.0060,
        time: epoch.add(const Duration(seconds: 1)),
      );
      expect(GeoUtils.speedKmh(a, b), closeTo(36.0, 1.0));
    });
  });

  group('GeoUtils.isPointInPolygon', () {
    late List<GeoPointEntity> square;

    setUp(() {
      square = _createRectangleLoop(
        startLat: 40.7128,
        startLng: -74.0060,
        widthMeters: 100,
        heightMeters: 100,
        startTime: epoch,
      );
    });

    test('returns true for point inside polygon', () {
      final inside = point(lat: 40.7128 + 0.0002, lng: -74.0060 + 0.0002);
      expect(GeoUtils.isPointInPolygon(inside, square), isTrue);
    });

    test('returns false for point outside polygon', () {
      final outside = point(lat: 40.7200, lng: -74.0060);
      expect(GeoUtils.isPointInPolygon(outside, square), isFalse);
    });

    test('returns false for empty ring', () {
      final inside = point(lat: 40.7128, lng: -74.0060);
      expect(GeoUtils.isPointInPolygon(inside, []), isFalse);
    });

    test('handles triangle ring without duplicated closing vertex', () {
      final triangle = [
        point(lat: 0.0, lng: 0.0),
        point(lat: 0.0, lng: 1.0),
        point(lat: 1.0, lng: 0.0),
      ];
      expect(GeoUtils.isPointInPolygon(point(lat: 0.1, lng: 0.1), triangle), isTrue);
      expect(GeoUtils.isPointInPolygon(point(lat: 0.9, lng: 0.9), triangle), isFalse);
    });
  });
}

List<GeoPointEntity> _createRectangleLoop({
  required double startLat,
  required double startLng,
  required double widthMeters,
  required double heightMeters,
  required DateTime startTime,
}) {
  final refLatRad = startLat * math.pi / 180.0;
  const metersPerDegreeLat = 111194.9266;
  final metersPerDegreeLon = 111194.9266 * math.cos(refLatRad);

  final dLat = heightMeters / metersPerDegreeLat;
  final dLon = widthMeters / metersPerDegreeLon;

  return [
    GeoPointEntity(latitude: startLat, longitude: startLng, timestamp: startTime),
    GeoPointEntity(latitude: startLat + dLat, longitude: startLng, timestamp: startTime),
    GeoPointEntity(
      latitude: startLat + dLat,
      longitude: startLng + dLon,
      timestamp: startTime,
    ),
    GeoPointEntity(latitude: startLat, longitude: startLng + dLon, timestamp: startTime),
  ];
}
