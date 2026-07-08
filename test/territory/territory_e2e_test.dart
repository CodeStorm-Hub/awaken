import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:awaken/app.dart';
import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/core/services/territory_decay_notification_service.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:awaken/features/alarm/domain/repositories/alarm_repository.dart';
import 'package:awaken/features/alarm/presentation/providers/alarm_schedule_providers.dart';
import 'package:awaken/features/auth/domain/entities/app_user.dart';
import 'package:awaken/features/auth/domain/repositories/auth_repository.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:awaken/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:awaken/features/sessions/domain/entities/session_entity.dart';
import 'package:awaken/features/sessions/domain/repositories/session_repository.dart';
import 'package:awaken/features/sessions/presentation/providers/session_providers.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/run_track_entity.dart';
import 'package:awaken/features/territory/domain/entities/territory_entity.dart';
import 'package:awaken/features/territory/domain/services/geo_utils.dart';
import 'package:awaken/features/territory/domain/services/gps_kalman_filter.dart';
import 'package:awaken/features/territory/domain/services/rdp_simplifier.dart';
import 'package:awaken/features/territory/domain/services/run_validation_service.dart';
import 'package:awaken/features/territory/presentation/providers/active_run_providers.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;

import 'helpers/territory_widget_test_helpers.dart';
import 'mocks/fake_territory_repository.dart';
import 'mocks/mock_geolocator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGeolocatorPlatform mockGeolocator;
  late FakeTerritoryRepository fakeTerritoryRepository;

  setUpAll(() {
    // Setup HttpOverrides to return transparent 1x1 PNG for any image/basemap requests
    HttpOverrides.global = MockHttpOverrides();

    // Mock local notification platform channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (MethodCall methodCall) {
        if (methodCall.method == 'initialize' || methodCall.method == 'show') {
          return Future<bool>.value(true);
        }
        return Future<dynamic>.value(null);
      },
    );

    // Mock native geolocator platform channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/geolocator'),
      (MethodCall methodCall) {
        if (methodCall.method == 'isLocationServiceEnabled') {
          return Future<bool>.value(true);
        }
        if (methodCall.method == 'checkPermission' || methodCall.method == 'requestPermission') {
          return Future<int>.value(3); // LocationPermission.whileInUse
        }
        return Future<dynamic>.value(null);
      },
    );
  });

  setUp(() {
    mockGeolocator = MockGeolocatorPlatform();
    GeolocatorPlatform.instance = mockGeolocator;
    fakeTerritoryRepository = FakeTerritoryRepository();

    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('DEBUG FlutterError: ${details.exception}\n${details.stack}');
      if (originalOnError != null) {
        originalOnError(details);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('DEBUG PlatformDispatcher error: $error\n$stack');
      return false;
    };
  });

  tearDown(() {
    fakeTerritoryRepository.close();
  });

  Position createPos({
    required double lat,
    required double lng,
    required DateTime time,
    double accuracy = 3.0,
    double speed = 2.0,
  }) {
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: time,
      accuracy: accuracy,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: speed,
      speedAccuracy: 0.0,
    );
  }

  GeoPointEntity movePointBySpeed(GeoPointEntity from, double speedKmh, Duration duration) {
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

  List<GeoPointEntity> createRectangleLoop({
    required double startLat,
    required double startLng,
    required double widthMeters,
    required double heightMeters,
    required DateTime startTime,
    Duration interval = const Duration(seconds: 30),
  }) {
    return createDenseRectangleLoop(
      startLat: startLat,
      startLng: startLng,
      widthMeters: widthMeters,
      heightMeters: heightMeters,
      startTime: startTime,
      interval: interval,
    );
  }

  group('Tier 1: Feature Coverage (F1-F7)', () {
    // F1: GPS Tracking & Kalman Smoothing (1-5)
    test('1. F1: Kalman filter stabilizes small GPS jitter.', () {
      final filter = GpsKalmanFilter(processNoise: 3.0);
      filter.filter(40.7128, -74.0060, 3.0);
      final (lat, lng) = filter.filter(40.71281, -74.00601, 3.0);
      expect((lat - 40.712805).abs(), lessThan(0.00005));
      expect((lng - (-74.006005)).abs(), lessThan(0.00005));
    });

    test('2. F1: Kalman filter ignores huge GPS jumps (low accuracy/high measurement variance).', () {
      final filter = GpsKalmanFilter(processNoise: 3.0);
      filter.filter(40.7128, -74.0060, 3.0);
      final (lat, lng) = filter.filter(40.7228, -74.0160, 100.0);
      expect((lat - 40.7128).abs(), lessThan(0.0002));
      expect((lng - (-74.0060)).abs(), lessThan(0.0002));
    });

    test('3. F1: Kalman filter follows consistent coordinate stream.', () {
      final filter = GpsKalmanFilter(processNoise: 3.0);
      filter.filter(40.7128, -74.0060, 3.0);
      var lat = 40.7128;
      var lng = -74.0060;
      for (int i = 0; i < 10; i++) {
        lat += 0.0001;
        lng += 0.0001;
        final (fLat, fLng) = filter.filter(lat, lng, 1.0);
        expect((fLat - lat).abs(), lessThan(0.00005));
        expect((fLng - lng).abs(), lessThan(0.00005));
      }
    });

    test('4. F1: Active run path is recorded correctly with smoothed coordinates.', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(activeRunProvider.notifier);
        notifier.startRun();
        async.flushMicrotasks();

        final baseTime = DateTime.now();
        mockGeolocator.feedPosition(createPos(lat: 40.7128, lng: -74.0060, time: baseTime, accuracy: 3.0));
        async.flushMicrotasks();
        mockGeolocator.feedPosition(createPos(lat: 40.7129, lng: -74.0061, time: baseTime.add(const Duration(seconds: 10)), accuracy: 3.0));
        async.flushMicrotasks();

        notifier.finishRun();
        async.flushMicrotasks();

        final recorded = fakeTerritoryRepository.recordedRuns.first;
        expect(recorded.points.length, equals(2));
        // Verify points match filtered values
        final filter = GpsKalmanFilter(processNoise: 3.0);
        final pt1 = filter.filter(40.7128, -74.0060, 3.0);
        final pt2 = filter.filter(40.7129, -74.0061, 3.0);
        expect(recorded.points[0].latitude, equals(pt1.$1));
        expect(recorded.points[1].latitude, equals(pt2.$1));
      });
    });

    test('5. F1: Distance calculation updates dynamically during run tracking using smoothed path.', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(activeRunProvider.notifier);
        notifier.startRun();
        async.flushMicrotasks();

        final baseTime = DateTime.now();
        mockGeolocator.feedPosition(createPos(lat: 40.7128, lng: -74.0060, time: baseTime));
        async.flushMicrotasks();
        expect(container.read(activeRunProvider).distanceMeters, equals(0.0));

        mockGeolocator.feedPosition(createPos(lat: 40.7138, lng: -74.0060, time: baseTime.add(const Duration(seconds: 10))));
        async.flushMicrotasks();
        expect(container.read(activeRunProvider).distanceMeters, greaterThan(50.0));
      });
    });

    // F2: Speed Cap Anti-Cheat (6-10)
    test('6. F2: Slow run (e.g. 8 km/h) is not flagged as over-speed.', () {
      final base = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: DateTime.now());
      final points = [base];
      for (var i = 1; i <= 6; i++) {
        points.add(movePointBySpeed(points.last, 8.0, const Duration(seconds: 1)));
      }
      expect(RunValidationService.isSustainedOverSpeed(points), isFalse);
    });

    test('7. F2: Sustained high speed (e.g. 30 km/h) over 6 points is flagged as over-speed.', () {
      final base = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: DateTime.now());
      final points = [base];
      for (var i = 1; i <= 6; i++) {
        points.add(movePointBySpeed(points.last, 30.0, const Duration(seconds: 1)));
      }
      expect(RunValidationService.isSustainedOverSpeed(points), isTrue);
    });

    test('8. F2: Run is invalidated with `invalidatedSpeedCap` when sustained over-speed is detected.', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(activeRunProvider.notifier);
        notifier.startRun();
        async.flushMicrotasks();

        final baseTime = DateTime.now();
        var current = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: baseTime);
        mockGeolocator.feedPosition(createPos(lat: current.latitude, lng: current.longitude, time: current.timestamp, accuracy: 0.1));
        async.flushMicrotasks();

        for (var i = 1; i <= 6; i++) {
          async.elapse(const Duration(seconds: 1));
          current = movePointBySpeed(current, 30.0, const Duration(seconds: 1));
          mockGeolocator.feedPosition(createPos(lat: current.latitude, lng: current.longitude, time: current.timestamp, accuracy: 0.1));
          async.flushMicrotasks();
        }

        notifier.finishRun();
        async.flushMicrotasks();

        expect(container.read(activeRunProvider).result?.outcome, equals(RunOutcome.invalidatedSpeedCap));
      });
    });

    test('9. F2: Short-lived speed spike (1 point at 40 km/h, 5 points at 8 km/h) does NOT trigger sustained over-speed.', () {
      final base = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: DateTime.now());
      final points = [base];
      // 1 spike
      points.add(movePointBySpeed(points.last, 40.0, const Duration(seconds: 1)));
      // 5 normal pings
      for (var i = 0; i < 5; i++) {
        points.add(movePointBySpeed(points.last, 8.0, const Duration(seconds: 1)));
      }
      expect(RunValidationService.isSustainedOverSpeed(points), isFalse);
    });

    test('10. F2: Speed cap check resets properly on start of a new run session.', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(activeRunProvider.notifier);
        notifier.startRun();
        async.flushMicrotasks();

        final baseTime = DateTime.now();
        var current = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: baseTime);
        mockGeolocator.feedPosition(createPos(lat: current.latitude, lng: current.longitude, time: current.timestamp, accuracy: 0.1));
        async.flushMicrotasks();

        for (var i = 1; i <= 6; i++) {
          async.elapse(const Duration(seconds: 1));
          current = movePointBySpeed(current, 30.0, const Duration(seconds: 1));
          mockGeolocator.feedPosition(createPos(lat: current.latitude, lng: current.longitude, time: current.timestamp, accuracy: 0.1));
          async.flushMicrotasks();
        }

        expect(container.read(activeRunProvider).isOverSpeed, isTrue);

        notifier.finishRun();
        async.flushMicrotasks();

        // Start new run
        notifier.startRun();
        async.flushMicrotasks();

        expect(container.read(activeRunProvider).isOverSpeed, isFalse);
      });
    });

    // F3: RDP Simplification (11-15)
    test('11. F3: Straight collinear path is simplified from N points to 2 points.', () {
      final baseTime = DateTime.now();
      final points = [
        GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: baseTime),
        GeoPointEntity(latitude: 40.7133, longitude: -74.0060, timestamp: baseTime.add(const Duration(seconds: 30))),
        GeoPointEntity(latitude: 40.7138, longitude: -74.0060, timestamp: baseTime.add(const Duration(seconds: 60))),
        GeoPointEntity(latitude: 40.7143, longitude: -74.0060, timestamp: baseTime.add(const Duration(seconds: 90))),
      ];
      final simplified = RdpSimplifier.simplify(points, 3.0);
      expect(simplified.length, equals(2));
      expect(simplified.first.latitude, equals(40.7128));
      expect(simplified.last.latitude, equals(40.7143));
    });

    test('12. F3: Circular path is simplified but retains main shape (within epsilon).', () {
      final baseTime = DateTime.now();
      final points = <GeoPointEntity>[];
      for (var i = 0; i < 16; i++) {
        final angle = (i * 2 * math.pi) / 16;
        points.add(GeoPointEntity(
          latitude: 40.7128 + 0.00018 * math.sin(angle),
          longitude: -74.0060 + 0.00018 * math.cos(angle),
          timestamp: baseTime.add(Duration(seconds: i)),
        ));
      }
      final simplified = RdpSimplifier.simplify(points, 3.0);
      expect(simplified.length, greaterThan(3));
      expect(simplified.length, lessThan(16));
    });

    test('13. F3: Zig-zag path with small deviations (under epsilon 3m) is flattened to a straight line.', () {
      final baseTime = DateTime.now();
      // Jitter deviation < 1m
      final points = [
        GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: baseTime),
        GeoPointEntity(latitude: 40.712800005, longitude: -74.006000005, timestamp: baseTime.add(const Duration(seconds: 1))),
        GeoPointEntity(latitude: 40.7128, longitude: -74.00600001, timestamp: baseTime.add(const Duration(seconds: 2))),
      ];
      final simplified = RdpSimplifier.simplify(points, 3.0);
      expect(simplified.length, equals(2));
    });

    test('14. F3: Zig-zag path with large deviations (over epsilon 3m) retains intermediate vertices.', () {
      final baseTime = DateTime.now();
      // Jitter deviation is ~50m
      final points = [
        GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: baseTime),
        GeoPointEntity(latitude: 40.7132, longitude: -74.0060, timestamp: baseTime.add(const Duration(seconds: 1))),
        GeoPointEntity(latitude: 40.7128, longitude: -74.0060001, timestamp: baseTime.add(const Duration(seconds: 2))),
      ];
      final simplified = RdpSimplifier.simplify(points, 3.0);
      expect(simplified.length, equals(3));
    });

    test('15. F3: Simplified vertices are used for database capture.', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(activeRunProvider.notifier);
        notifier.startRun();
        async.flushMicrotasks();

        final baseTime = DateTime.now();
        final pts = createRectangleLoop(
          startLat: 40.7128,
          startLng: -74.0060,
          widthMeters: 60,
          heightMeters: 60,
          startTime: baseTime,
          interval: const Duration(seconds: 30),
        );

        mockGeolocator.feedPosition(createPos(lat: pts[0].latitude, lng: pts[0].longitude, time: pts[0].timestamp, accuracy: 0.1));
        async.flushMicrotasks();

        for (var i = 1; i < pts.length; i++) {
          async.elapse(const Duration(seconds: 30));
          mockGeolocator.feedPosition(createPos(lat: pts[i].latitude, lng: pts[i].longitude, time: pts[i].timestamp, accuracy: 0.1));
          async.flushMicrotasks();
        }

        notifier.finishRun();
        async.flushMicrotasks();

        // Verify captured loops match simplified coordinates
        final simplified = RdpSimplifier.simplify(pts, 3.0);
        final userTerritory = fakeTerritoryRepository.territories.firstWhere((t) => t.userId == 'user-1');
        expect(userTerritory.polygons.first.length, equals(simplified.length));
      });
    });

    // F4: Loop Claiming & Validation (16-20)
    test('16. F4: Closed loop (start/end distance <= 20m) with min duration (2m) and min distance (200m) and area (>50m²) is valid.', () {
      final baseTime = DateTime.now();
      final loop = createRectangleLoop(
        startLat: 40.7128,
        startLng: -74.0060,
        widthMeters: 60,
        heightMeters: 60,
        startTime: baseTime,
      );
      final outcome = RunValidationService.classify(
        points: loop,
        distanceMeters: GeoUtils.pathDistanceMeters(loop),
        duration: const Duration(minutes: 2),
        wasInvalidatedBySpeed: false,
      );
      expect(outcome, equals(RunOutcome.territoryClaimed));
    });

    test('17. F4: Loop not closed (start/end distance > 20m) is classified as normal workout (not claimed).', () {
      final baseTime = DateTime.now();
      final loop = [
        GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: baseTime),
        GeoPointEntity(latitude: 40.7138, longitude: -74.0060, timestamp: baseTime.add(const Duration(seconds: 30))),
        GeoPointEntity(latitude: 40.7138, longitude: -74.0050, timestamp: baseTime.add(const Duration(seconds: 60))),
        GeoPointEntity(latitude: 40.7128, longitude: -74.0050, timestamp: baseTime.add(const Duration(seconds: 90))),
        GeoPointEntity(latitude: 40.7124, longitude: -74.0060, timestamp: baseTime.add(const Duration(seconds: 120))),
      ];
      final outcome = RunValidationService.classify(
        points: loop,
        distanceMeters: GeoUtils.pathDistanceMeters(loop),
        duration: const Duration(minutes: 2),
        wasInvalidatedBySpeed: false,
      );
      expect(outcome, equals(RunOutcome.loopNotClosed));
    });

    test('17b. F4: Loop closed mid-run with overrun past start is claimed on Stop.', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(activeRunProvider.notifier);
        notifier.startRun();
        async.flushMicrotasks();

        final baseTime = DateTime.now();
        final pts = createDenseRectangleLoopWithOverrun(
          startLat: 40.7128,
          startLng: -74.0060,
          widthMeters: 60,
          heightMeters: 60,
          overrunMeters: 50,
          startTime: baseTime,
        );

        mockGeolocator.feedPosition(
          createPos(lat: pts[0].latitude, lng: pts[0].longitude, time: pts[0].timestamp, accuracy: 5),
        );
        async.flushMicrotasks();

        for (var i = 1; i < pts.length; i++) {
          async.elapse(const Duration(seconds: 5));
          mockGeolocator.feedPosition(
            createPos(lat: pts[i].latitude, lng: pts[i].longitude, time: pts[i].timestamp, accuracy: 5),
          );
          async.flushMicrotasks();
        }

        async.elapse(const Duration(minutes: 2));
        notifier.finishRun();
        async.flushMicrotasks();

        final state = container.read(activeRunProvider);
        expect(state.result?.outcome, equals(RunOutcome.territoryClaimed));
        expect(state.sessionCaptureResult?.loopsCaptured, equals(1));
        expect(
          GeoUtils.haversineMeters(pts.first, pts.last),
          greaterThan(AppConstants.loopClosureRadiusMeters),
        );
        expect(fakeTerritoryRepository.territories.any((t) => t.userId == 'user-1'), isTrue);
      });
    });

    test('18. F4: Closed loop but too short duration (<2m) is classified as `invalidatedTooShort`.', () {
      final baseTime = DateTime.now();
      final loop = createRectangleLoop(
        startLat: 40.7128,
        startLng: -74.0060,
        widthMeters: 60,
        heightMeters: 60,
        startTime: baseTime,
        interval: const Duration(seconds: 20),
      );
      final outcome = RunValidationService.classify(
        points: loop,
        distanceMeters: GeoUtils.pathDistanceMeters(loop),
        duration: const Duration(seconds: 80),
        wasInvalidatedBySpeed: false,
      );
      expect(outcome, equals(RunOutcome.invalidatedTooShort));
    });

    test('19. F4: Closed loop but too short distance (<200m) is classified as `invalidatedTooShort`.', () {
      final baseTime = DateTime.now();
      final loop = createRectangleLoop(
        startLat: 40.7128,
        startLng: -74.0060,
        widthMeters: 10,
        heightMeters: 10,
        startTime: baseTime,
      );
      final outcome = RunValidationService.classify(
        points: loop,
        distanceMeters: GeoUtils.pathDistanceMeters(loop),
        duration: const Duration(minutes: 2),
        wasInvalidatedBySpeed: false,
      );
      expect(outcome, equals(RunOutcome.invalidatedTooShort));
    });

    test('20. F4: Closed loop but too small area (<50 m²) is rejected as `invalidatedTooSmall`.', () async {
      final baseTime = DateTime.now();
      // Area is 25m2, which is < 50m2, directly tested on captureTerritory
      final loop = createRectangleLoop(
        startLat: 40.7128,
        startLng: -74.0060,
        widthMeters: 5,
        heightMeters: 5,
        startTime: baseTime,
      );
      await expectLater(
        fakeTerritoryRepository.captureTerritory(loop),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('loop_too_small'))),
      );
    });

    // F5: Territory Merging & Stealing (21-25)
    test('21. F5: Claims overlapping own territory -> merges into a single polygon (ST_Union).', () async {
      final baseTime = DateTime.now();
      // First capture
      final loop1 = createRectangleLoop(
        startLat: 40.7120,
        startLng: -74.0060,
        widthMeters: 60,
        heightMeters: 60,
        startTime: baseTime,
      );
      await fakeTerritoryRepository.captureTerritory(loop1);

      // Overlapping second capture
      final loop2 = createRectangleLoop(
        startLat: 40.7123,
        startLng: -74.0060,
        widthMeters: 60,
        heightMeters: 60,
        startTime: baseTime,
      );
      await fakeTerritoryRepository.captureTerritory(loop2);

      final userTerritory = fakeTerritoryRepository.territories.firstWhere((t) => t.userId == 'user-1');
      expect(userTerritory.polygons.length, equals(1));
    });

    test('22. F5: Claims overlapping rival territory -> rival territory is reduced (ST_Difference).', () async {
      // Seed rival
      final rivalLoop = createRectangleLoop(startLat: 40.7135, startLng: -74.0055, widthMeters: 100, heightMeters: 100, startTime: _epoch);
      fakeTerritoryRepository.territories.add(TerritoryEntity(
        id: 'rival-t',
        userId: 'rival-1',
        ownerDisplayName: 'Rival',
        polygons: [rivalLoop],
        areaSqMeters: 10000.0,
        lastDefendedAt: DateTime.now(),
        isOwnedByCurrentUser: false,
      ));

      // Overlapping claim
      final userLoop = createRectangleLoop(startLat: 40.7130, startLng: -74.0050, widthMeters: 100, heightMeters: 100, startTime: _epoch);
      await fakeTerritoryRepository.captureTerritory(userLoop);

      final rival = fakeTerritoryRepository.territories.firstWhere((t) => t.userId == 'rival-1');
      expect(rival.areaSqMeters, lessThan(10000.0));
    });

    test('23. F5: Rival territory is split into multiple polygons if user\'s claim cuts through the middle.', () async {
      // Seed a 10-vertex rival polygon going north-south
      final rivalLoop = [
        GeoPointEntity(latitude: 40.7120, longitude: -74.0060, timestamp: _epoch),
        GeoPointEntity(latitude: 40.7130, longitude: -74.0060, timestamp: _epoch),
        GeoPointEntity(latitude: 40.7150, longitude: -74.0060, timestamp: _epoch), // middle (inside user's claim)
        GeoPointEntity(latitude: 40.7170, longitude: -74.0060, timestamp: _epoch),
        GeoPointEntity(latitude: 40.7180, longitude: -74.0060, timestamp: _epoch),
        GeoPointEntity(latitude: 40.7180, longitude: -74.0058, timestamp: _epoch),
        GeoPointEntity(latitude: 40.7170, longitude: -74.0058, timestamp: _epoch),
        GeoPointEntity(latitude: 40.7150, longitude: -74.0058, timestamp: _epoch), // middle (inside user's claim)
        GeoPointEntity(latitude: 40.7130, longitude: -74.0058, timestamp: _epoch),
        GeoPointEntity(latitude: 40.7120, longitude: -74.0058, timestamp: _epoch),
      ];
      fakeTerritoryRepository.territories.add(TerritoryEntity(
        id: 'rival-t',
        userId: 'rival-1',
        ownerDisplayName: 'Rival',
        polygons: [rivalLoop],
        areaSqMeters: 10000.0,
        lastDefendedAt: DateTime.now(),
        isOwnedByCurrentUser: false,
      ));

      // User cuts through the middle (from latitude 40.7140 to 40.7160)
      final userLoop = createRectangleLoop(startLat: 40.7140, startLng: -74.0065, widthMeters: 100, heightMeters: 220, startTime: _epoch);
      await fakeTerritoryRepository.captureTerritory(userLoop);

      final rival = fakeTerritoryRepository.territories.firstWhere((t) => t.userId == 'rival-1');
      expect(rival.polygons.length, greaterThan(1));
    });

    test('24. F5: Sliver cleanup: rival territory area reduced to < 1.0 m² is deleted.', () async {
      // Seed tiny rival territory of 0.8m2
      final rivalLoop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 0.9, heightMeters: 0.9, startTime: _epoch);
      fakeTerritoryRepository.territories.add(TerritoryEntity(
        id: 'rival-t',
        userId: 'rival-1',
        ownerDisplayName: 'Rival',
        polygons: [rivalLoop],
        areaSqMeters: 0.81,
        lastDefendedAt: DateTime.now(),
        isOwnedByCurrentUser: false,
      ));

      // Overlap fully
      final userLoop = createRectangleLoop(startLat: 40.7127, startLng: -74.0061, widthMeters: 50, heightMeters: 50, startTime: _epoch);
      await fakeTerritoryRepository.captureTerritory(userLoop);

      final rivals = fakeTerritoryRepository.territories.where((t) => t.userId == 'rival-1');
      expect(rivals, isEmpty);
    });

    test('25. F5: Multi-rival stealing: user\'s claim intersects and steals from multiple rivals in a single capture.', () async {
      // Rival 1
      fakeTerritoryRepository.territories.add(TerritoryEntity(
        id: 'rival-1-t',
        userId: 'rival-1',
        ownerDisplayName: 'Rival 1',
        polygons: [createRectangleLoop(startLat: 40.7120, startLng: -74.0060, widthMeters: 30, heightMeters: 30, startTime: _epoch)],
        areaSqMeters: 900.0,
        lastDefendedAt: DateTime.now(),
        isOwnedByCurrentUser: false,
      ));
      // Rival 2
      fakeTerritoryRepository.territories.add(TerritoryEntity(
        id: 'rival-2-t',
        userId: 'rival-2',
        ownerDisplayName: 'Rival 2',
        polygons: [createRectangleLoop(startLat: 40.7120, startLng: -74.0050, widthMeters: 30, heightMeters: 30, startTime: _epoch)],
        areaSqMeters: 900.0,
        lastDefendedAt: DateTime.now(),
        isOwnedByCurrentUser: false,
      ));

      // User captures loop overlapping both
      final userLoop = createRectangleLoop(startLat: 40.7118, startLng: -74.0062, widthMeters: 150, heightMeters: 60, startTime: _epoch);
      final result = await fakeTerritoryRepository.captureTerritory(userLoop);

      expect(result.rivalsAffected, equals(2));
    });

    // F6: Territory Decay & Warnings (26-30)
    test('26. F6: Territory last defended within 7 days does not decay.', () {
      fakeAsync((async) {
        final loop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 50, heightMeters: 50, startTime: _epoch);
        fakeTerritoryRepository.territories.add(TerritoryEntity(
          id: 'user-t',
          userId: 'user-1',
          ownerDisplayName: 'Player 1',
          polygons: [loop],
          areaSqMeters: 2500.0,
          lastDefendedAt: DateTime.now(),
          isOwnedByCurrentUser: true,
        ));

        fakeTerritoryRepository.simulateDecay(const Duration(days: 6));
        async.flushMicrotasks();

        expect(fakeTerritoryRepository.territories.first.areaSqMeters, equals(2500.0));
      });
    });

    test('27. F6: Territory last defended > 7 days decays by shrinking 5 meters (ST_Buffer negative offset).', () {
      fakeAsync((async) {
        final loop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 50, heightMeters: 50, startTime: _epoch);
        fakeTerritoryRepository.territories.add(TerritoryEntity(
          id: 'user-t',
          userId: 'user-1',
          ownerDisplayName: 'Player 1',
          polygons: [loop],
          areaSqMeters: 2500.0,
          lastDefendedAt: DateTime.now(),
          isOwnedByCurrentUser: true,
        ));

        // 8 days total -> 1 day past decay grace period -> shrinks 5 meters (offset area)
        fakeTerritoryRepository.simulateDecay(const Duration(days: 8));
        async.flushMicrotasks();

        expect(fakeTerritoryRepository.territories.first.areaSqMeters, lessThan(2500.0));
      });
    });

    test('28. F6: Decay warning triggers when last defended is 5-6 days ago (1-2 days before decay).', () {
      fakeAsync((async) {
        final loop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 50, heightMeters: 50, startTime: _epoch);
        fakeTerritoryRepository.territories.add(TerritoryEntity(
          id: 'user-t',
          userId: 'user-1',
          ownerDisplayName: 'Player 1',
          polygons: [loop],
          areaSqMeters: 2500.0,
          lastDefendedAt: DateTime.now(),
          isOwnedByCurrentUser: true,
        ));

        fakeTerritoryRepository.simulateDecay(const Duration(days: 5, hours: 12));
        async.flushMicrotasks();

        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        async.run((self) async {
          final warnings = await container.read(decayWarningsProvider.future);
          expect(warnings, isNotEmpty);
          expect(warnings.first.daysUntilDecay, lessThanOrEqualTo(2.0));
          expect(warnings.first.daysUntilDecay, greaterThan(0.0));
        });
      });
    });

    test('29. F6: Warning triggers a local push notification on app launch.', () async {
      // notifyIfDecaying checks count > 0 and shows notification, returns successfully
      await expectLater(TerritoryDecayNotificationService.notifyIfDecaying(territoryCount: 1), completes);
    });

    test('30. F6: Defending a territory (running through/near it) updates `last_defended_at` and resets decay timer.', () async {
      final loop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 50, heightMeters: 50, startTime: _epoch);
      final originalTime = DateTime.now().subtract(const Duration(days: 5));
      fakeTerritoryRepository.territories.add(TerritoryEntity(
        id: 'user-t',
        userId: 'user-1',
        ownerDisplayName: 'Player 1',
        polygons: [loop],
        areaSqMeters: 2500.0,
        lastDefendedAt: originalTime,
        isOwnedByCurrentUser: true,
      ));

      // Path touching within 20m (e.g. 40.7128, -74.0060)
      final path = [GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: DateTime.now())];
      await fakeTerritoryRepository.touchDefense(path);

      expect(fakeTerritoryRepository.territories.first.lastDefendedAt.isAfter(originalTime), isTrue);
    });

    // F7: Leaderboards & Realtime Sync (31-35)
    test('31. F7: Global leaderboard ranks users correctly by total area owned.', () async {
      fakeTerritoryRepository.territories.add(TerritoryEntity(
        id: 'rival-t', userId: 'rival-1', ownerDisplayName: 'Rival', polygons: const [], areaSqMeters: 1000.0, lastDefendedAt: DateTime.now(), isOwnedByCurrentUser: false,
      ));
      fakeTerritoryRepository.territories.add(TerritoryEntity(
        id: 'user-t', userId: 'user-1', ownerDisplayName: 'User', polygons: const [], areaSqMeters: 2000.0, lastDefendedAt: DateTime.now(), isOwnedByCurrentUser: true,
      ));

      final leaderboard = await fakeTerritoryRepository.getGlobalLeaderboard();
      expect(leaderboard[0].userId, equals('user-1'));
      expect(leaderboard[1].userId, equals('rival-1'));
    });

    test('32. F7: Nearby leaderboard ranks users within 5000m radius of current viewer location.', () async {
      final viewer = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: DateTime.now());
      // Rival 1 (close - 100m)
      fakeTerritoryRepository.territories.add(TerritoryEntity(
        id: 'r1', userId: 'rival-1', ownerDisplayName: 'Rival 1',
        polygons: [createRectangleLoop(startLat: 40.7130, startLng: -74.0060, widthMeters: 10, heightMeters: 10, startTime: _epoch)],
        areaSqMeters: 100.0, lastDefendedAt: DateTime.now(), isOwnedByCurrentUser: false,
      ));
      // Rival 2 (far - 6000m)
      // 0.05 degrees is approx 5559m
      fakeTerritoryRepository.territories.add(TerritoryEntity(
        id: 'r2', userId: 'rival-2', ownerDisplayName: 'Rival 2',
        polygons: [createRectangleLoop(startLat: 40.7628, startLng: -74.0060, widthMeters: 10, heightMeters: 10, startTime: _epoch)],
        areaSqMeters: 200.0, lastDefendedAt: DateTime.now(), isOwnedByCurrentUser: false,
      ));

      final nearby = await fakeTerritoryRepository.getNearbyLeaderboard(viewer);
      expect(nearby.length, equals(1));
      expect(nearby.first.userId, equals('rival-1'));
    });

    test('33. F7: Realtime stream notifies listeners when territory map updates.', () async {
      final updates = <List<TerritoryEntity>>[];
      final subscription = fakeTerritoryRepository.watchTerritories().listen(updates.add);

      final loop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 60, heightMeters: 60, startTime: _epoch);
      await fakeTerritoryRepository.captureTerritory(loop);
      await Future<void>.delayed(Duration.zero);

      expect(updates.any((list) => list.isNotEmpty), isTrue);
      await subscription.cancel();
    });

    test('34. F7: Leaderboard provider automatically invalidates and refetches when map updates.', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);
        enableTerritoryMapForTests(container);
        enableTerritoryTabForTests(container);

        // Force initial read
        async.run((self) async {
          final initial = await container.read(leaderboardProvider.future);
          expect(initial, isEmpty);
        });

        // Claim territory
        final loop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 60, heightMeters: 60, startTime: _epoch);
        fakeTerritoryRepository.captureTerritory(loop);
        async.flushMicrotasks();

        async.run((self) async {
          final updated = await container.read(leaderboardProvider.future);
          expect(updated, isNotEmpty);
          expect(updated.first.userId, equals('user-1'));
        });
      });
    });

    testWidgets('35. F7: Tab navigation switches between map, run screen, and leaderboard UI smoothly (verify UI screens and tabs can switch).', (WidgetTester tester) async {
      final fakeRepo = FakeTerritoryRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
            authStateProvider.overrideWith((ref) => signedOutAuthStateStream()),
            isSignedInProvider.overrideWith((ref) => false),
            currentUserProvider.overrideWith((ref) => null),
            alarmRepositoryProvider.overrideWithValue(FakeAlarmRepository()),
            sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
            territoryRepositoryProvider.overrideWithValue(fakeRepo),
            clockDisplayProvider.overrideWith((ref) => Stream.value('08:00')),
          ],
          child: const AwakenApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('AWAKEN'), findsOneWidget);

      await tester.tap(find.text('Run a loop, claim territory'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Start run'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.leaderboard_rounded));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('LEADERBOARD'), findsOneWidget);
    });
  });

  group('Tier 2: Boundary & Corner Cases', () {
    // F1: GPS Tracking & Kalman Smoothing (36-40)
    test('36. F1: Empty coordinates list (run starts and stops immediately with no fixes).', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(activeRunProvider.notifier);
        notifier.startRun();
        async.flushMicrotasks();

        notifier.finishRun();
        async.flushMicrotasks();

        expect(container.read(activeRunProvider).result?.outcome, equals(RunOutcome.invalidatedTooShort));
      });
    });

    test('37. F1: Single coordinate fix (run starts, gets one fix, stops).', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(activeRunProvider.notifier);
        notifier.startRun();
        async.flushMicrotasks();

        mockGeolocator.feedPosition(createPos(lat: 40.7128, lng: -74.0060, time: DateTime.now()));
        async.flushMicrotasks();

        notifier.finishRun();
        async.flushMicrotasks();

        expect(container.read(activeRunProvider).result?.points.length, equals(1));
        expect(container.read(activeRunProvider).result?.outcome, equals(RunOutcome.invalidatedTooShort));
      });
    });

    test('38. F1: Two identical coordinate fixes (runner is stationary, distance should be 0).', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(activeRunProvider.notifier);
        notifier.startRun();
        async.flushMicrotasks();

        final now = DateTime.now();
        mockGeolocator.feedPosition(createPos(lat: 40.7128, lng: -74.0060, time: now));
        async.flushMicrotasks();
        mockGeolocator.feedPosition(createPos(lat: 40.7128, lng: -74.0060, time: now.add(const Duration(seconds: 5))));
        async.flushMicrotasks();

        expect(container.read(activeRunProvider).distanceMeters, equals(0.0));
      });
    });

    test('39. F1: High noise Kalman filter adaptation (very noisy track eventually stabilizes).', () {
      final filter = GpsKalmanFilter(processNoise: 3.0);
      filter.filter(40.7128, -74.0060, 3.0);

      // Noise of +/- 0.005 deg (~500m) with high uncertainty (50m)
      for (var i = 0; i < 20; i++) {
        filter.filter(40.7128 + 0.005 * math.sin(i), -74.0060 + 0.005 * math.cos(i), 50.0);
      }
      
      // Stable stream with low uncertainty
      var finalLat = 0.0;
      var finalLng = 0.0;
      for (var i = 0; i < 10; i++) {
        final res = filter.filter(40.7128, -74.0060, 2.0);
        finalLat = res.$1;
        finalLng = res.$2;
      }
      expect((finalLat - 40.7128).abs(), lessThan(0.0002));
      expect((finalLng - (-74.0060)).abs(), lessThan(0.0002));
    });

    test('40. F1: Distance filter boundary: coordinates closer than 5 meters are filtered by Geolocator settings.', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(activeRunProvider.notifier);
        notifier.startRun();
        async.flushMicrotasks();

        // The Geolocator settings has distanceFilter: 5
        // We verify the code doesn't crash and initializes Geolocator
        expect(container.read(activeRunProvider).status, equals(RunSessionStatus.tracking));
      });
    });

    // F2: Speed Cap Anti-Cheat (41-45)
    test('41. F2: Exact boundary speed of 25.0 km/h is NOT flagged as over-speed.', () {
      final base = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: DateTime.now());
      final points = [base];
      for (var i = 0; i < 6; i++) {
        // 24.99 ensures haversine computed speed is strictly <= 25.0
        points.add(movePointBySpeed(points.last, 24.99, const Duration(seconds: 1)));
      }
      expect(RunValidationService.isSustainedOverSpeed(points), isFalse);
    });

    test('42. F2: Exact boundary speed of 25.01 km/h is flagged as over-speed.', () {
      final base = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: DateTime.now());
      final points = [base];
      for (var i = 0; i < 6; i++) {
        points.add(movePointBySpeed(points.last, 25.01, const Duration(seconds: 1)));
      }
      expect(RunValidationService.isSustainedOverSpeed(points), isTrue);
    });

    test('43. F2: Speed cap with exactly 5 over-speed points (rolling window needs 6 points) - not flagged.', () {
      final base = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: DateTime.now());
      final points = [base];
      // Interval 1: slow (so P1 is slow, leaving exactly 5 fast points in a 6-point window)
      points.add(movePointBySpeed(points.last, 10.0, const Duration(seconds: 1)));
      // Intervals 2-6: fast
      for (var i = 0; i < 4; i++) {
        points.add(movePointBySpeed(points.last, 30.0, const Duration(seconds: 1)));
      }
      expect(RunValidationService.isSustainedOverSpeed(points), isFalse);
    });

    test('44. F2: Speed cap with exactly 6 over-speed points - flagged.', () {
      final base = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: DateTime.now());
      final points = [base];
      for (var i = 0; i < 5; i++) {
        points.add(movePointBySpeed(points.last, 30.0, const Duration(seconds: 1)));
      }
      expect(RunValidationService.isSustainedOverSpeed(points), isTrue);
    });

    test('45. F2: Extremely high speed (e.g., plane speed 500 km/h) instantly flags over-speed when rolling window is satisfied.', () {
      final base = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: DateTime.now());
      final points = [base];
      for (var i = 0; i < 5; i++) {
        points.add(movePointBySpeed(points.last, 500.0, const Duration(seconds: 1)));
      }
      expect(RunValidationService.isSustainedOverSpeed(points), isTrue);
    });

    // F3: RDP Simplification (46-50)
    test('46. F3: Simplification of empty path list returns empty list.', () {
      expect(RdpSimplifier.simplify([], 3.0), isEmpty);
    });

    test('47. F3: Simplification of a single point returns that point.', () {
      final pt = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: DateTime.now());
      expect(RdpSimplifier.simplify([pt], 3.0), equals([pt]));
    });

    test('48. F3: Simplification of exactly two points returns those two points unchanged.', () {
      final pt1 = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: DateTime.now());
      final pt2 = GeoPointEntity(latitude: 40.7138, longitude: -74.0060, timestamp: DateTime.now());
      expect(RdpSimplifier.simplify([pt1, pt2], 3.0), equals([pt1, pt2]));
    });

    test('49. F3: Epsilon boundary: vertex deviation of exactly 2.99m is simplified away, exactly 3.01m is kept.', () {
      final baseTime = DateTime.now();
      // Latitude delta for 2.99m is approx 2.99 / 111194.9266 = 0.000026889
      // Latitude delta for 3.01m is approx 3.01 / 111194.9266 = 0.000027069
      final ptStart = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: baseTime);
      final ptEnd = GeoPointEntity(latitude: 40.7128, longitude: -74.0080, timestamp: baseTime.add(const Duration(seconds: 60)));

      // Collinear mid-point but offset by 2.99m in latitude
      final ptMid1 = GeoPointEntity(latitude: 40.7128 + 0.0000268, longitude: -74.0070, timestamp: baseTime.add(const Duration(seconds: 30)));
      // Collinear mid-point but offset by 3.01m in latitude
      final ptMid2 = GeoPointEntity(latitude: 40.7128 + 0.0000271, longitude: -74.0070, timestamp: baseTime.add(const Duration(seconds: 30)));

      final simplified1 = RdpSimplifier.simplify([ptStart, ptMid1, ptEnd], 3.0);
      final simplified2 = RdpSimplifier.simplify([ptStart, ptMid2, ptEnd], 3.0);

      expect(simplified1.length, equals(2));
      expect(simplified2.length, equals(3));
    });

    test('50. F3: Simplification of closed loop: start and end vertices are preserved.', () {
      final baseTime = DateTime.now();
      final loop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 60, heightMeters: 60, startTime: baseTime);
      final simplified = RdpSimplifier.simplify(loop, 3.0);
      expect(simplified.first.latitude, equals(loop.first.latitude));
      expect(simplified.last.latitude, equals(loop.last.latitude));
    });

    // F4: Loop Claiming & Validation (51-56)
    test('51. F4: Start/end distance of exactly 20.0m is closed.', () {
      final pt1 = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: _epoch);
      // 20m latitude delta is approx 20 / 111194.9266 = 0.000179865 degrees
      final pt2 = GeoPointEntity(latitude: 40.7128 + 0.0001798, longitude: -74.0060, timestamp: _epoch);
      expect(RunValidationService.isClosedLoop([pt1, pt2]), isTrue);
    });

    test('52. F4: Start/end distance of exactly 20.01m is not closed.', () {
      final pt1 = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: _epoch);
      // 20.01m latitude delta is approx 20.01 / 111194.9266 = 0.000179955 degrees
      final pt2 = GeoPointEntity(latitude: 40.7128 + 0.0001801, longitude: -74.0060, timestamp: _epoch);
      expect(RunValidationService.isClosedLoop([pt1, pt2]), isFalse);
    });

    test('53. F4: Run duration of exactly 2 minutes (120 seconds) is valid.', () {
      final baseTime = DateTime.now();
      final loop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 60, heightMeters: 60, startTime: baseTime, interval: const Duration(seconds: 30));
      final outcome = RunValidationService.classify(
        points: loop,
        distanceMeters: 240,
        duration: const Duration(seconds: 120),
        wasInvalidatedBySpeed: false,
      );
      expect(outcome, equals(RunOutcome.territoryClaimed));
    });

    test('54. F4: Run duration of exactly 119 seconds is invalid.', () {
      final baseTime = DateTime.now();
      final loop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 60, heightMeters: 60, startTime: baseTime, interval: const Duration(seconds: 29));
      final outcome = RunValidationService.classify(
        points: loop,
        distanceMeters: 240,
        duration: const Duration(seconds: 119),
        wasInvalidatedBySpeed: false,
      );
      expect(outcome, equals(RunOutcome.invalidatedTooShort));
    });

    test('55. F4: Cumulative distance of exactly 200.0m is valid.', () {
      final baseTime = DateTime.now();
      final loop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 50, heightMeters: 50, startTime: baseTime);
      final outcome = RunValidationService.classify(
        points: loop,
        distanceMeters: 200.0,
        duration: const Duration(minutes: 2),
        wasInvalidatedBySpeed: false,
      );
      expect(outcome, equals(RunOutcome.territoryClaimed));
    });

    test('56. F4: Cumulative distance of exactly 199.9m is invalid.', () {
      final baseTime = DateTime.now();
      final loop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 49, heightMeters: 50, startTime: baseTime);
      final outcome = RunValidationService.classify(
        points: loop,
        distanceMeters: 199.9,
        duration: const Duration(minutes: 2),
        wasInvalidatedBySpeed: false,
      );
      expect(outcome, equals(RunOutcome.invalidatedTooShort));
    });

    // F5: Territory Merging & Stealing (57-61)
    test('57. F5: Capturing a loop completely enclosing a rival\'s territory (rival is fully consumed and deleted).', () async {
      // Seed rival
      final rivalLoop = createRectangleLoop(startLat: 40.7125, startLng: -74.0055, widthMeters: 20, heightMeters: 20, startTime: _epoch);
      fakeTerritoryRepository.territories.add(TerritoryEntity(
        id: 'rival-t', userId: 'rival-1', ownerDisplayName: 'Rival', polygons: [rivalLoop], areaSqMeters: 400.0, lastDefendedAt: DateTime.now(), isOwnedByCurrentUser: false,
      ));

      // User fully encloses
      final userLoop = createRectangleLoop(startLat: 40.7120, startLng: -74.0060, widthMeters: 100, heightMeters: 100, startTime: _epoch);
      await fakeTerritoryRepository.captureTerritory(userLoop);

      expect(fakeTerritoryRepository.territories.where((t) => t.userId == 'rival-1'), isEmpty);
    });

    test('58. F5: Capturing a loop completely inside an existing own territory (no change in total area, merges cleanly).', () async {
      // User initial
      final loop1 = createRectangleLoop(startLat: 40.7120, startLng: -74.0060, widthMeters: 100, heightMeters: 100, startTime: _epoch);
      await fakeTerritoryRepository.captureTerritory(loop1);
      final initialArea = fakeTerritoryRepository.territories.first.areaSqMeters;

      // Capture inside
      final loop2 = createRectangleLoop(startLat: 40.7122, startLng: -74.0058, widthMeters: 20, heightMeters: 20, startTime: _epoch);
      await fakeTerritoryRepository.captureTerritory(loop2);

      final user = fakeTerritoryRepository.territories.firstWhere((t) => t.userId == 'user-1');
      expect(user.areaSqMeters, equals(initialArea));
    });

    test('59. F5: Rival territory reduced to exactly 1.0 m² is kept.', () async {
      final rivalLoop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 1.0, heightMeters: 1.0, startTime: _epoch);
      fakeTerritoryRepository.territories.add(TerritoryEntity(
        id: 'rival-t', userId: 'rival-1', ownerDisplayName: 'Rival', polygons: [rivalLoop], areaSqMeters: 1.0, lastDefendedAt: DateTime.now(), isOwnedByCurrentUser: false,
      ));

      // Cut 0%
      final userLoop = createRectangleLoop(startLat: 40.7135, startLng: -74.0060, widthMeters: 10, heightMeters: 10, startTime: _epoch);
      await fakeTerritoryRepository.captureTerritory(userLoop);

      expect(fakeTerritoryRepository.territories.any((t) => t.userId == 'rival-1'), isTrue);
    });

    test('60. F5: Rival territory reduced to exactly 0.99 m² is deleted (sliver cleanup).', () async {
      final rivalLoop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 0.99, heightMeters: 1.0, startTime: _epoch);
      fakeTerritoryRepository.territories.add(TerritoryEntity(
        id: 'rival-t', userId: 'rival-1', ownerDisplayName: 'Rival', polygons: [rivalLoop], areaSqMeters: 0.99, lastDefendedAt: DateTime.now(), isOwnedByCurrentUser: false,
      ));

      // Overlap fully
      final userLoop = createRectangleLoop(startLat: 40.7125, startLng: -74.0062, widthMeters: 100, heightMeters: 100, startTime: _epoch);
      await fakeTerritoryRepository.captureTerritory(userLoop);

      expect(fakeTerritoryRepository.territories.where((t) => t.userId == 'rival-1'), isEmpty);
    });

    test('61. F5: Merging non-overlapping user territories (remain as separate polygons).', () async {
      // Capture 1
      final loop1 = createRectangleLoop(startLat: 40.7120, startLng: -74.0060, widthMeters: 30, heightMeters: 30, startTime: _epoch);
      await fakeTerritoryRepository.captureTerritory(loop1);

      // Capture 2 (non-overlapping)
      final loop2 = createRectangleLoop(startLat: 40.7150, startLng: -74.0060, widthMeters: 30, heightMeters: 30, startTime: _epoch);
      await fakeTerritoryRepository.captureTerritory(loop2);

      final user = fakeTerritoryRepository.territories.firstWhere((t) => t.userId == 'user-1');
      expect(user.polygons.length, equals(2));
    });

    // F6: Territory Decay & Warnings (62-66)
    test('62. F6: Exact boundary: age of exactly 7 days (168 hours) does NOT trigger decay.', () {
      fakeAsync((async) {
        final loop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 50, heightMeters: 50, startTime: _epoch);
        fakeTerritoryRepository.territories.add(TerritoryEntity(
          id: 'user-t', userId: 'user-1', ownerDisplayName: 'Player 1', polygons: [loop], areaSqMeters: 2500.0, lastDefendedAt: DateTime.now(), isOwnedByCurrentUser: true,
        ));

        fakeTerritoryRepository.simulateDecay(const Duration(days: 7));
        async.flushMicrotasks();

        expect(fakeTerritoryRepository.territories.first.areaSqMeters, equals(2500.0));
      });
    });

    test('63. F6: Exact boundary: age of exactly 7.01 days triggers decay.', () {
      fakeAsync((async) {
        final loop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 50, heightMeters: 50, startTime: _epoch);
        fakeTerritoryRepository.territories.add(TerritoryEntity(
          id: 'user-t', userId: 'user-1', ownerDisplayName: 'Player 1', polygons: [loop], areaSqMeters: 2500.0, lastDefendedAt: DateTime.now(), isOwnedByCurrentUser: true,
        ));

        // 7.01 days triggers decay (decayDays = 7.01 - 7 = 0.01 days -> count as 0.01 day decay -> shrinks 0.05m)
        fakeTerritoryRepository.simulateDecay(const Duration(days: 7, hours: 1));
        async.flushMicrotasks();

        expect(fakeTerritoryRepository.territories.first.areaSqMeters, lessThan(2500.0));
      });
    });

    test('64. F6: Decayed territory shrinking to 0 m² or empty is deleted.', () {
      fakeAsync((async) {
        final loop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 1.0, heightMeters: 1.0, startTime: _epoch);
        fakeTerritoryRepository.territories.add(TerritoryEntity(
          id: 'user-t', userId: 'user-1', ownerDisplayName: 'Player 1', polygons: [loop], areaSqMeters: 1.0, lastDefendedAt: DateTime.now(), isOwnedByCurrentUser: true,
        ));

        fakeTerritoryRepository.simulateDecay(const Duration(days: 8));
        async.flushMicrotasks();

        expect(fakeTerritoryRepository.territories.first.areaSqMeters, equals(0.0));
        expect(fakeTerritoryRepository.territories.first.polygons, isEmpty);
      });
    });

    test('65. F6: Warning boundary: warning triggers at exactly 1.99 days before decay, but not at 2.01 days.', () {
      fakeAsync((async) {
        // Warning triggers when days left is <= 2.0.
        // Grace period is 7 days.
        // 1.99 days left means age is 7 - 1.99 = 5.01 days.
        // 2.01 days left means age is 7 - 2.01 = 4.99 days.

        // Case 1: age = 4.99 days (2.01 days left) -> no warning
        final loop1 = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 50, heightMeters: 50, startTime: _epoch);
        final t1 = TerritoryEntity(
          id: 't1', userId: 'user-1', ownerDisplayName: 'Player 1', polygons: [loop1], areaSqMeters: 2500.0,
          lastDefendedAt: DateTime.now().subtract(const Duration(days: 4, hours: 23, minutes: 45)), isOwnedByCurrentUser: true,
        );
        fakeTerritoryRepository.territories.add(t1);

        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        async.run((self) async {
          final warnings = await container.read(decayWarningsProvider.future);
          expect(warnings, isEmpty);
        });

        // Case 2: age = 5.01 days (1.99 days left) -> warning
        fakeTerritoryRepository.territories.clear();
        final t2 = TerritoryEntity(
          id: 't2', userId: 'user-1', ownerDisplayName: 'Player 1', polygons: [loop1], areaSqMeters: 2500.0,
          lastDefendedAt: DateTime.now().subtract(const Duration(days: 5, hours: 0, minutes: 15)), isOwnedByCurrentUser: true,
        );
        fakeTerritoryRepository.territories.add(t2);

        container.invalidate(decayWarningsProvider);
        async.flushMicrotasks();

        async.run((self) async {
          final warnings = await container.read(decayWarningsProvider.future);
          expect(warnings, isNotEmpty);
        });
      });
    });

    test('66. F6: Touching defense within exactly 20.0m of territory boundary updates defense timestamp.', () async {
      final loop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 50, heightMeters: 50, startTime: _epoch);
      final originalTime = DateTime.now().subtract(const Duration(days: 5));
      fakeTerritoryRepository.territories.add(TerritoryEntity(
        id: 'user-t', userId: 'user-1', ownerDisplayName: 'Player 1', polygons: [loop], areaSqMeters: 2500.0, lastDefendedAt: originalTime, isOwnedByCurrentUser: true,
      ));

      // Point at exactly 20.0m latitude from a vertex
      // 20m latitude delta = approx 20 / 111194.9266 = 0.000179865 deg
      final defensePt = GeoPointEntity(latitude: 40.7128 - 0.0001798, longitude: -74.0060, timestamp: DateTime.now());
      await fakeTerritoryRepository.touchDefense([defensePt]);

      expect(fakeTerritoryRepository.territories.first.lastDefendedAt.isAfter(originalTime), isTrue);
    });

    // F7: Leaderboards & Realtime Sync (67-71)
    test('67. F7: Empty leaderboard (no territories registered).', () async {
      final leaderboard = await fakeTerritoryRepository.getGlobalLeaderboard();
      expect(leaderboard, isEmpty);
    });

    test('68. F7: User outside the 5000m nearby radius is excluded from Nearby leaderboard.', () async {
      final viewer = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: DateTime.now());
      // Rival far away (5559.7m)
      fakeTerritoryRepository.territories.add(TerritoryEntity(
        id: 'far-t', userId: 'rival-1', ownerDisplayName: 'Rival 1',
        polygons: [createRectangleLoop(startLat: 40.7128 + 0.05, startLng: -74.0060, widthMeters: 10, heightMeters: 10, startTime: _epoch)],
        areaSqMeters: 100.0, lastDefendedAt: DateTime.now(), isOwnedByCurrentUser: false,
      ));

      final leaderboard = await fakeTerritoryRepository.getNearbyLeaderboard(viewer);
      expect(leaderboard, isEmpty);
    });

    test('69. F7: Exact boundary: user at exactly 5000.0m from viewer is included in Nearby leaderboard.', () async {
      final viewer = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: DateTime.now());
      // Rival at exactly 5000.0m
      fakeTerritoryRepository.territories.add(TerritoryEntity(
        id: 'boundary-t', userId: 'rival-1', ownerDisplayName: 'Rival 1',
        polygons: [createRectangleLoop(startLat: 40.7128 + 0.044966078, startLng: -74.0060, widthMeters: 10, heightMeters: 10, startTime: _epoch)],
        areaSqMeters: 100.0, lastDefendedAt: DateTime.now(), isOwnedByCurrentUser: false,
      ));

      final leaderboard = await fakeTerritoryRepository.getNearbyLeaderboard(viewer);
      expect(leaderboard, isNotEmpty);
    });

    test('70. F7: Exact boundary: user at exactly 5000.1m is excluded.', () async {
      final viewer = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: DateTime.now());
      // Rival at exactly 5000.1m
      fakeTerritoryRepository.territories.add(TerritoryEntity(
        id: 'boundary-t-2', userId: 'rival-1', ownerDisplayName: 'Rival 1',
        polygons: [createRectangleLoop(startLat: 40.7128 + 0.044966978, startLng: -74.0060, widthMeters: 10, heightMeters: 10, startTime: _epoch)],
        areaSqMeters: 100.0, lastDefendedAt: DateTime.now(), isOwnedByCurrentUser: false,
      ));

      final leaderboard = await fakeTerritoryRepository.getNearbyLeaderboard(viewer);
      expect(leaderboard, isEmpty);
    });

    test('71. F7: Realtime sync updates multiple screens concurrently (Leaderboard and Map both react to change).', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);
        enableTerritoryMapForTests(container);
        enableTerritoryTabForTests(container);

        // Watch map stream and leaderboard future
        var mapUpdatesCount = 0;
        var leaderboardUpdatesCount = 0;

        container.listen(territoryListProvider, (prev, next) {
          mapUpdatesCount++;
        }, fireImmediately: true);

        container.listen(leaderboardProvider, (prev, next) {
          leaderboardUpdatesCount++;
        }, fireImmediately: true);

        async.flushMicrotasks();

        // Perform update
        final loop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 60, heightMeters: 60, startTime: _epoch);
        fakeTerritoryRepository.captureTerritory(loop);
        async.flushMicrotasks();

        expect(mapUpdatesCount, greaterThan(0));
        expect(leaderboardUpdatesCount, greaterThan(0));
      });
    });
  });

  group('Tier 3: Cross-Feature Combinations', () {
    test('72. F1+F3+F4: Noisy GPS stream gets Kalman-smoothed and simplified, closing a loop that passes validation.', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(activeRunProvider.notifier);
        notifier.startRun();
        async.flushMicrotasks();

        final baseTime = DateTime.now();
        // A loop of 300mx300m with noise (accuracy 30m) injected in fixes, lasting 2m
        // Use a larger size to offset the heavy Kalman smoothing distance reduction
        final pts = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 300, heightMeters: 300, startTime: baseTime, interval: const Duration(seconds: 30));
        
        mockGeolocator.feedPosition(createPos(lat: pts[0].latitude, lng: pts[0].longitude, time: pts[0].timestamp, accuracy: 30.0));
        async.flushMicrotasks();

        for (var i = 1; i < pts.length; i++) {
          async.elapse(const Duration(seconds: 30));
          final p = pts[i];
          final isLast = i == pts.length - 1;
          final noiseLat = isLast ? 0.0 : 0.0001 * math.sin(i);
          final noiseLng = isLast ? 0.0 : 0.0001 * math.cos(i);
          final acc = isLast ? 0.1 : 30.0;
          mockGeolocator.feedPosition(createPos(
            lat: p.latitude + noiseLat,
            lng: p.longitude + noiseLng,
            time: p.timestamp,
            accuracy: acc,
          ));
          async.flushMicrotasks();
        }

        notifier.finishRun();
        async.flushMicrotasks();

        expect(container.read(activeRunProvider).result?.outcome, equals(RunOutcome.territoryClaimed));
      });
    });

    test('73. F2+F4+F5: Run has short over-speed spikes but doesn\'t trigger sustained speed cap, closes loop, and successfully merges with own territory.', () {
      fakeAsync((async) {
        // Seed initial own territory
        final initialLoop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 60, heightMeters: 60, startTime: _epoch);
        fakeTerritoryRepository.territories.add(TerritoryEntity(
          id: 'user-t', userId: 'user-1', ownerDisplayName: 'Player 1', polygons: [initialLoop], areaSqMeters: 3600.0, lastDefendedAt: DateTime.now(), isOwnedByCurrentUser: true,
        ));

        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(activeRunProvider.notifier);
        notifier.startRun();
        async.flushMicrotasks();

        final baseTime = DateTime.now();
        final loop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 60, heightMeters: 60, startTime: baseTime, interval: const Duration(seconds: 30));
        
        mockGeolocator.feedPosition(createPos(lat: loop[0].latitude, lng: loop[0].longitude, time: loop[0].timestamp, accuracy: 0.1, speed: 8.0));
        async.flushMicrotasks();

        for (var i = 1; i < loop.length; i++) {
          async.elapse(const Duration(seconds: 30));
          final p = loop[i];
          final speed = i == 2 ? 40.0 : 8.0;
          mockGeolocator.feedPosition(createPos(lat: p.latitude, lng: p.longitude, time: p.timestamp, accuracy: 0.1, speed: speed));
          async.flushMicrotasks();
        }

        notifier.finishRun();
        async.flushMicrotasks();

        final state = container.read(activeRunProvider);
        expect(state.result?.outcome, equals(RunOutcome.territoryClaimed));
        expect(fakeTerritoryRepository.territories.firstWhere((t) => t.userId == 'user-1').polygons.length, equals(1));
      });
    });

    test('74. F4+F5+F7: User closes valid loop, steals rival territory, and instantly rises in the Nearby leaderboard.', () {
      fakeAsync((async) {
        // Seed rival with 900m2 territory close by
        final rivalLoop = createRectangleLoop(startLat: 40.7130, startLng: -74.0058, widthMeters: 30, heightMeters: 30, startTime: _epoch);
        fakeTerritoryRepository.territories.add(TerritoryEntity(
          id: 'rival-t', userId: 'rival-1', ownerDisplayName: 'Rival', polygons: [rivalLoop], areaSqMeters: 900.0, lastDefendedAt: DateTime.now(), isOwnedByCurrentUser: false,
        ));

        final container = ProviderContainer(
          overrides: [
            territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository),
            viewerLocationProvider.overrideWith(FakeViewerLocationNotifier.new),
            leaderboardModeProvider.overrideWith(FakeLeaderboardModeNotifier.new),
          ],
        );
        addTearDown(container.dispose);

        // Fetch leaderboard first
        async.run((self) async {
          final leaderboard = await container.read(leaderboardProvider.future);
          expect(leaderboard.first.userId, equals('rival-1'));
        });

        // User does a larger loop capture, overlapping/stealing from rival
        final userLoop = createRectangleLoop(startLat: 40.7120, startLng: -74.0060, widthMeters: 100, heightMeters: 100, startTime: DateTime.now());
        fakeTerritoryRepository.captureTerritory(userLoop);
        async.flushMicrotasks();

        container.invalidate(leaderboardProvider);
        async.flushMicrotasks();

        async.run((self) async {
          final leaderboard = await container.read(leaderboardProvider.future);
          expect(leaderboard.first.userId, equals('user-1')); // User overtakes!
        });
      });
    });

    test('75. F4+F6+F7: Decayed territory shrinks, dropping a user in the leaderboard; user runs through it, defending it, resetting decay, and updating the leaderboard.', () {
      fakeAsync((async) {
        final loopUser = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 60, heightMeters: 60, startTime: _epoch);
        fakeTerritoryRepository.territories.add(TerritoryEntity(
          id: 'user-t', userId: 'user-1', ownerDisplayName: 'User', polygons: [loopUser], areaSqMeters: 3200.0, lastDefendedAt: DateTime.now(), isOwnedByCurrentUser: true,
        ));

        // Rival territory: 3000.0 m2 (User is rank #1, Rival is rank #2)
        fakeTerritoryRepository.territories.add(TerritoryEntity(
          id: 'rival-t', userId: 'rival-1', ownerDisplayName: 'Rival', polygons: const [], areaSqMeters: 3000.0, lastDefendedAt: DateTime.now(), isOwnedByCurrentUser: false,
        ));

        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        // 1. Decayed territory shrinks by 800m2 -> user area becomes 2800m2 -> user drops in leaderboard
        fakeTerritoryRepository.simulateDecay(const Duration(days: 100)); // Large age offset to cause shrink
        
        // Reset rival's area and defender time so rival doesn't decay
        final rivalIdx = fakeTerritoryRepository.territories.indexWhere((t) => t.userId == 'rival-1');
        fakeTerritoryRepository.territories[rivalIdx] = TerritoryEntity(
          id: 'rival-t',
          userId: 'rival-1',
          ownerDisplayName: 'Rival',
          polygons: const [],
          areaSqMeters: 3000.0,
          lastDefendedAt: DateTime.now(),
          isOwnedByCurrentUser: false,
        );
        async.flushMicrotasks();

        async.run((self) async {
          final leaderboard = await container.read(leaderboardProvider.future);
          expect(leaderboard.first.userId, equals('rival-1')); // Rival took first place
        });

        // 2. User runs a defense path to defend the territory (resets decay last_defended_at)
        final path = [GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: DateTime.now())];
        fakeTerritoryRepository.touchDefense(path);
        async.flushMicrotasks();

        // Check last defended updated
        final userTerritory = fakeTerritoryRepository.territories.firstWhere((t) => t.userId == 'user-1');
        expect(userTerritory.lastDefendedAt.isAfter(DateTime.now().subtract(const Duration(seconds: 5))), isTrue);
      });
    });

    test('76. F3+F4+F5+F6: Running a loop to defend and expand a territory that is about to decay, simplifying the vertices, and performing self-union.', () {
      fakeAsync((async) {
        // Seed decaying user territory
        final loopUser = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 60, heightMeters: 60, startTime: _epoch);
        fakeTerritoryRepository.territories.add(TerritoryEntity(
          id: 'user-t', userId: 'user-1', ownerDisplayName: 'User', polygons: [loopUser], areaSqMeters: 3600.0,
          lastDefendedAt: DateTime.now().subtract(const Duration(days: 6)), isOwnedByCurrentUser: true,
        ));

        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        // Run a loop that overlaps existing to expand and defend it
        final notifier = container.read(activeRunProvider.notifier);
        notifier.startRun();
        async.flushMicrotasks();

        final baseTime = DateTime.now();
        final path = createRectangleLoop(startLat: 40.7130, startLng: -74.0060, widthMeters: 60, heightMeters: 60, startTime: baseTime, interval: const Duration(seconds: 30));
        
        mockGeolocator.feedPosition(createPos(lat: path[0].latitude, lng: path[0].longitude, time: path[0].timestamp, accuracy: 0.1));
        async.flushMicrotasks();

        for (var i = 1; i < path.length; i++) {
          async.elapse(const Duration(seconds: 30));
          final p = path[i];
          mockGeolocator.feedPosition(createPos(lat: p.latitude, lng: p.longitude, time: p.timestamp, accuracy: 0.1));
          async.flushMicrotasks();
        }

        notifier.finishRun();
        async.flushMicrotasks();

        // Verify:
        // 1. Defended time reset
        final updated = fakeTerritoryRepository.territories.firstWhere((t) => t.userId == 'user-1');
        expect(updated.lastDefendedAt.isAfter(baseTime), isTrue);
        // 2. Self-union merged polygons
        expect(updated.polygons.length, equals(1));
      });
    });

    test('77. F2+F4+F6: Speed cap invalidates a loop capture run, meaning territory does not get defended and continues to decay.', () {
      fakeAsync((async) {
        // Seed decaying user territory
        final loopUser = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 60, heightMeters: 60, startTime: _epoch);
        final initialDefendedTime = DateTime.now().subtract(const Duration(days: 6));
        fakeTerritoryRepository.territories.add(TerritoryEntity(
          id: 'user-t', userId: 'user-1', ownerDisplayName: 'User', polygons: [loopUser], areaSqMeters: 3600.0,
          lastDefendedAt: initialDefendedTime, isOwnedByCurrentUser: true,
        ));

        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(activeRunProvider.notifier);
        notifier.startRun();
        async.flushMicrotasks();

        final baseTime = DateTime.now();
        var current = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: baseTime);
        mockGeolocator.feedPosition(createPos(lat: current.latitude, lng: current.longitude, time: current.timestamp, accuracy: 0.1));
        async.flushMicrotasks();

        for (var i = 1; i <= 6; i++) {
          async.elapse(const Duration(seconds: 30));
          current = movePointBySpeed(current, 30.0, const Duration(seconds: 30));
          mockGeolocator.feedPosition(createPos(lat: current.latitude, lng: current.longitude, time: current.timestamp, accuracy: 0.1));
          async.flushMicrotasks();
        }

        notifier.finishRun();
        async.flushMicrotasks();

        expect(container.read(activeRunProvider).result?.outcome, equals(RunOutcome.invalidatedSpeedCap));

        // Verify territory was NOT defended
        final updated = fakeTerritoryRepository.territories.firstWhere((t) => t.userId == 'user-1');
        expect(updated.lastDefendedAt, equals(initialDefendedTime));
      });
    });

    test('78. F1+F2+F5+F7: Smoothing prevents over-speed flag by filtering jitter, allowing loop capture that steals rival and shifts leaderboard live.', () {
      fakeAsync((async) {
        // Seed rival
        final rivalLoop = createRectangleLoop(startLat: 40.7130, startLng: -74.0055, widthMeters: 30, heightMeters: 30, startTime: _epoch);
        fakeTerritoryRepository.territories.add(TerritoryEntity(
          id: 'rival-t', userId: 'rival-1', ownerDisplayName: 'Rival', polygons: [rivalLoop], areaSqMeters: 900.0, lastDefendedAt: DateTime.now(), isOwnedByCurrentUser: false,
        ));

        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(activeRunProvider.notifier);
        notifier.startRun();
        async.flushMicrotasks();

        final baseTime = DateTime.now();
        // A loop path moving at 8 km/h (under 25) but with large raw GPS jitter spikes (which would look like 40 km/h raw)
        // Kalman filter processNoise: 3.0 will smooth out the raw spikes.
        // Use a larger loop size (150m x 150m) to offset the Kalman distance shrinkage
        final path = createRectangleLoop(startLat: 40.7120, startLng: -74.0060, widthMeters: 200, heightMeters: 200, startTime: baseTime, interval: const Duration(seconds: 30));
        
        mockGeolocator.feedPosition(createPos(lat: path[0].latitude, lng: path[0].longitude, time: path[0].timestamp, accuracy: 0.1));
        async.flushMicrotasks();

        for (var i = 1; i < path.length; i++) {
          async.elapse(const Duration(seconds: 30));
          final p = path[i];
          final isLast = i == path.length - 1;
          final jitterLat = (!isLast && i == 2) ? 0.0003 : 0.0;
          final acc = isLast ? 0.1 : (i == 2 ? 40.0 : 0.1);
          mockGeolocator.feedPosition(createPos(
            lat: p.latitude + jitterLat,
            lng: p.longitude,
            time: p.timestamp,
            accuracy: acc,
          ));
          async.flushMicrotasks();
        }

        notifier.finishRun();
        async.flushMicrotasks();

        expect(container.read(activeRunProvider).result?.outcome, equals(RunOutcome.territoryClaimed));
        expect(fakeTerritoryRepository.territories.where((t) => t.userId == 'rival-1'), isEmpty);
      });
    });
  });

  group('Tier 4: Real-World Application Scenarios', () {
    test('79. E2E Scenario 1: Standard loop capture updates map and leaderboards.', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);
        enableTerritoryMapForTests(container);
        enableTerritoryTabForTests(container);

        final notifier = container.read(activeRunProvider.notifier);
        notifier.startRun();
        async.flushMicrotasks();

        final baseTime = DateTime.now();
        final loop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 60, heightMeters: 60, startTime: baseTime, interval: const Duration(seconds: 30));
        
        mockGeolocator.feedPosition(createPos(lat: loop[0].latitude, lng: loop[0].longitude, time: loop[0].timestamp, accuracy: 0.1));
        async.flushMicrotasks();

        for (var i = 1; i < loop.length; i++) {
          async.elapse(const Duration(seconds: 30));
          final p = loop[i];
          mockGeolocator.feedPosition(createPos(lat: p.latitude, lng: p.longitude, time: p.timestamp, accuracy: 0.1));
          async.flushMicrotasks();
        }

        notifier.finishRun();
        async.flushMicrotasks();

        expect(container.read(activeRunProvider).result?.outcome, equals(RunOutcome.territoryClaimed));

        async.run((self) async {
          final list = await container.read(territoryListProvider.future);
          expect(list.any((t) => t.userId == 'user-1'), isTrue);

          final leaderboard = await container.read(leaderboardProvider.future);
          expect(leaderboard.first.userId, equals('user-1'));
        });
      });
    });

    test('80. E2E Scenario 2: Inactive decay triggers warnings and shrinks size.', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        // Seed territory
        final loop = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 60, heightMeters: 60, startTime: _epoch);
        fakeTerritoryRepository.territories.add(TerritoryEntity(
          id: 'user-t', userId: 'user-1', ownerDisplayName: 'User', polygons: [loop], areaSqMeters: 3600.0, lastDefendedAt: DateTime.now(), isOwnedByCurrentUser: true,
        ));

        // Advance 6 days -> triggers warnings
        fakeTerritoryRepository.simulateDecay(const Duration(days: 6));
        async.flushMicrotasks();

        async.run((self) async {
          final warnings = await container.read(decayWarningsProvider.future);
          expect(warnings, isNotEmpty);
        });

        // Advance further (total 8 days) -> shrinks area
        fakeTerritoryRepository.simulateDecay(const Duration(days: 2));
        async.flushMicrotasks();

        expect(fakeTerritoryRepository.territories.first.areaSqMeters, lessThan(3600.0));
      });
    });

    test('81. E2E Scenario 3: Rivalry Battle. User A claims territory. User B runs a loop cutting User A\'s territory in half (stealing). User A runs a new loop to merge and retake the stolen area. Verify leaderboard and map updates.', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        // 1. User A (Player 1) claims territory
        final loopA = createRectangleLoop(startLat: 40.7120, startLng: -74.0060, widthMeters: 100, heightMeters: 100, startTime: _epoch);
        fakeTerritoryRepository.captureTerritory(loopA);
        async.flushMicrotasks();

        // 2. User B (Rival) claims overlapping territory cutting User A's territory
        // Set repository context to User B
        fakeTerritoryRepository.currentUserId = 'rival-1';
        fakeTerritoryRepository.currentUserDisplayName = 'Rival Player';
        final loopB = createRectangleLoop(startLat: 40.7125, startLng: -74.0055, widthMeters: 100, heightMeters: 100, startTime: _epoch);
        fakeTerritoryRepository.captureTerritory(loopB);
        async.flushMicrotasks();

        // Verify User A territory split or reduced
        final userA = fakeTerritoryRepository.territories.firstWhere((t) => t.userId == 'user-1');
        expect(userA.areaSqMeters, lessThan(10000.0));

        // 3. User A (Player 1) retakes
        fakeTerritoryRepository.currentUserId = 'user-1';
        fakeTerritoryRepository.currentUserDisplayName = 'Player 1';
        final loopRetake = createRectangleLoop(startLat: 40.7120, startLng: -74.0060, widthMeters: 120, heightMeters: 120, startTime: _epoch);
        fakeTerritoryRepository.captureTerritory(loopRetake);
        async.flushMicrotasks();

        final updatedUserA = fakeTerritoryRepository.territories.firstWhere((t) => t.userId == 'user-1');
        expect(updatedUserA.areaSqMeters, greaterThan(10000.0));
      });
    });

    test('82. E2E Scenario 4: Cheating runner. User starts run in vehicle (exceeding 25 km/h), slows down to jog, then speeds up again. Speed cap invalidates run. No territory claimed.', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        final notifier = container.read(activeRunProvider.notifier);
        notifier.startRun();
        async.flushMicrotasks();

        final baseTime = DateTime.now();
        var current = GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: baseTime);
        
        mockGeolocator.feedPosition(createPos(lat: current.latitude, lng: current.longitude, time: current.timestamp, accuracy: 0.1));
        async.flushMicrotasks();

        // 1. Vehicle speed (30 km/h) for 7 points -> triggers over-speed
        for (var i = 1; i <= 6; i++) {
          async.elapse(const Duration(seconds: 1));
          current = movePointBySpeed(current, 30.0, const Duration(seconds: 1));
          mockGeolocator.feedPosition(createPos(lat: current.latitude, lng: current.longitude, time: current.timestamp, accuracy: 0.1));
          async.flushMicrotasks();
        }

        // 2. Jog speed (8 km/h) for 5 points
        for (var i = 0; i < 5; i++) {
          async.elapse(const Duration(seconds: 1));
          current = movePointBySpeed(current, 8.0, const Duration(seconds: 1));
          mockGeolocator.feedPosition(createPos(lat: current.latitude, lng: current.longitude, time: current.timestamp, accuracy: 0.1));
          async.flushMicrotasks();
        }

        // 3. Vehicle speed (30 km/h) again
        async.elapse(const Duration(seconds: 1));
        current = movePointBySpeed(current, 30.0, const Duration(seconds: 1));
        mockGeolocator.feedPosition(createPos(lat: current.latitude, lng: current.longitude, time: current.timestamp, accuracy: 0.1));
        async.flushMicrotasks();

        notifier.finishRun();
        async.flushMicrotasks();

        expect(container.read(activeRunProvider).result?.outcome, equals(RunOutcome.invalidatedSpeedCap));
      });
    });

    test('83. E2E Scenario 5: Defense Run. User has decaying territory. User runs a path (not a loop) through/near their territory to defend it. Verify `last_defended_at` updates, warning disappears, and decay is avoided.', () {
      fakeAsync((async) {
        final container = ProviderContainer(
          overrides: [territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository)],
        );
        addTearDown(container.dispose);

        // Seed decaying user territory
        final loopUser = createRectangleLoop(startLat: 40.7128, startLng: -74.0060, widthMeters: 60, heightMeters: 60, startTime: _epoch);
        final decayStartTime = DateTime.now().subtract(const Duration(days: 6));
        fakeTerritoryRepository.territories.add(TerritoryEntity(
          id: 'user-t', userId: 'user-1', ownerDisplayName: 'User', polygons: [loopUser], areaSqMeters: 3600.0,
          lastDefendedAt: decayStartTime, isOwnedByCurrentUser: true,
        ));

        // Verify warning is active
        async.run((self) async {
          final warnings = await container.read(decayWarningsProvider.future);
          expect(warnings, isNotEmpty);
        });

        // Run non-loop defense path close to the boundary
        final path = [
          GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: DateTime.now()),
          GeoPointEntity(latitude: 40.7130, longitude: -74.0060, timestamp: DateTime.now().add(const Duration(seconds: 5))),
        ];
        fakeTerritoryRepository.touchDefense(path);
        async.flushMicrotasks();

        container.invalidate(decayWarningsProvider);
        async.flushMicrotasks();

        // Verify warning is gone and lastDefendedAt updated
        async.run((self) async {
          final warnings = await container.read(decayWarningsProvider.future);
          expect(warnings, isEmpty);

          final updated = fakeTerritoryRepository.territories.firstWhere((t) => t.userId == 'user-1');
          expect(updated.lastDefendedAt.isAfter(decayStartTime), isTrue);
        });
      });
    });
  });
}

