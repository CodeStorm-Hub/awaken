// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(authRepository)
final authRepositoryProvider = AuthRepositoryProvider._();

final class AuthRepositoryProvider
    extends $FunctionalProvider<AuthRepository, AuthRepository, AuthRepository>
    with $Provider<AuthRepository> {
  AuthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authRepositoryHash();

  @$internal
  @override
  $ProviderElement<AuthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuthRepository create(Ref ref) {
    return authRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthRepository>(value),
    );
  }
}

String _$authRepositoryHash() => r'6ef7ec0f4b807a3cb431d36a0c89e726eada3f3a';

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

@ProviderFor(AuthStateNotifier)
final authStateProvider = AuthStateNotifierProvider._();

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
final class AuthStateNotifierProvider
    extends $AsyncNotifierProvider<AuthStateNotifier, AuthState> {
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
  AuthStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authStateNotifierHash();

  @$internal
  @override
  AuthStateNotifier create() => AuthStateNotifier();
}

String _$authStateNotifierHash() => r'2e8064bc629227e8391c09cc6d56d929f228adbf';

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

abstract class _$AuthStateNotifier extends $AsyncNotifier<AuthState> {
  FutureOr<AuthState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AuthState>, AuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AuthState>, AuthState>,
              AsyncValue<AuthState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(isSignedIn)
final isSignedInProvider = IsSignedInProvider._();

final class IsSignedInProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  IsSignedInProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isSignedInProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isSignedInHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return isSignedIn(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$isSignedInHash() => r'4f80f133cd0ff9c82671d4bf59501b719a2a2236';

/// The currently signed-in user, or null when not authenticated.

@ProviderFor(currentUser)
final currentUserProvider = CurrentUserProvider._();

/// The currently signed-in user, or null when not authenticated.

final class CurrentUserProvider
    extends $FunctionalProvider<AppUser?, AppUser?, AppUser?>
    with $Provider<AppUser?> {
  /// The currently signed-in user, or null when not authenticated.
  CurrentUserProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentUserProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentUserHash();

  @$internal
  @override
  $ProviderElement<AppUser?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppUser? create(Ref ref) {
    return currentUser(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppUser? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppUser?>(value),
    );
  }
}

String _$currentUserHash() => r'd081c1b0f525dba4c169264bd85598dd3174e3aa';
