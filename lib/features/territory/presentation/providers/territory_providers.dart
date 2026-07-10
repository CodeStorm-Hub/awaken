import 'dart:async';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:awaken/features/territory/data/datasources/pending_capture_queue.dart';
import 'package:awaken/features/territory/data/datasources/territory_supabase_datasource.dart';
import 'package:awaken/features/territory/data/repositories/territory_local_repository_impl.dart';
import 'package:awaken/features/territory/data/repositories/territory_supabase_repository_impl.dart';
import 'package:awaken/features/territory/domain/entities/decay_warning_entity.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/leaderboard_entry_entity.dart';
import 'package:awaken/features/territory/domain/entities/territory_entity.dart';
import 'package:awaken/features/territory/domain/repositories/territory_repository.dart';
import 'package:awaken/features/territory/domain/services/location_fix_service.dart';
import 'package:awaken/features/territory/domain/services/location_permission_helper.dart';
import 'package:awaken/features/territory/presentation/widgets/territory_map_style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart' show Style;

part 'territory_providers.g.dart';

/// Current shell tab index (0 = dashboard, 1 = territory, 2 = leaderboard).
/// Updated by [_ShellScaffold] in app_router.dart.
final territoryShellTabIndexProvider = StateProvider<int>((ref) => 0);

/// Set true while a run is actively tracking so GPS/map layers stay warm if the
/// user briefly backgrounds the app (not shell tab switches during a run).
final territoryRunGpsKeepAliveProvider = StateProvider<bool>((ref) => false);

/// When true, [ActiveRunNotifier] owns the high-accuracy GPS stream — idle
/// [myLocationProvider] must not open a second Geolocator subscription.
final runOwnsHighAccuracyGpsProvider = StateProvider<bool>((ref) => false);

/// Live map camera zoom — updated by [TerritoryRunScreen] on pan/zoom.
final territoryMapZoomProvider = StateProvider<double>(
  (ref) => AppConstants.territoryMapInitialZoom,
);

bool _territoryMapServicesActive(int shellTabIndex) =>
    shellTabIndex == 1 || shellTabIndex == 2;

bool _territoryGpsActive(Ref ref) {
  if (ref.watch(territoryShellTabIndexProvider) == 1) return true;
  return ref.watch(territoryRunGpsKeepAliveProvider);
}

/// Picks the correct repository based on auth state:
///   - Signed in  → Supabase (cloud-synced)
///   - Signed out → SharedPreferences (local-only)
@Riverpod(keepAlive: true)
TerritoryRepository territoryRepository(TerritoryRepositoryRef ref) {
  final signedIn = ref.watch(isSignedInProvider);
  if (signedIn) {
    return const TerritorySupabaseRepositoryImpl(TerritorySupabaseDatasource());
  }
  return TerritoryLocalRepositoryImpl();
}

/// Live view of the shared map — every player's territory, updated via
/// Supabase Realtime whenever any capture/steal/decay touches the table.
/// Deferred until [territoryMapReadyProvider] is true so startup and other
/// shell tabs do not open the Realtime subscription.
@Riverpod(keepAlive: true)
Stream<List<TerritoryEntity>> territoryList(TerritoryListRef ref) {
  if (!ref.watch(territoryMapReadyProvider)) {
    return Completer<List<TerritoryEntity>>().future.asStream();
  }

  final tabIndex = ref.watch(territoryShellTabIndexProvider);
  if (!_territoryMapServicesActive(tabIndex)) {
    return Completer<List<TerritoryEntity>>().future.asStream();
  }

  ref.keepAlive();
  return ref.watch(territoryRepositoryProvider).watchTerritories();
}

enum LeaderboardMode { nearby, global }

/// Which time window the leaderboard ranks over.
enum LeaderboardWindow { day, week, allTime }

/// Defaults to "Nearby" per the product decision.
@riverpod
class LeaderboardModeNotifier extends _$LeaderboardModeNotifier {
  @override
  LeaderboardMode build() => LeaderboardMode.nearby;

  @override
  set state(LeaderboardMode value) => super.state = value;
}

final leaderboardModeProvider = leaderboardModeNotifierProvider;

/// Defaults to all-time (current ownership).
@riverpod
class LeaderboardWindowNotifier extends _$LeaderboardWindowNotifier {
  @override
  LeaderboardWindow build() => LeaderboardWindow.allTime;

  @override
  set state(LeaderboardWindow value) => super.state = value;
}

final leaderboardWindowProvider = leaderboardWindowNotifierProvider;

/// The viewer's current position, used only to scope the "Nearby" leaderboard.
@riverpod
class ViewerLocationNotifier extends _$ViewerLocationNotifier {
  @override
  GeoPointEntity? build() => null;

  @override
  set state(GeoPointEntity? value) => super.state = value;
}

final viewerLocationProvider = viewerLocationNotifierProvider;

