import 'package:awaken/features/territory/data/datasources/active_run_checkpoint_store.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/presentation/providers/active_run_providers.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks/fake_territory_repository.dart';
import 'mocks/mock_geolocator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGeolocatorPlatform mockGeolocator;
  late FakeTerritoryRepository fakeRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockGeolocator = MockGeolocatorPlatform();
    GeolocatorPlatform.instance = mockGeolocator;
    fakeRepo = FakeTerritoryRepository();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'initialize' ||
                methodCall.method == 'requestNotificationsPermission' ||
                methodCall.method == 'requestExactAlarmsPermission') {
              return true;
            }
            return null;
          },
        );
  });

  tearDown(() {
    fakeRepo.close();
  });

  test('restoreFromCheckpoint resumes a killed tracking session', () async {
    final start = DateTime.utc(2026, 7, 11, 10, 0, 0);
    const store = ActiveRunCheckpointStore();
    await store.save(
      ActiveRunCheckpoint(
        statusName: 'tracking',
        points: [
          GeoPointEntity(latitude: 43.65, longitude: -79.38, timestamp: start),
        ],
        distanceMeters: 0,
        elapsed: const Duration(minutes: 3),
        startTime: start,
        pausedAccumulated: Duration.zero,
        sawSustainedOverSpeed: false,
        pendingLoops: const [],
        currentSegmentAnchorIndex: 0,
        loopTrackerAnchorIndex: 0,
        loopTrackerMaxDistFromAnchor: 0,
        loopTrackerClosureArmed: false,
        gpsAccuracyMeters: 5,
      ),
    );

    final container = ProviderContainer(
      overrides: [territoryRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(() {
      container.read(activeRunProvider.notifier).reset();
      container.dispose();
    });

    // Trigger build (schedules restore microtask) then run restore explicitly
    // so the test does not race the microtask.
    container.read(activeRunProvider);
    await container.read(activeRunProvider.notifier).restoreFromCheckpoint();

    final state = container.read(activeRunProvider);
    expect(state.status, RunSessionStatus.tracking);
    expect(state.points, hasLength(1));
    expect(state.elapsed, const Duration(minutes: 3));
    expect(state.gpsAccuracyMeters, 5);
  });

  test('startRun persists a resumable checkpoint', () async {
    final container = ProviderContainer(
      overrides: [territoryRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(() {
      container.read(activeRunProvider.notifier).reset();
      container.dispose();
    });

    final notifier = container.read(activeRunProvider.notifier);
    // Skip auto-restore from empty prefs.
    await notifier.restoreFromCheckpoint();
    await notifier.startRun();

    expect(container.read(activeRunProvider).status, RunSessionStatus.tracking);

    final checkpoint = await const ActiveRunCheckpointStore().load();
    expect(checkpoint, isNotNull);
    expect(checkpoint!.statusName, 'tracking');
    expect(checkpoint.isResumable, isTrue);
  });

  test('reset clears the durable checkpoint', () async {
    final container = ProviderContainer(
      overrides: [territoryRepositoryProvider.overrideWithValue(fakeRepo)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(activeRunProvider.notifier);
    await notifier.restoreFromCheckpoint();
    await notifier.startRun();
    expect(await const ActiveRunCheckpointStore().load(), isNotNull);

    notifier.reset();
    await Future<void>.delayed(Duration.zero);

    expect(await const ActiveRunCheckpointStore().load(), isNull);
  });
}
