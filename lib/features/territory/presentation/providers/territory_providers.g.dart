// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'territory_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Picks the correct repository based on auth state:
///   - Signed in  → Supabase (cloud-synced)
///   - Signed out → SharedPreferences (local-only)

@ProviderFor(territoryRepository)
final territoryRepositoryProvider = TerritoryRepositoryProvider._();

/// Picks the correct repository based on auth state:
///   - Signed in  → Supabase (cloud-synced)
///   - Signed out → SharedPreferences (local-only)

final class TerritoryRepositoryProvider
    extends
        $FunctionalProvider<
          TerritoryRepository,
          TerritoryRepository,
          TerritoryRepository
        >
    with $Provider<TerritoryRepository> {
  /// Picks the correct repository based on auth state:
  ///   - Signed in  → Supabase (cloud-synced)
  ///   - Signed out → SharedPreferences (local-only)
  TerritoryRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'territoryRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$territoryRepositoryHash();

  @$internal
  @override
  $ProviderElement<TerritoryRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TerritoryRepository create(Ref ref) {
    return territoryRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TerritoryRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TerritoryRepository>(value),
    );
  }
}

String _$territoryRepositoryHash() =>
    r'f275efd11bc1f95d4ea47cab27bf7fc702bd43d9';

/// Live view of the shared map — every player's territory, updated via
/// Supabase Realtime whenever any capture/steal/decay touches the table.
/// Deferred until [territoryMapReadyProvider] is true so startup and other
/// shell tabs do not open the Realtime subscription.

@ProviderFor(territoryList)
final territoryListProvider = TerritoryListProvider._();

/// Live view of the shared map — every player's territory, updated via
/// Supabase Realtime whenever any capture/steal/decay touches the table.
/// Deferred until [territoryMapReadyProvider] is true so startup and other
/// shell tabs do not open the Realtime subscription.

final class TerritoryListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TerritoryEntity>>,
          List<TerritoryEntity>,
          Stream<List<TerritoryEntity>>
        >
    with
        $FutureModifier<List<TerritoryEntity>>,
        $StreamProvider<List<TerritoryEntity>> {
  /// Live view of the shared map — every player's territory, updated via
  /// Supabase Realtime whenever any capture/steal/decay touches the table.
  /// Deferred until [territoryMapReadyProvider] is true so startup and other
  /// shell tabs do not open the Realtime subscription.
  TerritoryListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'territoryListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$territoryListHash();

  @$internal
  @override
  $StreamProviderElement<List<TerritoryEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TerritoryEntity>> create(Ref ref) {
    return territoryList(ref);
  }
}

String _$territoryListHash() => r'87d9b6b25d4f4a7693bcc574fb8a18384bad5beb';

/// Defaults to "Nearby" per the product decision.

@ProviderFor(LeaderboardModeNotifier)
final leaderboardModeProvider = LeaderboardModeNotifierProvider._();

/// Defaults to "Nearby" per the product decision.
final class LeaderboardModeNotifierProvider
    extends $NotifierProvider<LeaderboardModeNotifier, LeaderboardMode> {
  /// Defaults to "Nearby" per the product decision.
  LeaderboardModeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leaderboardModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leaderboardModeNotifierHash();

  @$internal
  @override
  LeaderboardModeNotifier create() => LeaderboardModeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeaderboardMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeaderboardMode>(value),
    );
  }
}

String _$leaderboardModeNotifierHash() =>
    r'1ed5920c6c4cfd974b181b70c10a99d1ff640b9d';

/// Defaults to "Nearby" per the product decision.

abstract class _$LeaderboardModeNotifier extends $Notifier<LeaderboardMode> {
  LeaderboardMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LeaderboardMode, LeaderboardMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LeaderboardMode, LeaderboardMode>,
              LeaderboardMode,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Defaults to all-time (current ownership).

@ProviderFor(LeaderboardWindowNotifier)
final leaderboardWindowProvider = LeaderboardWindowNotifierProvider._();

/// Defaults to all-time (current ownership).
final class LeaderboardWindowNotifierProvider
    extends $NotifierProvider<LeaderboardWindowNotifier, LeaderboardWindow> {
  /// Defaults to all-time (current ownership).
  LeaderboardWindowNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leaderboardWindowProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leaderboardWindowNotifierHash();

  @$internal
  @override
  LeaderboardWindowNotifier create() => LeaderboardWindowNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LeaderboardWindow value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LeaderboardWindow>(value),
    );
  }
}

