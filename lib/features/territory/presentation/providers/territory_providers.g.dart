// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'territory_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$territoryRepositoryHash() =>
    r'072c77d83aab8153aec7a46f0a33dda07cba3455';

/// Picks the correct repository based on auth state:
///   - Signed in  → Supabase (cloud-synced)
///   - Signed out → SharedPreferences (local-only)
///
/// Copied from [territoryRepository].
@ProviderFor(territoryRepository)
final territoryRepositoryProvider = Provider<TerritoryRepository>.internal(
  territoryRepository,
  name: r'territoryRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$territoryRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TerritoryRepositoryRef = ProviderRef<TerritoryRepository>;
String _$territoryListHash() => r'e984f48bc36c15fda346f948c63c5d0c4f4ad203';

/// Live view of the shared map — every player's territory, updated via
/// Supabase Realtime whenever any capture/steal/decay touches the table.
/// Deferred until [territoryMapReadyProvider] is true so startup and other
/// shell tabs do not open the Realtime subscription.
///
/// Copied from [territoryList].
@ProviderFor(territoryList)
final territoryListProvider = StreamProvider<List<TerritoryEntity>>.internal(
  territoryList,
  name: r'territoryListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$territoryListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TerritoryListRef = StreamProviderRef<List<TerritoryEntity>>;
String _$leaderboardHash() => r'257449706127759e6c80d2270149ceb6572fee67';

/// See also [leaderboard].
@ProviderFor(leaderboard)
final leaderboardProvider =
    AutoDisposeFutureProvider<List<LeaderboardEntryEntity>>.internal(
      leaderboard,
      name: r'leaderboardProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$leaderboardHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LeaderboardRef =
    AutoDisposeFutureProviderRef<List<LeaderboardEntryEntity>>;
String _$decayWarningsHash() => r'e8b438d4d6707fd22fc46e35c0503540cae83b46';

/// See also [decayWarnings].
@ProviderFor(decayWarnings)
final decayWarningsProvider =
    AutoDisposeFutureProvider<List<DecayWarningEntity>>.internal(
      decayWarnings,
      name: r'decayWarningsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$decayWarningsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DecayWarningsRef =
    AutoDisposeFutureProviderRef<List<DecayWarningEntity>>;
String _$territoryMapStyleHash() => r'b0bae61edd5116d9cd4dc88257250bb94a88a2c3';

/// Loads and caches Awaken's branded OpenFreeMap vector style once per app session.
///
/// Copied from [territoryMapStyle].
@ProviderFor(territoryMapStyle)
final territoryMapStyleProvider = FutureProvider<Style>.internal(
  territoryMapStyle,
  name: r'territoryMapStyleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$territoryMapStyleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TerritoryMapStyleRef = FutureProviderRef<Style>;
String _$myLocationHash() => r'4a8354c52ccc931bafed4cce76f21e9103d28cd6';

/// Continuous "blue dot" GPS feed for the map's live-position marker.
///
/// Copied from [myLocation].
@ProviderFor(myLocation)
final myLocationProvider = AutoDisposeStreamProvider<Position?>.internal(
  myLocation,
  name: r'myLocationProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myLocationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyLocationRef = AutoDisposeStreamProviderRef<Position?>;
String _$leaderboardModeNotifierHash() =>
    r'1ed5920c6c4cfd974b181b70c10a99d1ff640b9d';

/// Defaults to "Nearby" per the product decision.
///
/// Copied from [LeaderboardModeNotifier].
@ProviderFor(LeaderboardModeNotifier)
final leaderboardModeNotifierProvider =
    AutoDisposeNotifierProvider<
      LeaderboardModeNotifier,
      LeaderboardMode
    >.internal(
      LeaderboardModeNotifier.new,
      name: r'leaderboardModeNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$leaderboardModeNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LeaderboardModeNotifier = AutoDisposeNotifier<LeaderboardMode>;
String _$leaderboardWindowNotifierHash() =>
    r'932581e77b9be62aee9840c06c03f3c69f7d5459';

/// Defaults to all-time (current ownership).
///
/// Copied from [LeaderboardWindowNotifier].
@ProviderFor(LeaderboardWindowNotifier)
final leaderboardWindowNotifierProvider =
    AutoDisposeNotifierProvider<
      LeaderboardWindowNotifier,
      LeaderboardWindow
    >.internal(
      LeaderboardWindowNotifier.new,
      name: r'leaderboardWindowNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$leaderboardWindowNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$LeaderboardWindowNotifier = AutoDisposeNotifier<LeaderboardWindow>;
String _$viewerLocationNotifierHash() =>
    r'913c432fa2b93dbbc294beafff168f21525b8aac';

/// The viewer's current position, used only to scope the "Nearby" leaderboard.
///
/// Copied from [ViewerLocationNotifier].
@ProviderFor(ViewerLocationNotifier)
final viewerLocationNotifierProvider =
    AutoDisposeNotifierProvider<
      ViewerLocationNotifier,
      GeoPointEntity?
    >.internal(
      ViewerLocationNotifier.new,
      name: r'viewerLocationNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$viewerLocationNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ViewerLocationNotifier = AutoDisposeNotifier<GeoPointEntity?>;
String _$territoryMapReadyNotifierHash() =>
    r'c99e68c5a854e40477b9e7fc0d64df80ddec2b6b';

/// Set to `true` the first time [TerritoryRunScreen] mounts.
///
/// Copied from [TerritoryMapReadyNotifier].
@ProviderFor(TerritoryMapReadyNotifier)
final territoryMapReadyNotifierProvider =
    AutoDisposeNotifierProvider<TerritoryMapReadyNotifier, bool>.internal(
      TerritoryMapReadyNotifier.new,
      name: r'territoryMapReadyNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$territoryMapReadyNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TerritoryMapReadyNotifier = AutoDisposeNotifier<bool>;
String _$mapLastKnownPositionNotifierHash() =>
    r'ca8bcd1b6084e20fdb9cd7878e2deca297de10fe';

/// Last known GPS fix for the idle map marker.
///
/// Copied from [MapLastKnownPositionNotifier].
@ProviderFor(MapLastKnownPositionNotifier)
final mapLastKnownPositionNotifierProvider =
    AutoDisposeNotifierProvider<
      MapLastKnownPositionNotifier,
      Position?
    >.internal(
      MapLastKnownPositionNotifier.new,
      name: r'mapLastKnownPositionNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$mapLastKnownPositionNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MapLastKnownPositionNotifier = AutoDisposeNotifier<Position?>;
String _$mapEngineNotifierHash() => r'a0a7d4ef2f0f130b84efd00d98f37701cc71466c';

/// See also [MapEngineNotifier].
@ProviderFor(MapEngineNotifier)
final mapEngineNotifierProvider =
    AutoDisposeNotifierProvider<MapEngineNotifier, MapEngine>.internal(
      MapEngineNotifier.new,
      name: r'mapEngineNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$mapEngineNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MapEngineNotifier = AutoDisposeNotifier<MapEngine>;
String _$territoryMapFocusNotifierHash() =>
    r'db22237a7596fec3789201ac0b5261354a6e5fc5';

/// Set by the leaderboard's "tap to locate" action.
///
/// Copied from [TerritoryMapFocusNotifier].
@ProviderFor(TerritoryMapFocusNotifier)
final territoryMapFocusNotifierProvider =
    AutoDisposeNotifierProvider<TerritoryMapFocusNotifier, LatLng?>.internal(
      TerritoryMapFocusNotifier.new,
      name: r'territoryMapFocusNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$territoryMapFocusNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TerritoryMapFocusNotifier = AutoDisposeNotifier<LatLng?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
