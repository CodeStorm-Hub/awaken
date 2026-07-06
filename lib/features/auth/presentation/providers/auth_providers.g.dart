// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authRepositoryHash() => r'ae2a9c7c4226836cd659c3ec8f6f8a02a8913d3b';

/// See also [authRepository].
@ProviderFor(authRepository)
final authRepositoryProvider = Provider<AuthRepository>.internal(
  authRepository,
  name: r'authRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthRepositoryRef = ProviderRef<AuthRepository>;
String _$authStateHash() => r'f2fa688c93779efa15fbb59d8bbfd70439794450';

/// Streams every auth state change from Supabase (sign in / sign out / refresh).
///
/// Copied from [authState].
@ProviderFor(authState)
final authStateProvider = StreamProvider<AuthState>.internal(
  authState,
  name: r'authStateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthStateRef = StreamProviderRef<AuthState>;
String _$isSignedInHash() => r'8873747d0a2eac2819c4368dcd7efbbe3eda8f98';

/// See also [isSignedIn].
@ProviderFor(isSignedIn)
final isSignedInProvider = Provider<bool>.internal(
  isSignedIn,
  name: r'isSignedInProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isSignedInHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsSignedInRef = ProviderRef<bool>;
String _$currentUserHash() => r'820d7b3df79ce9a4c3c0522e39c9433ffbd8358b';

/// The currently signed-in user, or null when not authenticated.
///
/// Copied from [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = Provider<AppUser?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = ProviderRef<AppUser?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
