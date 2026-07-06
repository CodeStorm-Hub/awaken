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
String _$territoryListHash() => r'c22be22bf6f2548d9982f219944ee81319187cbb';

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
String _$myLocationHash() => r'c4487b70092cc53d88347655d9060452f9571e8e';

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
    r'2a71ea9ee9efc592497f6ac99c93277935f4d9ba';

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
    r'6c3ecbbe4441420463b7c9c16000a36bb56ab727';

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
    r'59820c2606dcb75843e0d8b434ede84e019778cd';

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
    r'78e6549bd6d71929252f5db78dee746614341fbe';

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
    r'c56d218fea7cfdf52de920c55348b914136a5bb7';

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
String _$mapEngineNotifierHash() => r'f94be632b4c3ba48083c157caa52e6b0eb892b42';

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
    r'16d41326a66237d433dca27357b4321442f150ce';

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
