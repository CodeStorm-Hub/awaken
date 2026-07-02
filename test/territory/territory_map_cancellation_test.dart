import 'dart:async';
import 'dart:io';

import 'package:awaken/app.dart';
import 'package:awaken/core/utils/expected_async_cancellation.dart';
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
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:executor_lib/executor_lib.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthState;

import 'helpers/territory_widget_test_helpers.dart';
import 'mocks/fake_territory_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('isExpectedAsyncCancellation', () {
    test('matches executor_lib CancellationException with Cancelled message', () {
      expect(isExpectedAsyncCancellation(CancellationException()), isTrue);
    });

    test('rejects other exceptions even when message is Cancelled', () {
      expect(isExpectedAsyncCancellation(Exception('Cancelled')), isFalse);
      expect(isExpectedAsyncCancellation(StateError('Network failed')), isFalse);
    });
  });

  group('installExpectedAsyncCancellationHandlers', () {
    test('swallows CancellationException in FlutterError.onError', () {
      FlutterErrorDetails? forwarded;
      FlutterError.onError = (details) => forwarded = details;

      installExpectedAsyncCancellationHandlers();

      FlutterError.reportError(
        FlutterErrorDetails(
          exception: CancellationException(),
          library: 'test',
        ),
      );

      expect(forwarded, isNull);
    });

    test('forwards non-cancellation errors', () {
      FlutterErrorDetails? forwarded;
      FlutterError.onError = (details) => forwarded = details;

      installExpectedAsyncCancellationHandlers();

      FlutterError.reportError(
        FlutterErrorDetails(
          exception: StateError('real failure'),
          library: 'test',
        ),
      );

      expect(forwarded, isNotNull);
      expect(forwarded!.exception, isA<StateError>());
    });
  });

  group('territory tab navigation', () {
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

    testWidgets(
      'switching shell tabs does not report tile CancellationException',
      (WidgetTester tester) async {
        final tileCancellations = <FlutterErrorDetails>[];
        final priorFlutterOnError = FlutterError.onError;
        FlutterError.onError = (FlutterErrorDetails details) {
          if (isExpectedAsyncCancellation(details.exception)) {
            tileCancellations.add(details);
            return;
          }
          priorFlutterOnError?.call(details);
        };
        addTearDown(() => FlutterError.onError = priorFlutterOnError);

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
        await tester.pump(const Duration(seconds: 2));

        await tester.tap(find.byIcon(Icons.leaderboard_rounded));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        await tester.tap(find.text('TERRITORY'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        await tester.tap(find.byIcon(Icons.home_rounded));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        await tester.tap(find.text('TERRITORY'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(tileCancellations, isEmpty);

        fakeRepo.close();
      },
    );
  });
}

class FakeAuthRepository implements AuthRepository {
  @override
  AppUser? get currentUser =>
      const AppUser(id: 'user-1', email: 'test@example.com', displayName: 'Player 1');

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
