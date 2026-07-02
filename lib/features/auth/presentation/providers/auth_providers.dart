import 'package:awaken/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:awaken/features/auth/domain/entities/app_user.dart';
import 'package:awaken/features/auth/domain/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(AuthRepositoryRef ref) {
  return SupabaseAuthRepository();
}

/// Streams every auth state change from Supabase (sign in / sign out / refresh).
@Riverpod(keepAlive: true)
Stream<AuthState> authState(AuthStateRef ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
}

/// True when a valid Supabase session exists.
///
/// While [authStateProvider] is still loading its first event, fall back to
/// the synchronously-restored session from [Supabase.initialize] so repo
/// switching (alarms, territory) doesn't briefly route signed-in users to
/// the offline/local implementation on cold start.
bool _hasSupabaseSession() {
  try {
    return Supabase.instance.client.auth.currentSession != null;
  } on Object {
    return false;
  }
}

@Riverpod(keepAlive: true)
bool isSignedIn(IsSignedInRef ref) {
  final authAsync = ref.watch(authStateProvider);
  return authAsync.when(
    data: (state) => state.session != null,
    loading: _hasSupabaseSession,
    error: (_, _) => _hasSupabaseSession(),
  );
}

/// The currently signed-in user, or null when not authenticated.
@Riverpod(keepAlive: true)
AppUser? currentUser(CurrentUserRef ref) {
  // Re-derive any time auth state changes
  ref.watch(authStateProvider);
  return ref.read(authRepositoryProvider).currentUser;
}
