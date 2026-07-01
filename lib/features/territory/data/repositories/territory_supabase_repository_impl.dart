import 'package:awaken/features/territory/data/datasources/territory_supabase_datasource.dart';
import 'package:awaken/features/territory/domain/entities/capture_result_entity.dart';
import 'package:awaken/features/territory/domain/entities/decay_warning_entity.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/leaderboard_entry_entity.dart';
import 'package:awaken/features/territory/domain/entities/run_track_entity.dart';
import 'package:awaken/features/territory/domain/entities/territory_entity.dart';
import 'package:awaken/features/territory/domain/repositories/territory_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TerritorySupabaseRepositoryImpl implements TerritoryRepository {
  const TerritorySupabaseRepositoryImpl(this._datasource);

  final TerritorySupabaseDatasource _datasource;

  String get _currentUserId => Supabase.instance.client.auth.currentUser!.id;

  @override
  Future<List<TerritoryEntity>> getAllTerritories() async {
    final models = await _datasource.getAllTerritories();
    return models.map((m) => m.toEntity(currentUserId: _currentUserId)).toList();
  }

  @override
  Stream<List<TerritoryEntity>> watchTerritories() {
    return _datasource.watchTerritories().map(
          (models) => models.map((m) => m.toEntity(currentUserId: _currentUserId)).toList(),
        );
  }

  @override
  Future<void> recordRun(RunTrackEntity run) => _datasource.recordRun(run);

  @override
  Future<CaptureResultEntity> captureTerritory(List<GeoPointEntity> loopPoints) async {
    final result = await _datasource.captureTerritory(loopPoints);
    return result.toEntity();
  }

  @override
  Future<void> touchDefense(List<GeoPointEntity> path) => _datasource.touchDefense(path);

  @override
  Future<List<LeaderboardEntryEntity>> getGlobalLeaderboard() async {
    final models = await _datasource.getGlobalLeaderboard();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<LeaderboardEntryEntity>> getNearbyLeaderboard(
    GeoPointEntity viewerLocation, {
    double radiusMeters = 5000,
  }) async {
    final models = await _datasource.getNearbyLeaderboard(viewerLocation, radiusMeters);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<DecayWarningEntity>> getDecayWarnings() async {
    final models = await _datasource.getDecayWarnings();
    return models.map((m) => m.toEntity()).toList();
  }
}
