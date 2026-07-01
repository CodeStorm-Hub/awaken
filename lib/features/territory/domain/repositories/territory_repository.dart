import 'package:awaken/features/territory/domain/entities/capture_result_entity.dart';
import 'package:awaken/features/territory/domain/entities/decay_warning_entity.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/leaderboard_entry_entity.dart';
import 'package:awaken/features/territory/domain/entities/run_track_entity.dart';
import 'package:awaken/features/territory/domain/entities/territory_entity.dart';

abstract class TerritoryRepository {
  /// All territories on the shared map (every player's land).
  Future<List<TerritoryEntity>> getAllTerritories();

  /// Live updates to the shared map via Supabase Realtime.
  Stream<List<TerritoryEntity>> watchTerritories();

  /// Persists a finished run (closed or not) for history/stats.
  Future<void> recordRun(RunTrackEntity run);

  /// Calls the `capture_territory` RPC with the closed-loop polygon.
  /// Throws if the loop is rejected server-side (e.g. `loop_too_small`).
  Future<CaptureResultEntity> captureTerritory(List<GeoPointEntity> loopPoints);

  /// Refreshes `last_defended_at` for any owned territory the run path
  /// passed through, even when no new loop was closed.
  Future<void> touchDefense(List<GeoPointEntity> path);

  Future<List<LeaderboardEntryEntity>> getGlobalLeaderboard();

  Future<List<LeaderboardEntryEntity>> getNearbyLeaderboard(
    GeoPointEntity viewerLocation, {
    double radiusMeters = 5000,
  });

  Future<List<DecayWarningEntity>> getDecayWarnings();
}
