import 'package:awaken/features/territory/data/datasources/active_run_checkpoint_store.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/loop_segment_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('ActiveRunCheckpoint', () {
    test('round-trips JSON for a tracking session', () {
      final start = DateTime.utc(2026, 7, 11, 12, 0, 0);
      final checkpoint = ActiveRunCheckpoint(
        statusName: 'tracking',
        points: [
          GeoPointEntity(
            latitude: 43.65,
            longitude: -79.38,
            timestamp: start,
          ),
          GeoPointEntity(
            latitude: 43.651,
            longitude: -79.381,
            timestamp: start.add(const Duration(seconds: 30)),
          ),
        ],
        distanceMeters: 120.5,
        elapsed: const Duration(minutes: 4, seconds: 20),
        startTime: start,
        pausedAccumulated: const Duration(seconds: 12),
        sawSustainedOverSpeed: false,
        pendingLoops: [
          LoopSegmentEntity(
            startIndex: 0,
            endIndex: 1,
            closedAt: start.add(const Duration(seconds: 30)),
            points: [
              GeoPointEntity(
                latitude: 43.65,
                longitude: -79.38,
                timestamp: start,
              ),
              GeoPointEntity(
                latitude: 43.651,
                longitude: -79.381,
                timestamp: start.add(const Duration(seconds: 30)),
              ),
            ],
          ),
        ],
        currentSegmentAnchorIndex: 1,
        loopTrackerAnchorIndex: 1,
        loopTrackerMaxDistFromAnchor: 42.0,
        loopTrackerClosureArmed: true,
        gpsAccuracyMeters: 6.5,
      );

      final restored = ActiveRunCheckpoint.fromJson(checkpoint.toJson());

      expect(restored.statusName, 'tracking');
      expect(restored.isResumable, isTrue);
      expect(restored.points, hasLength(2));
      expect(restored.points.last.latitude, 43.651);
      expect(restored.distanceMeters, 120.5);
      expect(restored.elapsed, const Duration(minutes: 4, seconds: 20));
      expect(restored.pausedAccumulated, const Duration(seconds: 12));
      expect(restored.pendingLoops, hasLength(1));
      expect(restored.currentSegmentAnchorIndex, 1);
      expect(restored.loopTrackerClosureArmed, isTrue);
      expect(restored.gpsAccuracyMeters, 6.5);
    });

    test('idle / finished checkpoints are not resumable', () {
      final checkpoint = ActiveRunCheckpoint(
        statusName: 'idle',
        points: const [],
        distanceMeters: 0,
        elapsed: Duration.zero,
        startTime: DateTime.utc(2026, 7, 11),
        pausedAccumulated: Duration.zero,
        sawSustainedOverSpeed: false,
        pendingLoops: const [],
        currentSegmentAnchorIndex: 0,
        loopTrackerAnchorIndex: 0,
        loopTrackerMaxDistFromAnchor: 0,
        loopTrackerClosureArmed: false,
      );
      expect(checkpoint.isResumable, isFalse);
    });
  });

  group('ActiveRunCheckpointStore', () {
    const store = ActiveRunCheckpointStore();

    test('save then load restores a tracking checkpoint', () async {
      final start = DateTime.utc(2026, 7, 11, 8, 0, 0);
      await store.save(
        ActiveRunCheckpoint(
          statusName: 'paused',
          points: [
            GeoPointEntity(
              latitude: 40.71,
              longitude: -74.0,
              timestamp: start,
            ),
          ],
          distanceMeters: 10,
          elapsed: const Duration(minutes: 1),
          startTime: start,
          pausedAccumulated: const Duration(seconds: 5),
          sawSustainedOverSpeed: true,
          pendingLoops: const [],
          currentSegmentAnchorIndex: 0,
          loopTrackerAnchorIndex: 0,
          loopTrackerMaxDistFromAnchor: 0,
          loopTrackerClosureArmed: false,
        ),
      );

      final loaded = await store.load();
      expect(loaded, isNotNull);
      expect(loaded!.statusName, 'paused');
      expect(loaded.points, hasLength(1));
      expect(loaded.sawSustainedOverSpeed, isTrue);
      expect(loaded.pausedAccumulated, const Duration(seconds: 5));
    });

    test('clear removes the checkpoint', () async {
      await store.save(
        ActiveRunCheckpoint(
          statusName: 'tracking',
          points: const [],
          distanceMeters: 0,
          elapsed: Duration.zero,
          startTime: DateTime.utc(2026, 7, 11),
          pausedAccumulated: Duration.zero,
          sawSustainedOverSpeed: false,
          pendingLoops: const [],
          currentSegmentAnchorIndex: 0,
          loopTrackerAnchorIndex: 0,
          loopTrackerMaxDistFromAnchor: 0,
          loopTrackerClosureArmed: false,
        ),
      );
      await store.clear();
      expect(await store.load(), isNull);
    });

    test('saving a non-resumable checkpoint clears storage', () async {
      await store.save(
        ActiveRunCheckpoint(
          statusName: 'tracking',
          points: const [],
          distanceMeters: 0,
          elapsed: Duration.zero,
          startTime: DateTime.utc(2026, 7, 11),
          pausedAccumulated: Duration.zero,
          sawSustainedOverSpeed: false,
          pendingLoops: const [],
          currentSegmentAnchorIndex: 0,
          loopTrackerAnchorIndex: 0,
          loopTrackerMaxDistFromAnchor: 0,
          loopTrackerClosureArmed: false,
        ),
      );
      await store.save(
        ActiveRunCheckpoint(
          statusName: 'finished',
          points: const [],
          distanceMeters: 0,
          elapsed: Duration.zero,
          startTime: DateTime.utc(2026, 7, 11),
          pausedAccumulated: Duration.zero,
          sawSustainedOverSpeed: false,
          pendingLoops: const [],
          currentSegmentAnchorIndex: 0,
          loopTrackerAnchorIndex: 0,
          loopTrackerMaxDistFromAnchor: 0,
          loopTrackerClosureArmed: false,
        ),
      );
      expect(await store.load(), isNull);
    });
  });
}
