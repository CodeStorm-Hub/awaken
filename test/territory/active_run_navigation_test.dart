import 'dart:io';

import 'package:awaken/app.dart';
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
import 'package:awaken/features/territory/presentation/providers/active_run_providers.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;

import 'helpers/territory_widget_test_helpers.dart';
import 'mocks/fake_territory_repository.dart';
import 'mocks/mock_geolocator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGeolocatorPlatform mockGeolocator;
  late FakeTerritoryRepository fakeRepo;
  late ProviderContainer container;

  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (MethodCall methodCall) {
        if (methodCall.method == 'initialize' || methodCall.method == 'show') {
          return Future<bool>.value(true);
        }
        return Future<dynamic>.value(null);
      },
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/geolocator'),
      (MethodCall methodCall) {
        if (methodCall.method == 'isLocationServiceEnabled') {
          return Future<bool>.value(true);
        }
        if (methodCall.method == 'checkPermission' ||
            methodCall.method == 'requestPermission') {
          return Future<int>.value(3);
        }
        return Future<dynamic>.value(null);
      },
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockGeolocator = MockGeolocatorPlatform();
    mockGeolocator.feedPosition(
      Position(
        latitude: 43.65,
        longitude: -79.38,
        timestamp: DateTime.utc(2026, 1, 1),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 1.5,
        speedAccuracy: 0,
      ),
    );
    GeolocatorPlatform.instance = mockGeolocator;
    fakeRepo = FakeTerritoryRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        authStateProvider.overrideWith((ref) => signedOutAuthStateStream()),
        isSignedInProvider.overrideWith((ref) => true),
        currentUserProvider.overrideWith(
          (ref) => const AppUser(
            id: 'user-1',
            email: 'test@example.com',
            displayName: 'Runner',
          ),
        ),
        alarmRepositoryProvider.overrideWithValue(_FakeAlarmRepository()),
        sessionRepositoryProvider.overrideWithValue(_FakeSessionRepository()),
        territoryRepositoryProvider.overrideWithValue(fakeRepo),
        clockDisplayProvider.overrideWith((ref) => Stream.value('08:00')),
      ],
    );
  });

  tearDown(() {
    // Cancel the 1s tick timer from any in-flight run so widget tests
    // don't fail with "A Timer is still pending".
    container.read(activeRunProvider.notifier).reset();
    container.dispose();
    fakeRepo.close();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AwakenApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> startRunFromTerritoryTab(WidgetTester tester) async {
    await tester.tap(find.text('TERRITORY'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Start run'), findsOneWidget);
    await tester.tap(find.text('Start run'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(container.read(activeRunProvider).status, RunSessionStatus.tracking);
    expect(find.text('Stop'), findsOneWidget);
  }

  group('active run survives navigation', () {
    testWidgets(
      'switching tabs mid-run does not discard and keeps tracking',
      (WidgetTester tester) async {
        await pumpApp(tester);
        await startRunFromTerritoryTab(tester);

        await tester.tap(find.text('HOME'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Discard this run?'), findsNothing);
        expect(
          container.read(activeRunProvider).status,
          RunSessionStatus.tracking,
        );
        expect(find.text('AWAKEN'), findsOneWidget);

        await tester.tap(find.text('TERRITORY'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          container.read(activeRunProvider).status,
          RunSessionStatus.tracking,
        );
        expect(find.text('Stop'), findsOneWidget);
        expect(find.text('Start run'), findsNothing);

        // Cancel tick timer before widget-test invariant check.
        container.read(activeRunProvider.notifier).reset();
      },
    );

    testWidgets(
      'back arrow mid-run leaves territory without discarding',
      (WidgetTester tester) async {
        await pumpApp(tester);
        await startRunFromTerritoryTab(tester);

        await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Discard this run?'), findsNothing);
        expect(
          container.read(activeRunProvider).status,
          RunSessionStatus.tracking,
        );
        expect(find.text('AWAKEN'), findsOneWidget);

        await tester.tap(find.text('TERRITORY'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Stop'), findsOneWidget);

        container.read(activeRunProvider.notifier).reset();
      },
    );

    testWidgets(
      'Stop is what ends the run after navigating away and back',
      (WidgetTester tester) async {
        await pumpApp(tester);
        await startRunFromTerritoryTab(tester);

        await tester.tap(find.text('RANKS'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          container.read(activeRunProvider).status,
          RunSessionStatus.tracking,
        );

        await tester.tap(find.text('TERRITORY'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.text('Stop'));
        await tester.pump();
        // finishRun is async (checkpoint clear + classify + record).
        await tester.pump(const Duration(milliseconds: 500));

        expect(
          container.read(activeRunProvider).status,
          isNot(RunSessionStatus.tracking),
        );
      },
    );
  });
}

class _FakeAuthRepository implements AuthRepository {
  @override
  AppUser? get currentUser =>
      const AppUser(id: 'user-1', email: 'test@example.com', displayName: 'Runner');

  @override
  Stream<AuthState> get authStateChanges => signedOutAuthStateStream();

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {}

  @override
  Future<void> signUpWithEmailAndPassword(
    String email,
    String password, {
    String? displayName,
  }) async {}

  @override
  Future<void> signOut() async {}
}

class _FakeAlarmRepository implements AlarmRepository {
  @override
  Future<List<AlarmEntity>> getAlarms() async => [];

  @override
  Future<void> saveAlarm(AlarmEntity alarm) async {}

  @override
  Future<void> deleteAlarm(String id) async {}
}

class _FakeSessionRepository implements SessionRepository {
  @override
  Future<void> recordSession(SessionEntity session) async {}

  @override
  Future<int> weeklyReps(String userId, {int days = 7}) async => 0;

  @override
  Future<int> monthlyCalories(String userId, {int days = 30}) async => 0;

  @override
  Future<({int current, int best})> streakStats(String userId) async =>
      (current: 0, best: 0);
}
