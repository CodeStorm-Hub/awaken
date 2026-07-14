import 'dart:async';

import 'package:awaken/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:awaken/features/auth/domain/entities/app_user.dart';
import 'package:awaken/features/auth/domain/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_providers.g.dart';

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) {
  return SupabaseAuthRepository();
}

/// Every auth state change from Supabase (sign in / sign out / refresh),
/// exposed as `AsyncValue<AuthState>` — same shape a plain `Stream<AuthState>`
/// provider would give, but with the subscription managed by hand instead of
/// through Riverpod's built-in `StreamNotifier`.
///
/// Riverpod 3's `StreamProvider`/`Stream<T> build()` machinery auto-pauses
/// and resumes its subscription based on `TickerMode`. On Android, the
/// transient system UI overlay from Google Sign-In's Credential Manager
/// account picker can toggle `TickerMode` mid-frame, and the resume path
/// synchronously calls `invalidateSelf()` — tripping a `setState() during
/// build` framework violation on every toggle (caught by Riverpod's own
/// error zone, but the repeated exceptions cause visible jank). This is an
/// open upstream bug: https://github.com/rrousselGit/riverpod/issues/4381
/// (still unresolved as of riverpod 3.3.2). A manually-managed subscription
/// inside an `AsyncNotifier.build()` isn't subject to that auto-pause
/// behavior at all, sidestepping the issue entirely.
@Riverpod(keepAlive: true)
class AuthStateNotifier extends _$AuthStateNotifier {
  StreamSubscription<AuthState>? _sub;

  @override
  Future<AuthState> build() {
    final repo = ref.watch(authRepositoryProvider);
    final firstEvent = Completer<AuthState>();
    var gotFirstEvent = false;

    _sub = repo.authStateChanges.listen(
      (event) {
        if (!gotFirstEvent) {
          gotFirstEvent = true;
          firstEvent.complete(event);
        } else {
          state = AsyncData(event);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!gotFirstEvent) {
          gotFirstEvent = true;
          firstEvent.completeError(error, stackTrace);
        } else {
          state = AsyncError(error, stackTrace);
        }
      },
    );
    ref.onDispose(() => _sub?.cancel());

    return firstEvent.future;
  }
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
bool isSignedIn(Ref ref) {
  final authAsync = ref.watch(authStateProvider);
  return authAsync.when(
    data: (state) => state.session != null,
    loading: _hasSupabaseSession,
    error: (_, _) => _hasSupabaseSession(),
  );
}

/// The currently signed-in user, or null when not authenticated.
@Riverpod(keepAlive: true)
AppUser? currentUser(Ref ref) {
  // Re-derive any time auth state changes
  ref.watch(authStateProvider);
  return ref.read(authRepositoryProvider).currentUser;
}
