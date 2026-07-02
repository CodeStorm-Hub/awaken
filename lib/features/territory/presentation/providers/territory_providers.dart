import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:awaken/features/territory/data/datasources/territory_supabase_datasource.dart';
import 'package:awaken/features/territory/data/repositories/territory_local_repository_impl.dart';
import 'package:awaken/features/territory/data/repositories/territory_supabase_repository_impl.dart';
import 'package:awaken/features/territory/domain/entities/decay_warning_entity.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/leaderboard_entry_entity.dart';
import 'package:awaken/features/territory/domain/entities/territory_entity.dart';
import 'package:awaken/features/territory/domain/repositories/territory_repository.dart';
import 'package:awaken/features/territory/domain/services/location_permission_helper.dart';
import 'package:awaken/features/territory/presentation/widgets/territory_map_style.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart' show Style;

/// Picks the correct repository based on auth state:
///   - Signed in  → Supabase (cloud-synced)
///   - Signed out → SharedPreferences (local-only)
final territoryRepositoryProvider = Provider<TerritoryRepository>((ref) {
  final signedIn = ref.watch(isSignedInProvider);
  if (signedIn) {
    return const TerritorySupabaseRepositoryImpl(TerritorySupabaseDatasource());
  }
  return TerritoryLocalRepositoryImpl();
});

/// Live view of the shared map — every player's territory, updated via
/// Supabase Realtime whenever any capture/steal/decay touches the table.
final territoryListProvider = StreamProvider<List<TerritoryEntity>>((ref) {
  return ref.watch(territoryRepositoryProvider).watchTerritories();
});

enum LeaderboardMode { nearby, global }

/// Which time window the leaderboard ranks over.
///
/// [day]/[week] rank by area *captured* within that window (a "momentum"
/// board, backed by the `territory_captures` history log written once per
/// `capture_territory` call) — a runner who stole a lot of land in the last
/// 24 hours can outrank someone who owns more land overall but hasn't run
/// recently. [allTime] ranks by *current* total ownership, same as before
/// this enum existed (`leaderboard_global`/`leaderboard_nearby`).
enum LeaderboardWindow { day, week, allTime }

/// Defaults to "Nearby" per the product decision — more motivating for a
/// new player than seeing they're #4,812 globally.
final leaderboardModeProvider = StateProvider<LeaderboardMode>((ref) => LeaderboardMode.nearby);

/// Defaults to all-time (current ownership) — the original, unfiltered
/// leaderboard behavior, so this is purely additive for existing users.
final leaderboardWindowProvider = StateProvider<LeaderboardWindow>((ref) => LeaderboardWindow.allTime);

/// The viewer's current position, used only to scope the "Nearby" leaderboard.
/// Set by the leaderboard screen on open; null falls back to the global view.
final viewerLocationProvider = StateProvider<GeoPointEntity?>((ref) => null);

final leaderboardProvider = FutureProvider<List<LeaderboardEntryEntity>>((ref) async {
  final repo = ref.watch(territoryRepositoryProvider);
  final mode = ref.watch(leaderboardModeProvider);
  final window = ref.watch(leaderboardWindowProvider);
  final viewerLocation = ref.watch(viewerLocationProvider);
  final nearby = mode == LeaderboardMode.nearby && viewerLocation != null;

  // Re-run whenever the shared map changes via Realtime, so rankings shift
  // live as territory changes hands per the plan's leaderboard requirement.
  ref.watch(territoryListProvider);

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
});

final decayWarningsProvider = FutureProvider<List<DecayWarningEntity>>((ref) async {
  return ref.watch(territoryRepositoryProvider).getDecayWarnings();
});

/// Loads and caches Awaken's branded OpenFreeMap vector style once per app
/// session. Not `autoDispose`: the style/tile-source resolution costs a
/// network round-trip, and every map surface (run screen, future territory
/// overview) should reuse the same resolved [Style] rather than re-fetching
/// it per screen visit.
final territoryMapStyleProvider = FutureProvider<Style>((ref) {
  return TerritoryMapStyle.load();
});

/// Continuous "blue dot" GPS feed for the map's live-position marker —
/// independent of [ActiveRunNotifier]'s tracking stream, so the user's
/// current position shows on the map at all times, not only mid-run.
/// `autoDispose` (unlike run tracking): no result needs to survive the
/// screen closing, so the stream/subscription should tear down with it.
///
/// While a run is actively tracking, [_MyLocationMarkerLayer] stops watching
/// this provider and reads run points instead — `autoDispose` then cancels
/// this stream so only one Geolocator subscription is active at a time.
///
/// Emits `null` (rather than throwing) when location isn't available yet
/// (permission not granted, services off) so the UI can simply omit the
/// marker instead of surfacing an error — [TerritoryRunScreen]'s explicit
/// permission flow (via [LocationPermissionHelper]) is the one place that
/// should ever prompt the user; this provider stays silent.
final myLocationProvider = StreamProvider.autoDispose<Position?>((ref) async* {
  try {
    await LocationPermissionHelper.ensureLocationAccess();
  } on LocationAccessException {
    yield null;
    return;
  }

  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    ),
  );
});

/// Which basemap renderer [TerritoryVectorTileLayer] should use.
enum MapEngine {
  /// Branded OpenFreeMap vector tiles (default) — themed to match
  /// `AppColors`, rendered via `VectorTileLayerMode.raster` for good frame
  /// rate on most devices.
  vector,

  /// Plain OSM XYZ raster tiles, unthemed. An emergency degrade path for
  /// devices where even raster-mode vector rendering janks — not the
  /// default; flip only after profiling confirms it's needed, per the
  /// map-perfection plan's own caution about vector-tile CPU cost on very
  /// low-end Android.
  raster,
}

/// Defaults to [MapEngine.vector]. Not surfaced as a user-facing setting —
/// a developer/support escape hatch, not a feature.
final mapEngineProvider = StateProvider<MapEngine>((ref) => MapEngine.vector);

/// Set by the leaderboard's "tap to locate" action just before navigating to
/// the run screen; consumed once by [TerritoryRunScreen] to re-center the
/// camera, then cleared. Computed client-side from [territoryListProvider]'s
/// live polygon geometry (a simple ring-vertex average, not a true polygon
/// centroid) — no backend change needed since that geometry is already
/// broadcast over Realtime for every player, unlike leaderboard entries
/// themselves, which carry no location.
final territoryMapFocusProvider = StateProvider<LatLng?>((ref) => null);

/// Ring-vertex average of a territory's first polygon — "near enough" for
/// jumping the map camera there, not meant as a precise geometric centroid.
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
