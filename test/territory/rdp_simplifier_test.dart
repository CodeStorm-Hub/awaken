import 'dart:math' as math;

import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/services/rdp_simplifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const epsilon = 3.0;
  final baseTime = DateTime.fromMillisecondsSinceEpoch(0);

  group('RdpSimplifier.simplify', () {
    test('returns empty list for empty input', () {
      expect(RdpSimplifier.simplify([], epsilon), isEmpty);
    });

    test('returns single point unchanged', () {
      final pt = GeoPointEntity(
        latitude: 40.7128,
        longitude: -74.0060,
        timestamp: baseTime,
      );
      expect(RdpSimplifier.simplify([pt], epsilon), equals([pt]));
    });

    test('returns two points unchanged', () {
      final pt1 = GeoPointEntity(
        latitude: 40.7128,
        longitude: -74.0060,
        timestamp: baseTime,
      );
      final pt2 = GeoPointEntity(
        latitude: 40.7138,
        longitude: -74.0060,
        timestamp: baseTime.add(const Duration(seconds: 30)),
      );
      expect(RdpSimplifier.simplify([pt1, pt2], epsilon), equals([pt1, pt2]));
    });

    test('collapses collinear path to endpoints only', () {
      final points = [
        GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: baseTime),
        GeoPointEntity(
          latitude: 40.7133,
          longitude: -74.0060,
          timestamp: baseTime.add(const Duration(seconds: 30)),
        ),
        GeoPointEntity(
          latitude: 40.7138,
          longitude: -74.0060,
          timestamp: baseTime.add(const Duration(seconds: 60)),
        ),
        GeoPointEntity(
          latitude: 40.7143,
          longitude: -74.0060,
          timestamp: baseTime.add(const Duration(seconds: 90)),
        ),
      ];
      final simplified = RdpSimplifier.simplify(points, epsilon);
      expect(simplified.length, equals(2));
      expect(simplified.first.latitude, equals(40.7128));
      expect(simplified.last.latitude, equals(40.7143));
    });

    test('flattens zig-zag with deviation under epsilon', () {
      final points = [
        GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: baseTime),
        GeoPointEntity(
          latitude: 40.712800005,
          longitude: -74.006000005,
          timestamp: baseTime.add(const Duration(seconds: 1)),
        ),
        GeoPointEntity(
          latitude: 40.7128,
          longitude: -74.00600001,
          timestamp: baseTime.add(const Duration(seconds: 2)),
        ),
      ];
      expect(RdpSimplifier.simplify(points, epsilon).length, equals(2));
    });

    test('retains zig-zag vertices when deviation exceeds epsilon', () {
      final points = [
        GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: baseTime),
        GeoPointEntity(
          latitude: 40.7132,
          longitude: -74.0060,
          timestamp: baseTime.add(const Duration(seconds: 1)),
        ),
        GeoPointEntity(
          latitude: 40.7128,
          longitude: -74.0060001,
          timestamp: baseTime.add(const Duration(seconds: 2)),
        ),
      ];
      expect(RdpSimplifier.simplify(points, epsilon).length, equals(3));
    });

    test('epsilon boundary: 2.99m deviation simplified, 3.01m deviation kept', () {
      final ptStart = GeoPointEntity(
        latitude: 40.7128,
        longitude: -74.0060,
        timestamp: baseTime,
      );
      final ptEnd = GeoPointEntity(
        latitude: 40.7128,
        longitude: -74.0080,
        timestamp: baseTime.add(const Duration(seconds: 60)),
      );
      final ptMidUnder = GeoPointEntity(
        latitude: 40.7128 + 0.0000268,
        longitude: -74.0070,
        timestamp: baseTime.add(const Duration(seconds: 30)),
      );
      final ptMidOver = GeoPointEntity(
        latitude: 40.7128 + 0.0000271,
        longitude: -74.0070,
        timestamp: baseTime.add(const Duration(seconds: 30)),
      );

      expect(
        RdpSimplifier.simplify([ptStart, ptMidUnder, ptEnd], epsilon).length,
        equals(2),
      );
      expect(
        RdpSimplifier.simplify([ptStart, ptMidOver, ptEnd], epsilon).length,
        equals(3),
      );
    });

    test('preserves start and end vertices on closed loop', () {
      final loop = _createRectangleLoop(
        startLat: 40.7128,
        startLng: -74.0060,
        widthMeters: 60,
        heightMeters: 60,
        startTime: baseTime,
      );
      final simplified = RdpSimplifier.simplify(loop, epsilon);
      expect(simplified.first.latitude, equals(loop.first.latitude));
      expect(simplified.last.latitude, equals(loop.last.latitude));
    });

    test('retains shape for circular path while reducing vertex count', () {
      final points = <GeoPointEntity>[];
      for (var i = 0; i < 16; i++) {
        final angle = (i * 2 * math.pi) / 16;
        points.add(GeoPointEntity(
          latitude: 40.7128 + 0.00018 * math.sin(angle),
          longitude: -74.0060 + 0.00018 * math.cos(angle),
          timestamp: baseTime.add(Duration(seconds: i)),
        ));
      }
      final simplified = RdpSimplifier.simplify(points, epsilon);
      expect(simplified.length, greaterThan(3));
      expect(simplified.length, lessThan(16));
    });
  });
}

List<GeoPointEntity> _createRectangleLoop({
  required double startLat,
  required double startLng,
  required double widthMeters,
  required double heightMeters,
  required DateTime startTime,
  Duration interval = const Duration(seconds: 30),
}) {
  final refLatRad = startLat * math.pi / 180.0;
  const metersPerDegreeLat = 111194.9266;
  final metersPerDegreeLon = 111194.9266 * math.cos(refLatRad);

  final dLat = heightMeters / metersPerDegreeLat;
  final dLon = widthMeters / metersPerDegreeLon;

  return [
    GeoPointEntity(latitude: startLat, longitude: startLng, timestamp: startTime),
    GeoPointEntity(
      latitude: startLat + dLat,
      longitude: startLng,
      timestamp: startTime.add(interval),
    ),
    GeoPointEntity(
      latitude: startLat + dLat,
      longitude: startLng + dLon,
      timestamp: startTime.add(interval * 2),
    ),
    GeoPointEntity(
      latitude: startLat,
      longitude: startLng + dLon,
      timestamp: startTime.add(interval * 3),
    ),
    GeoPointEntity(
      latitude: startLat,
      longitude: startLng,
      timestamp: startTime.add(interval * 4),
    ),
  ];
}
