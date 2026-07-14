import 'package:awaken/core/theme/app_theme.dart';
import 'package:awaken/features/auth/domain/entities/app_user.dart';
import 'package:awaken/features/auth/domain/repositories/auth_repository.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:awaken/features/auth/presentation/screens/profile_screen.dart';
import 'package:awaken/features/dashboard/domain/entities/dashboard_stats_entity.dart';
import 'package:awaken/features/dashboard/presentation/providers/dashboard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.user});
  final AppUser? user;

  @override
  AppUser? get currentUser => user;

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
  const testStats = DashboardStatsEntity(
    currentStreak: 5,
    bestStreak: 10,
    weeklyReps: 150,
    monthlyCalories: 300,
    nextAlarm: null,
    nextAlarmReps: 10,
  );

  testWidgets('renders Guest mode when not signed in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(user: null),
          ),
          isSignedInProvider.overrideWithValue(false),
          currentUserProvider.overrideWithValue(null),
          dashboardStatsProvider.overrideWith((ref) => testStats),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const ProfileScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Guest mode UI components
    expect(find.text('Guest User'), findsOneWidget);
    expect(find.text('Local offline profile'), findsOneWidget);
    expect(find.text('LOCAL STORAGE ONLY'), findsOneWidget);
    expect(find.text('CONNECT GOOGLE ACCOUNT'), findsOneWidget);

    // Verify stats recap
    expect(find.text('5'), findsOneWidget); // current streak
    expect(find.text('10'), findsOneWidget); // best streak
    expect(find.text('150'), findsOneWidget); // weekly squats
    expect(find.text('300'), findsOneWidget); // monthly energy calories
  });

  testWidgets('renders authenticated profile details when signed in', (
    WidgetTester tester,
  ) async {
    const testUser = AppUser(
      id: 'abc-123',
      email: 'alex@example.com',
      displayName: 'Alex Smith',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(user: testUser),
          ),
          isSignedInProvider.overrideWithValue(true),
          currentUserProvider.overrideWithValue(testUser),
          dashboardStatsProvider.overrideWith((ref) => testStats),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const ProfileScreen()),
      ),
    );

    await tester.pumpAndSettle();

    // Verify signed-in mode UI components
    expect(find.text('Alex Smith'), findsOneWidget);
    expect(find.text('alex@example.com'), findsOneWidget);
    expect(find.text('CLOUD SYNCHRONIZED'), findsOneWidget);
    expect(find.text('SIGN OUT OF ACCOUNT'), findsOneWidget);
    expect(find.text('CONNECT GOOGLE ACCOUNT'), findsNothing);

    // Verify stats recap is still visible
    expect(find.text('5'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('150'), findsOneWidget);
    expect(find.text('300'), findsOneWidget);
  });
}