String _$leaderboardWindowNotifierHash() =>
    r'932581e77b9be62aee9840c06c03f3c69f7d5459';

/// Defaults to all-time (current ownership).

abstract class _$LeaderboardWindowNotifier
    extends $Notifier<LeaderboardWindow> {
  LeaderboardWindow build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LeaderboardWindow, LeaderboardWindow>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LeaderboardWindow, LeaderboardWindow>,
              LeaderboardWindow,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The viewer's current position, used only to scope the "Nearby" leaderboard.

@ProviderFor(ViewerLocationNotifier)
final viewerLocationProvider = ViewerLocationNotifierProvider._();

/// The viewer's current position, used only to scope the "Nearby" leaderboard.
final class ViewerLocationNotifierProvider
    extends $NotifierProvider<ViewerLocationNotifier, GeoPointEntity?> {
  /// The viewer's current position, used only to scope the "Nearby" leaderboard.
  ViewerLocationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'viewerLocationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$viewerLocationNotifierHash();

  @$internal
  @override
  ViewerLocationNotifier create() => ViewerLocationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeoPointEntity? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeoPointEntity?>(value),
    );
  }
}

String _$viewerLocationNotifierHash() =>
    r'913c432fa2b93dbbc294beafff168f21525b8aac';

/// The viewer's current position, used only to scope the "Nearby" leaderboard.

abstract class _$ViewerLocationNotifier extends $Notifier<GeoPointEntity?> {
  GeoPointEntity? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<GeoPointEntity?, GeoPointEntity?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GeoPointEntity?, GeoPointEntity?>,
              GeoPointEntity?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(leaderboard)
final leaderboardProvider = LeaderboardProvider._();

final class LeaderboardProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LeaderboardEntryEntity>>,
          List<LeaderboardEntryEntity>,
          FutureOr<List<LeaderboardEntryEntity>>
        >
    with
        $FutureModifier<List<LeaderboardEntryEntity>>,
        $FutureProvider<List<LeaderboardEntryEntity>> {
  LeaderboardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'leaderboardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$leaderboardHash();

  @$internal
  @override
  $FutureProviderElement<List<LeaderboardEntryEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LeaderboardEntryEntity>> create(Ref ref) {
    return leaderboard(ref);
  }
}

String _$leaderboardHash() => r'27e160a27357154944783c5b42282c97873f7c98';

@ProviderFor(decayWarnings)
final decayWarningsProvider = DecayWarningsProvider._();

final class DecayWarningsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DecayWarningEntity>>,
          List<DecayWarningEntity>,
          FutureOr<List<DecayWarningEntity>>
        >
    with
        $FutureModifier<List<DecayWarningEntity>>,
        $FutureProvider<List<DecayWarningEntity>> {
  DecayWarningsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'decayWarningsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$decayWarningsHash();

  @$internal
  @override
  $FutureProviderElement<List<DecayWarningEntity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DecayWarningEntity>> create(Ref ref) {
    return decayWarnings(ref);
  }
}

String _$decayWarningsHash() => r'fc3ccd8a52c26b66f9bc1f39beb9dd2f22c6f672';

/// Set to `true` the first time [TerritoryRunScreen] mounts.

@ProviderFor(TerritoryMapReadyNotifier)
final territoryMapReadyProvider = TerritoryMapReadyNotifierProvider._();

/// Set to `true` the first time [TerritoryRunScreen] mounts.
final class TerritoryMapReadyNotifierProvider
    extends $NotifierProvider<TerritoryMapReadyNotifier, bool> {
  /// Set to `true` the first time [TerritoryRunScreen] mounts.
  TerritoryMapReadyNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'territoryMapReadyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$territoryMapReadyNotifierHash();

  @$internal
  @override
  TerritoryMapReadyNotifier create() => TerritoryMapReadyNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$territoryMapReadyNotifierHash() =>
    r'c99e68c5a854e40477b9e7fc0d64df80ddec2b6b';

/// Set to `true` the first time [TerritoryRunScreen] mounts.

abstract class _$TerritoryMapReadyNotifier extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Last known GPS fix for the idle map marker.

@ProviderFor(MapLastKnownPositionNotifier)
final mapLastKnownPositionProvider = MapLastKnownPositionNotifierProvider._();

/// Last known GPS fix for the idle map marker.
final class MapLastKnownPositionNotifierProvider
    extends $NotifierProvider<MapLastKnownPositionNotifier, Position?> {
  /// Last known GPS fix for the idle map marker.
  MapLastKnownPositionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapLastKnownPositionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapLastKnownPositionNotifierHash();

  @$internal
  @override
  MapLastKnownPositionNotifier create() => MapLastKnownPositionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Position? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Position?>(value),
    );
  }
}

