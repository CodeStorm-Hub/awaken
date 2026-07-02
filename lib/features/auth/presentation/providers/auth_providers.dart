import 'package:awaken/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:awaken/features/auth/domain/entities/app_user.dart';
import 'package:awaken/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

/// Streams every auth state change from Supabase (sign in / sign out / refresh).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});

/// True when a valid Supabase session exists.
///
/// While [authStateProvider] is still loading its first event, fall back to
/// the synchronously-restored session from [Supabase.initialize] so repo
/// switching (alarms, territory) doesn't briefly route signed-in users to
/// the offline/local implementation on cold start.
final isSignedInProvider = Provider<bool>((ref) {
  final authAsync = ref.watch(authStateProvider);
  return authAsync.when(
    data: (state) => state.session != null,
    loading: () => Supabase.instance.client.auth.currentSession != null,
    error: (_, _) => Supabase.instance.client.auth.currentSession != null,
  );
});

/// The currently signed-in user, or null when not authenticated.
final currentUserProvider = Provider<AppUser?>((ref) {
  // Re-derive any time auth state changes
  ref.watch(authStateProvider);
  return ref.read(authRepositoryProvider).currentUser;
});
