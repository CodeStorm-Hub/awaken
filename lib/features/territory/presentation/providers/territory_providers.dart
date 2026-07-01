import 'package:awaken/features/territory/data/datasources/territory_supabase_datasource.dart';
import 'package:awaken/features/territory/data/repositories/territory_supabase_repository_impl.dart';
import 'package:awaken/features/territory/domain/entities/decay_warning_entity.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/leaderboard_entry_entity.dart';
import 'package:awaken/features/territory/domain/entities/territory_entity.dart';
import 'package:awaken/features/territory/domain/repositories/territory_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Territory capture is inherently multiplayer/cloud-backed — there is no
/// local fallback repository the way alarms/sessions have one. Screens that
/// read this assume the caller is signed in (gated by the router/UI).
final territoryRepositoryProvider = Provider<TerritoryRepository>((ref) {
  return const TerritorySupabaseRepositoryImpl(TerritorySupabaseDatasource());
});

/// Live view of the shared map — every player's territory, updated via
/// Supabase Realtime whenever any capture/steal/decay touches the table.
final territoryListProvider = StreamProvider<List<TerritoryEntity>>((ref) {
  return ref.watch(territoryRepositoryProvider).watchTerritories();
});

enum LeaderboardMode { nearby, global }

/// Defaults to "Nearby" per the product decision — more motivating for a
/// new player than seeing they're #4,812 globally.
final leaderboardModeProvider = StateProvider<LeaderboardMode>((ref) => LeaderboardMode.nearby);

/// The viewer's current position, used only to scope the "Nearby" leaderboard.
/// Set by the leaderboard screen on open; null falls back to the global view.
final viewerLocationProvider = StateProvider<GeoPointEntity?>((ref) => null);

final leaderboardProvider = FutureProvider<List<LeaderboardEntryEntity>>((ref) async {
  final repo = ref.watch(territoryRepositoryProvider);
  final mode = ref.watch(leaderboardModeProvider);
  final viewerLocation = ref.watch(viewerLocationProvider);

  // Re-run whenever the shared map changes via Realtime, so rankings shift
  // live as territory changes hands per the plan's leaderboard requirement.
  ref.watch(territoryListProvider);

  if (mode == LeaderboardMode.nearby && viewerLocation != null) {
    return repo.getNearbyLeaderboard(viewerLocation);
  }
  return repo.getGlobalLeaderboard();
});

final decayWarningsProvider = FutureProvider<List<DecayWarningEntity>>((ref) async {
  return ref.watch(territoryRepositoryProvider).getDecayWarnings();
});