String _$mapLastKnownPositionNotifierHash() =>
    r'ca8bcd1b6084e20fdb9cd7878e2deca297de10fe';

/// Last known GPS fix for the idle map marker.

abstract class _$MapLastKnownPositionNotifier extends $Notifier<Position?> {
  Position? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Position?, Position?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Position?, Position?>,
              Position?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Loads and caches Awaken's branded OpenFreeMap vector style once per app session.

@ProviderFor(territoryMapStyle)
final territoryMapStyleProvider = TerritoryMapStyleProvider._();

/// Loads and caches Awaken's branded OpenFreeMap vector style once per app session.

final class TerritoryMapStyleProvider
    extends $FunctionalProvider<AsyncValue<Style>, Style, FutureOr<Style>>
    with $FutureModifier<Style>, $FutureProvider<Style> {
  /// Loads and caches Awaken's branded OpenFreeMap vector style once per app session.
  TerritoryMapStyleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'territoryMapStyleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$territoryMapStyleHash();

  @$internal
  @override
  $FutureProviderElement<Style> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Style> create(Ref ref) {
    return territoryMapStyle(ref);
  }
}

String _$territoryMapStyleHash() => r'3794f0255d57b28c29ce9ff143886ca12c8bd5a4';

/// Continuous "blue dot" GPS feed for the map's live-position marker.

@ProviderFor(myLocation)
final myLocationProvider = MyLocationProvider._();

/// Continuous "blue dot" GPS feed for the map's live-position marker.

final class MyLocationProvider
    extends
        $FunctionalProvider<AsyncValue<Position?>, Position?, Stream<Position?>>
    with $FutureModifier<Position?>, $StreamProvider<Position?> {
  /// Continuous "blue dot" GPS feed for the map's live-position marker.
  MyLocationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myLocationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myLocationHash();

  @$internal
  @override
  $StreamProviderElement<Position?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Position?> create(Ref ref) {
    return myLocation(ref);
  }
}

String _$myLocationHash() => r'eac97c11cd75ea0bf0e6d0ddaa1a7c4bb92d17ad';

@ProviderFor(MapEngineNotifier)
final mapEngineProvider = MapEngineNotifierProvider._();

final class MapEngineNotifierProvider
    extends $NotifierProvider<MapEngineNotifier, MapEngine> {
  MapEngineNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapEngineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapEngineNotifierHash();

  @$internal
  @override
  MapEngineNotifier create() => MapEngineNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapEngine>(value),
    );
  }
}

String _$mapEngineNotifierHash() => r'a0a7d4ef2f0f130b84efd00d98f37701cc71466c';

abstract class _$MapEngineNotifier extends $Notifier<MapEngine> {
  MapEngine build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MapEngine, MapEngine>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MapEngine, MapEngine>,
              MapEngine,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Set by the leaderboard's "tap to locate" action.

@ProviderFor(TerritoryMapFocusNotifier)
final territoryMapFocusProvider = TerritoryMapFocusNotifierProvider._();

/// Set by the leaderboard's "tap to locate" action.
final class TerritoryMapFocusNotifierProvider
    extends $NotifierProvider<TerritoryMapFocusNotifier, LatLng?> {
  /// Set by the leaderboard's "tap to locate" action.
  TerritoryMapFocusNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'territoryMapFocusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$territoryMapFocusNotifierHash();

  @$internal
  @override
  TerritoryMapFocusNotifier create() => TerritoryMapFocusNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LatLng? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LatLng?>(value),
    );
  }
}

String _$territoryMapFocusNotifierHash() =>
    r'db22237a7596fec3789201ac0b5261354a6e5fc5';

/// Set by the leaderboard's "tap to locate" action.

abstract class _$TerritoryMapFocusNotifier extends $Notifier<LatLng?> {
  LatLng? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<LatLng?, LatLng?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<LatLng?, LatLng?>,
              LatLng?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
