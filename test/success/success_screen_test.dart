import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:awaken/features/alarm/domain/repositories/alarm_repository.dart';
import 'package:awaken/features/alarm/presentation/providers/alarm_schedule_providers.dart';
import 'package:awaken/features/auth/domain/entities/app_user.dart';
import 'package:awaken/features/auth/domain/repositories/auth_repository.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:awaken/features/sessions/domain/entities/session_entity.dart';
import 'package:awaken/features/sessions/domain/repositories/session_repository.dart';
import 'package:awaken/features/sessions/presentation/providers/session_providers.dart';
import 'package:awaken/features/success/presentation/screens/success_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _RecordingSessionRepository implements SessionRepository {
  final List<SessionEntity> recorded = [];

  @override
  Future<void> recordSession(SessionEntity session) async {
    recorded.add(session);
  }

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

class _RecordingAlarmRepository implements AlarmRepository {
  final List<AlarmEntity> saved = [];

  @override
  Future<List<AlarmEntity>> getAlarms() async => List.of(saved);

  @override
  Future<void> saveAlarm(AlarmEntity alarm) async {
    saved.removeWhere((a) => a.id == alarm.id);
    saved.add(alarm);
  }

  @override
  Future<void> deleteAlarm(String id) async {
    saved.removeWhere((a) => a.id == id);
  }
}

class _GuestAuthRepository implements AuthRepository {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final alarm = AlarmEntity(
    id: 'alarm-1',
    scheduledTime: DateTime(2026, 7, 11, 7, 0),
    requiredReps: 10,
    isActive: true,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('success route builder forwards AlarmEntity extra to SuccessScreen', () {
    // Mirrors lib/core/router/app_router.dart success route builder.
    Object? extra = alarm;
    final screen = SuccessScreen(alarm: extra is AlarmEntity ? extra : null);
    expect(screen.alarm?.id, 'alarm-1');

    extra = null;
    final missing = SuccessScreen(alarm: extra is AlarmEntity ? extra : null);
    expect(missing.alarm, isNull);
    expect(AppRoutes.success, '/alarm/success');
  });

  test(
    'success route builder forwards SuccessScreenArgs stats explicitly, '
    'independent of live provider state',
    () {
      // Mirrors lib/core/router/app_router.dart success route builder: a
      // SuccessScreenArgs extra must carry reps/duration/accessibility
      // through untouched, so the screen never has to fall back to reading
      // repCountProvider/sessionStartTimeProvider (which may already be
      // reset/disposed by the time SuccessScreen builds).
      const args = SuccessScreenArgs(
        alarm: null,
        repsCompleted: 12,
        durationSeconds: 47,
        usedAccessibilityMode: true,
      );
      Object? extra = args;

      SuccessScreen screen;
      if (extra is SuccessScreenArgs) {
        screen = SuccessScreen(
          alarm: extra.alarm,
          repsCompleted: extra.repsCompleted,
          durationSeconds: extra.durationSeconds,
          usedAccessibilityMode: extra.usedAccessibilityMode,
        );
      } else {
        screen = SuccessScreen(alarm: extra is AlarmEntity ? extra : null);
      }

      expect(screen.repsCompleted, 12);
      expect(screen.durationSeconds, 47);
      expect(screen.usedAccessibilityMode, isTrue);
    },
  );

  test('guest workout records locally and deactivates alarm', () async {
    final sessions = _RecordingSessionRepository();
    final alarms = _RecordingAlarmRepository()..saved.add(alarm);

    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(_GuestAuthRepository()),
        isSignedInProvider.overrideWithValue(false),
        currentUserProvider.overrideWithValue(null),
        sessionRepositoryProvider.overrideWithValue(sessions),
        alarmRepositoryProvider.overrideWithValue(alarms),
      ],
    );
    addTearDown(container.dispose);

    // Same persistence order as SuccessScreen._recordSession.
    const userId = SessionEntity.localGuestUserId;
    await container
        .read(sessionRepositoryProvider)
        .recordSession(
          SessionEntity(
            userId: userId,
            alarmId: alarm.id,
            completedAt: DateTime.now(),
            repsCompleted: 10,
            durationSeconds: 45,
            caloriesBurned: SessionEntity.estimateCalories(10),
          ),
        );
    await container.read(alarmListProvider.notifier).markCompleted(alarm);

    expect(sessions.recorded, hasLength(1));
    expect(sessions.recorded.single.userId, SessionEntity.localGuestUserId);
    expect(sessions.recorded.single.alarmId, alarm.id);
    expect(alarms.saved.single.isActive, isFalse);
  });
}
