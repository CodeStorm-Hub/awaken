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
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  AppUser? get currentUser => null;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {}

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

  @override
  Future<({int current, int best})> streakStats(String userId) async =>
      (current: 0, best: 0);

  @override
  Future<List<int>> weeklyRepsTrend(String userId, {int weeks = 4}) async =>
      List.filled(weeks, 0);
}

void main() {
  testWidgets('Awaken App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          alarmRepositoryProvider.overrideWithValue(FakeAlarmRepository()),
          sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
          clockDisplayProvider.overrideWith((ref) => Stream.value('08:00')),
        ],
        child: const AwakenApp(),
      ),
    );

    // Verify that the title 'AWAKEN' exists.
    expect(find.text('AWAKEN'), findsOneWidget);
  });
}