@riverpod
Future<List<LeaderboardEntryEntity>> leaderboard(LeaderboardRef ref) async {
  final repo = ref.watch(territoryRepositoryProvider);
  final mode = ref.watch(leaderboardModeProvider);
  final window = ref.watch(leaderboardWindowProvider);
  final viewerLocation = ref.watch(viewerLocationProvider);
  final nearby = mode == LeaderboardMode.nearby && viewerLocation != null;

  // Re-run whenever the shared map changes via Realtime
  if (ref.watch(territoryMapReadyProvider)) {
    ref.watch(territoryListProvider);
  }

  if (window == LeaderboardWindow.allTime) {
    return nearby ? repo.getNearbyLeaderboard(viewerLocation) : repo.getGlobalLeaderboard();
  }

  final windowHours = switch (window) {
    LeaderboardWindow.day => 24,
    LeaderboardWindow.week => 24 * 7,
    LeaderboardWindow.allTime => throw StateError('handled above'),
  };
  return repo.getWindowedLeaderboard(
    windowHours: windowHours,
    viewerLocation: nearby ? viewerLocation : null,
  );
}

@riverpod
Future<List<DecayWarningEntity>> decayWarnings(DecayWarningsRef ref) async {
  return ref.watch(territoryRepositoryProvider).getDecayWarnings();
}

/// Set to `true` the first time [TerritoryRunScreen] mounts.
@riverpod
class TerritoryMapReadyNotifier extends _$TerritoryMapReadyNotifier {
  @override
  bool build() => false;

  @override
  set state(bool value) => super.state = value;
}

final territoryMapReadyProvider = territoryMapReadyNotifierProvider;

/// Last known GPS fix for the idle map marker.
@riverpod
class MapLastKnownPositionNotifier extends _$MapLastKnownPositionNotifier {
  @override
  Position? build() => null;

  @override
  set state(Position? value) => super.state = value;
}

final mapLastKnownPositionProvider = mapLastKnownPositionNotifierProvider;

/// Loads and caches Awaken's branded OpenFreeMap vector style once per app session.
@Riverpod(keepAlive: true)
Future<Style> territoryMapStyle(TerritoryMapStyleRef ref) async {
  if (!ref.watch(territoryMapReadyProvider)) {
    // Stay in [AsyncLoading] until the territory tab opens once.
    await Completer<Style>().future;
  }

  ref.keepAlive();
  return TerritoryMapStyle.load();
}

/// Continuous "blue dot" GPS feed for the map's live-position marker.
@riverpod
Stream<Position?> myLocation(MyLocationRef ref) async* {
  if (!ref.watch(territoryMapReadyProvider)) {
    return;
  }

  if (!_territoryGpsActive(ref)) {
    return;
  }

  // Active run already has a high-accuracy stream — avoid a second subscription.
  if (ref.watch(runOwnsHighAccuracyGpsProvider)) {
    yield ref.read(mapLastKnownPositionProvider);
    return;
  }

  try {
    await LocationPermissionHelper.ensureLocationAccess();
  } on LocationAccessException {
    yield null;
    return;
  }

  // Emit cached / one-shot fixes immediately
  final cached = ref.read(mapLastKnownPositionProvider);
  if (cached != null) {
    yield cached;
  }

  try {
    final current = await LocationFixService.acquireForMapCentering(
      onInterim: (position) {
        ref.read(mapLastKnownPositionProvider.notifier).state = position;
      },
    );
    if (current != null) {
      ref.read(mapLastKnownPositionProvider.notifier).state = current;
      yield current;
    }
  } catch (_) {
    // Keep any cached/last-known fix already emitted above.
  }

  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    ),
  ).map((position) {
    ref.read(mapLastKnownPositionProvider.notifier).state = position;
    return position;
  });
}

enum MapEngine { vector, raster }

@riverpod
class MapEngineNotifier extends _$MapEngineNotifier {
  @override
  MapEngine build() => MapEngine.vector;

  @override
  set state(MapEngine value) => super.state = value;
}

final mapEngineProvider = mapEngineNotifierProvider;

/// Set by the leaderboard's "tap to locate" action.
@riverpod
class TerritoryMapFocusNotifier extends _$TerritoryMapFocusNotifier {
  @override
  LatLng? build() => null;

  @override
  set state(LatLng? value) => super.state = value;
}

final territoryMapFocusProvider = territoryMapFocusNotifierProvider;

/// Ring-vertex average of a territory's first polygon.
LatLng? territoryApproxCentroid(TerritoryEntity territory) {
  if (territory.polygons.isEmpty) return null;
  final ring = territory.polygons.first;
  if (ring.isEmpty) return null;

  var sumLat = 0.0;
  var sumLng = 0.0;
  for (final point in ring) {
    sumLat += point.latitude;
    sumLng += point.longitude;
  }
  return LatLng(sumLat / ring.length, sumLng / ring.length);
}

/// Retries queued territory captures after sign-in (parity with session sync).
final captureSyncOnSignInProvider = Provider<void>((ref) {
  ref.listen(authStateProvider, (previous, next) {
    next.whenData((state) async {
      if (state.session == null) return;
      const queue = PendingCaptureQueue();
      final pending = await queue.peek();
      if (pending.isEmpty) return;

      final repo = ref.read(territoryRepositoryProvider);
      for (final item in pending) {
        try {
          await repo.captureTerritory(item.points);
          await queue.remove(item.id);
        } catch (e) {
          debugPrint('[CaptureQueue] sign-in flush failed for ${item.id}: $e');
        }
      }
    });
  });
});