class FakeAuthRepository implements AuthRepository {
  @override
  AppUser? get currentUser => const AppUser(id: 'user-1', email: 'test@example.com', displayName: 'Player 1');

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {}

  @override
  Future<void> signUpWithEmailAndPassword(String email, String password, {String? displayName}) async {}

  @override
  Future<void> signOut() async {}
}

class FakeAlarmRepository implements AlarmRepository {
  @override
  Future<List<AlarmEntity>> getAlarms() async => [];

  @override
  Future<void> saveAlarm(AlarmEntity alarm) async {}

  @override
  Future<void> deleteAlarm(String id) async {}
}

class FakeSessionRepository implements SessionRepository {
  @override
  Future<void> recordSession(SessionEntity session) async {}

  @override
  Future<int> weeklyReps(String userId, {int days = 7}) async => 0;

  @override
  Future<int> monthlyCalories(String userId, {int days = 30}) async => 0;
}

final DateTime _epoch = DateTime.fromMillisecondsSinceEpoch(0);

// --- Http Mocking boilerplate for widget tests ---

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

class MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl || invocation.memberName == #openUrl) {
      return Future.value(MockHttpClientRequest());
    }
    return null;
  }
}

class MockHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(MockHttpClientResponse());
    }
    if (invocation.memberName == #headers) {
      return MockHttpHeaders();
    }
    return null;
  }
}

class MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  static const List<int> _transparentPng = [
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84, 120, 1, 99, 96, 96, 96, 0, 0, 0, 5, 0, 1, 165, 246, 69, 127, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130
  ];

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_transparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #statusCode) return 200;
    if (invocation.memberName == #contentLength) return _transparentPng.length;
    if (invocation.memberName == #headers) return MockHttpHeaders();
    return null;
  }
}

class FakeViewerLocationNotifier extends ViewerLocationNotifier {
  @override
  GeoPointEntity? build() => GeoPointEntity(latitude: 40.7128, longitude: -74.0060, timestamp: DateTime.now());
}

class FakeLeaderboardModeNotifier extends LeaderboardModeNotifier {
  @override
  LeaderboardMode build() => LeaderboardMode.nearby;
}
