import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/loop_segment_entity.dart';
import 'package:awaken/features/territory/domain/services/geo_utils.dart';
import 'package:awaken/features/territory/domain/services/loop_segment_extractor.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/territory_widget_test_helpers.dart';

void main() {
  group('LoopSegmentExtractor.extract', () {
    test('S1: rectangle loop with overrun past start yields one segment', () {
      final baseTime = DateTime(2026, 1, 1, 8);
      final path = createDenseRectangleLoopWithOverrun(
        startLat: 40.7128,
        startLng: -74.0060,
        widthMeters: 60,
        heightMeters: 60,
        overrunMeters: 50,
        startTime: baseTime,
      );

      final segments = LoopSegmentExtractor.extract(path);
      expect(segments, hasLength(1));
      expect(segments.first.startIndex, equals(0));
      expect(segments.first.endIndex, lessThan(path.length - 1));
      expect(
        GeoUtils.haversineMeters(path.first, path.last),
        greaterThan(AppConstants.loopClosureRadiusMeters),
      );
    });

    test('S2: classic close at stop yields one segment', () {
      final baseTime = DateTime(2026, 1, 1, 8);
      final path = createDenseRectangleLoop(
        startLat: 40.7128,
        startLng: -74.0060,
        widthMeters: 60,
        heightMeters: 60,
        startTime: baseTime,
      );

      final segments = LoopSegmentExtractor.extract(path);
      expect(segments, hasLength(1));
      expect(
        GeoUtils.haversineMeters(path.first, path.last),
        lessThanOrEqualTo(AppConstants.loopClosureRadiusMeters),
      );
    });

    test('S3: two sequential loops in one path yield two segments', () {
      final baseTime = DateTime(2026, 1, 1, 8);
      final path = _twoLapsAtSameAnchor(
        startLat: 40.7128,
        startLng: -74.0060,
        widthMeters: 60,
        heightMeters: 60,
        startTime: baseTime,
      );

      final segments = LoopSegmentExtractor.extract(path);
      expect(segments, hasLength(2));
    });

    test('C1: micro-loop under segment distance yields zero segments', () {
      final baseTime = DateTime(2026, 1, 1, 8);
      final path = densifyGpsPath([
        GeoPointEntity(
          latitude: 40.7128,
          longitude: -74.0060,
          timestamp: baseTime,
        ),
        GeoPointEntity(
          latitude: 40.7128 + 15 / 111194.9266,
          longitude: -74.0060,
          timestamp: baseTime.add(const Duration(seconds: 10)),
        ),
        GeoPointEntity(
          latitude: 40.7128,
          longitude: -74.0060,
          timestamp: baseTime.add(const Duration(seconds: 20)),
        ),
      ]);

      expect(LoopSegmentExtractor.extract(path), isEmpty);
    });

    test('C3: lingering near start without exit does not double-count', () {
      final baseTime = DateTime(2026, 1, 1, 8);
      final loop = createDenseRectangleLoop(
        startLat: 40.7128,
        startLng: -74.0060,
        widthMeters: 60,
        heightMeters: 60,
        startTime: baseTime,
      );
      // Orbit near start without leaving exit radius.
      final linger = <GeoPointEntity>[
        for (var i = 0; i < 8; i++)
          GeoPointEntity(
            latitude: loop.last.latitude + (i.isEven ? 0.00001 : -0.00001),
            longitude: loop.last.longitude,
            timestamp: loop.last.timestamp.add(Duration(seconds: 10 * (i + 1))),
          ),
      ];
      final path = [...loop, ...linger];

      final segments = LoopSegmentExtractor.extract(path);
      expect(segments, hasLength(1));
    });

    test('C7: caps loops at maxLoopsPerSession', () {
      final baseTime = DateTime(2026, 1, 1, 8);
      var path = <GeoPointEntity>[];
      var time = baseTime;

      for (var n = 0; n < AppConstants.maxLoopsPerSession + 1; n++) {
        final anchor = path.isEmpty
            ? GeoPointEntity(
                latitude: 40.7128,
                longitude: -74.0060,
                timestamp: time,
              )
            : path.first;
        final lap = createDenseRectangleLoop(
          startLat: anchor.latitude,
          startLng: anchor.longitude,
          widthMeters: 60,
          heightMeters: 60,
          startTime: time,
        );
        if (path.isEmpty) {
          path = lap;
        } else {
          final exitSouth = densifyGpsPath([
            path.last,
            _extendSouth(path.last, meters: 40, time: time),
          ]);
          final returnNorth = densifyGpsPath([
            exitSouth.last,
            GeoPointEntity(
              latitude: anchor.latitude,
              longitude: anchor.longitude,
              timestamp: time.add(const Duration(minutes: 1)),
            ),
          ]);
          path = [
            ...path,
            ...exitSouth.skip(1),
            ...returnNorth.skip(1),
            ...lap.skip(1),
          ];
        }
        time = time.add(const Duration(minutes: 5));
      }

      final segments = LoopSegmentExtractor.extract(path);
      expect(segments.length, equals(AppConstants.maxLoopsPerSession));
    });
  });

  group('LoopClosureTracker.evaluate', () {
    test('detects closure incrementally matching batch extract', () {
      final baseTime = DateTime(2026, 1, 1, 8);
      final path = createDenseRectangleLoop(
        startLat: 40.7128,
        startLng: -74.0060,
        widthMeters: 60,
        heightMeters: 60,
        startTime: baseTime,
      );
      final tracker = LoopClosureTracker();
      final incremental = <LoopSegmentEntity>[];

      for (var i = 1; i < path.length; i++) {
        final segment = tracker.evaluate(path.sublist(0, i + 1));
        if (segment != null) incremental.add(segment);
      }

      final batch = LoopSegmentExtractor.extract(path);
      expect(incremental.length, equals(batch.length));
      expect(incremental, isNotEmpty);
    });
  });
}

List<GeoPointEntity> _twoLapsAtSameAnchor({
  required double startLat,
  required double startLng,
  required double widthMeters,
  required double heightMeters,
  required DateTime startTime,
}) {
  final loop1 = createDenseRectangleLoop(
    startLat: startLat,
    startLng: startLng,
    widthMeters: widthMeters,
    heightMeters: heightMeters,
    startTime: startTime,
  );
  final exitSouth = densifyGpsPath([
    loop1.last,
    _extendSouth(
      loop1.last,
      meters: 40,
      time: startTime.add(const Duration(minutes: 5)),
    ),
  ]);
  final returnNorth = densifyGpsPath([
    exitSouth.last,
    GeoPointEntity(
      latitude: startLat,
      longitude: startLng,
      timestamp: startTime.add(const Duration(minutes: 6)),
    ),
  ]);
  final loop2 = createDenseRectangleLoop(
    startLat: startLat,
    startLng: startLng,
    widthMeters: widthMeters,
    heightMeters: heightMeters,
    startTime: startTime.add(const Duration(minutes: 7)),
  );
  return [
    ...loop1,
    ...exitSouth.skip(1),
    ...returnNorth.skip(1),
    ...loop2.skip(1),
  ];
}

GeoPointEntity _extendSouth(
  GeoPointEntity from, {
  required double meters,
  required DateTime time,
}) {
  const metersPerDegreeLat = 111194.9266;
  return GeoPointEntity(
    latitude: from.latitude - meters / metersPerDegreeLat,
    longitude: from.longitude,
    timestamp: time,
  );
}
