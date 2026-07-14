import 'dart:math' as math;

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/run_track_entity.dart';
import 'package:awaken/features/territory/domain/services/geo_utils.dart';
import 'package:awaken/features/territory/domain/services/run_validation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RunValidationService.isSustainedOverSpeed', () {
    test('returns false for fewer than 2 points', () {
      final base = GeoPointEntity(
        latitude: 40.7128,
        longitude: -74.0060,
        timestamp: DateTime.now(),
      );
      expect(RunValidationService.isSustainedOverSpeed([]), isFalse);
      expect(RunValidationService.isSustainedOverSpeed([base]), isFalse);
    });

    test('returns false for slow sustained run', () {
      final points = _pointsAtSpeedKmh(8.0, count: 7);
      expect(RunValidationService.isSustainedOverSpeed(points), isFalse);
    });

    test(
      'returns true when rolling window has 6 consecutive over-speed segments',
      () {
        final points = _pointsAtSpeedKmh(30.0, count: 7);
        expect(RunValidationService.isSustainedOverSpeed(points), isTrue);
      },
    );

    test('returns false at exact boundary speed of 25.0 km/h', () {
      final points = _pointsAtSpeedKmh(24.99, count: 7);
      expect(RunValidationService.isSustainedOverSpeed(points), isFalse);
    });

    test('returns true just above boundary speed of 25.01 km/h', () {
      final points = _pointsAtSpeedKmh(25.01, count: 7);
      expect(RunValidationService.isSustainedOverSpeed(points), isTrue);
    });

    test('returns false with exactly 5 over-speed segments in window', () {
      final base = GeoPointEntity(
        latitude: 40.7128,
        longitude: -74.0060,
        timestamp: DateTime.now(),
      );
      final points = [base];
      points.add(
        _movePointBySpeed(points.last, 10.0, const Duration(seconds: 1)),
      );
      for (var i = 0; i < 4; i++) {
        points.add(
          _movePointBySpeed(points.last, 30.0, const Duration(seconds: 1)),
        );
      }
      expect(points.length, equals(AppConstants.speedRollingWindowSize));
      expect(RunValidationService.isSustainedOverSpeed(points), isFalse);
    });

    test('returns true with exactly 6 over-speed segments in window', () {
      final points = _pointsAtSpeedKmh(
        30.0,
        count: AppConstants.speedRollingWindowSize,
      );
      expect(RunValidationService.isSustainedOverSpeed(points), isTrue);
    });

    test(
      'returns false when a single spike is surrounded by slow segments',
      () {
        final base = GeoPointEntity(
          latitude: 40.7128,
          longitude: -74.0060,
          timestamp: DateTime.now(),
        );
        final points = [base];
        points.add(
          _movePointBySpeed(points.last, 40.0, const Duration(seconds: 1)),
        );
        for (var i = 0; i < 5; i++) {
          points.add(
            _movePointBySpeed(points.last, 8.0, const Duration(seconds: 1)),
          );
        }
        expect(RunValidationService.isSustainedOverSpeed(points), isFalse);
      },
    );

    test(
      'uses only the trailing rolling window when more points are provided',
      () {
        final base = GeoPointEntity(
          latitude: 40.7128,
          longitude: -74.0060,
          timestamp: DateTime.now(),
        );
        final points = [base];
        for (var i = 0; i < 4; i++) {
          points.add(
            _movePointBySpeed(points.last, 8.0, const Duration(seconds: 1)),
          );
        }
        for (var i = 0; i < 5; i++) {
          points.add(
            _movePointBySpeed(points.last, 30.0, const Duration(seconds: 1)),
          );
        }
        expect(points.length, greaterThan(AppConstants.speedRollingWindowSize));
        expect(RunValidationService.isSustainedOverSpeed(points), isTrue);
      },
    );
  });

  group('RunValidationService.isClosedLoop', () {
    test('returns false for fewer than 2 points', () {
      final pt = GeoPointEntity(
        latitude: 40.7128,
        longitude: -74.0060,
        timestamp: DateTime.now(),
      );
      expect(RunValidationService.isClosedLoop([]), isFalse);
      expect(RunValidationService.isClosedLoop([pt]), isFalse);
    });

    test(
      'returns true when start/end distance is within 50.0m closure radius',
      () {
        final pt1 = GeoPointEntity(
          latitude: 40.7128,
          longitude: -74.0060,
          timestamp: DateTime.now(),
        );
        // Slightly under 50m to avoid floating-point edge on the exact bound.
        final pt2 = GeoPointEntity(
          latitude: 40.7128 + 49.9 / 111194.9266,
          longitude: -74.0060,
          timestamp: DateTime.now(),
        );
        expect(
          GeoUtils.haversineMeters(pt1, pt2),
          lessThanOrEqualTo(AppConstants.loopClosureRadiusMeters),
        );
        expect(RunValidationService.isClosedLoop([pt1, pt2]), isTrue);
      },
    );

    test('returns false when start/end distance exceeds 50.0m', () {
      final pt1 = GeoPointEntity(
        latitude: 40.7128,
        longitude: -74.0060,
        timestamp: DateTime.now(),
      );
      final pt2 = GeoPointEntity(
        latitude: 40.7128 + 50.01 / 111194.9266,
        longitude: -74.0060,
        timestamp: DateTime.now(),
      );
      expect(RunValidationService.isClosedLoop([pt1, pt2]), isFalse);
    });

    test('returns true for a closed rectangle loop', () {
      final loop = _createRectangleLoop(
        startLat: 40.7128,
        startLng: -74.0060,
        widthMeters: 60,
        heightMeters: 60,
        startTime: DateTime.now(),
      );
      expect(RunValidationService.isClosedLoop(loop), isTrue);
    });
  });

  group('RunValidationService.classify', () {
    test('returns invalidatedSpeedCap when speed flag is set', () {
      final loop = _createRectangleLoop(
        startLat: 40.7128,
        startLng: -74.0060,
        widthMeters: 60,
        heightMeters: 60,
        startTime: DateTime.now(),
      );
      expect(
        RunValidationService.classify(
          points: loop,
          distanceMeters: 240,
          duration: const Duration(minutes: 2),
          wasInvalidatedBySpeed: true,
        ),
        equals(RunOutcome.invalidatedSpeedCap),
      );
    });

    test('returns invalidatedTooShort when duration is below minimum', () {
      final loop = _createRectangleLoop(
        startLat: 40.7128,
        startLng: -74.0060,
        widthMeters: 60,
        heightMeters: 60,
        startTime: DateTime.now(),
      );
      expect(
        RunValidationService.classify(
          points: loop,
          distanceMeters: 240,
          // Derived from the constant — it differs between debug (45s) and
          // prod (2m) builds, so a hardcoded duration is wrong in one mode.
          duration: AppConstants.minRunDuration - const Duration(seconds: 1),
          wasInvalidatedBySpeed: false,
        ),
        equals(RunOutcome.invalidatedTooShort),
      );
    });

    test('returns invalidatedTooShort when distance is below minimum', () {
      final loop = _createRectangleLoop(
        startLat: 40.7128,
        startLng: -74.0060,
        widthMeters: 60,
        heightMeters: 60,
        startTime: DateTime.now(),
      );
      expect(
        RunValidationService.classify(
          points: loop,
          distanceMeters: 199.9,
          duration: const Duration(minutes: 2),
          wasInvalidatedBySpeed: false,
        ),
        equals(RunOutcome.invalidatedTooShort),
      );
    });

    test('returns loopNotClosed when path does not close near start', () {
      final baseTime = DateTime.now();
      // End ~80m from start — outside loopClosureRadiusMeters (50).
      final openPath = [
        GeoPointEntity(
          latitude: 40.7128,
          longitude: -74.0060,
          timestamp: baseTime,
        ),
        GeoPointEntity(
          latitude: 40.7138,
          longitude: -74.0060,
          timestamp: baseTime.add(const Duration(seconds: 30)),
        ),
        GeoPointEntity(
          latitude: 40.7138,
          longitude: -74.0050,
          timestamp: baseTime.add(const Duration(seconds: 60)),
        ),
        GeoPointEntity(
          latitude: 40.7128 - 80 / 111194.9266,
          longitude: -74.0060,
          timestamp: baseTime.add(const Duration(seconds: 90)),
        ),
      ];
      expect(
        RunValidationService.classify(
          points: openPath,
          distanceMeters: GeoUtils.pathDistanceMeters(openPath),
          duration: const Duration(minutes: 2),
          wasInvalidatedBySpeed: false,
        ),
        equals(RunOutcome.loopNotClosed),
      );
    });

    test(
      'returns territoryClaimed for valid closed loop meeting all thresholds',
      () {
        final baseTime = DateTime.now();
        final loop = _createRectangleLoop(
          startLat: 40.7128,
          startLng: -74.0060,
          widthMeters: 60,
          heightMeters: 60,
          startTime: baseTime,
        );
        expect(
          RunValidationService.classify(
            points: loop,
            distanceMeters: GeoUtils.pathDistanceMeters(loop),
            duration: const Duration(minutes: 2),
            wasInvalidatedBySpeed: false,
          ),
          equals(RunOutcome.territoryClaimed),
        );
      },
    );

    test('accepts exact boundary duration and distance', () {
      final loop = _createRectangleLoop(
        startLat: 40.7128,
        startLng: -74.0060,
        widthMeters: 50,
        heightMeters: 50,
        startTime: DateTime.now(),
      );
      expect(
        RunValidationService.classify(
          points: loop,
          distanceMeters: 200.0,
          duration: const Duration(seconds: 120),
          wasInvalidatedBySpeed: false,
        ),
        equals(RunOutcome.territoryClaimed),
      );
    });
  });
}

List<GeoPointEntity> _pointsAtSpeedKmh(double speedKmh, {required int count}) {
  final base = GeoPointEntity(
    latitude: 40.7128,
    longitude: -74.0060,
    timestamp: DateTime.now(),
  );
  final points = [base];
  for (var i = 1; i < count; i++) {
    points.add(
      _movePointBySpeed(points.last, speedKmh, const Duration(seconds: 1)),
    );
  }
  return points;
}

GeoPointEntity _movePointBySpeed(
  GeoPointEntity from,
  double speedKmh,
  Duration duration,
) {
  final seconds = duration.inMilliseconds / 1000.0;
  final distance = (speedKmh / 3.6) * seconds;
  const metersPerDegreeLat = 111194.9266;
  final dLat = distance / metersPerDegreeLat;
  return GeoPointEntity(
    latitude: from.latitude + dLat,
    longitude: from.longitude,
    timestamp: from.timestamp.add(duration),
  );
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
    GeoPointEntity(
      latitude: startLat,
      longitude: startLng,
      timestamp: startTime,
    ),
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
