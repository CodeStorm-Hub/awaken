import 'dart:async';

import 'package:awaken/features/territory/data/models/capture_result_model.dart';
import 'package:awaken/features/territory/data/models/decay_warning_model.dart';
import 'package:awaken/features/territory/data/models/leaderboard_entry_model.dart';
import 'package:awaken/features/territory/data/models/territory_geo_codec.dart';
import 'package:awaken/features/territory/data/models/territory_model.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/run_track_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TerritorySupabaseDatasource {
  const TerritorySupabaseDatasource();

  SupabaseClient get _client => Supabase.instance.client;
  String get _userId => _client.auth.currentUser!.id;

  Future<List<TerritoryModel>> getAllTerritories() async {
    final data = await _client.from('territories_geojson').select();
    return (data as List)
        .map((json) => TerritoryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Re-fetches the full territory set whenever the underlying `territories`
  /// table changes — simpler and more correct than diffing individual
  /// postgres_changes payloads against client-side geometry state.
  Stream<List<TerritoryModel>> watchTerritories() {
    final controller = StreamController<List<TerritoryModel>>();

    Future<void> refresh() async {
      if (controller.isClosed) return;
      try {
        controller.add(await getAllTerritories());
      } catch (error, stackTrace) {
        if (!controller.isClosed) controller.addError(error, stackTrace);
      }
    }

    final channel = _client
        .channel('territories-changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'territories',
          callback: (_) => refresh(),
        )
        .subscribe();

    unawaited(refresh());

    controller.onCancel = () async {
      await _client.removeChannel(channel);
    };

    return controller.stream;
  }

  Future<void> recordRun(RunTrackEntity run) async {
    await _client.from('runs').insert({
      'user_id': _userId,
      'path': TerritoryGeoCodec.pointsToLineStringEwkt(run.points),
      'distance_meters': run.distanceMeters,
      'duration_seconds': run.duration.inSeconds,
      'is_closed_loop': run.isClosedLoop,
      'territory_claimed': run.outcome == RunOutcome.territoryClaimed,
      'invalidated_reason': switch (run.outcome) {
        RunOutcome.territoryClaimed => null,
        RunOutcome.loopNotClosed => null,
        RunOutcome.invalidatedSpeedCap => 'speed_cap',
        RunOutcome.invalidatedTooSmall => 'loop_too_small',
        RunOutcome.invalidatedTooShort => 'too_short',
      },
    });
  }

  Future<CaptureResultModel> captureTerritory(List<GeoPointEntity> loopPoints) async {
    final result = await _client.rpc<List<dynamic>>(
      'capture_territory',
      params: {'new_geom': TerritoryGeoCodec.pointsToPolygonEwkt(loopPoints)},
    );
    return CaptureResultModel.fromJson(result.first as Map<String, dynamic>);
  }

  Future<void> touchDefense(List<GeoPointEntity> path) async {
    await _client.rpc<void>(
      'touch_territory_defense',
      params: {'run_path': TerritoryGeoCodec.pointsToLineStringEwkt(path)},
    );
  }

  Future<List<LeaderboardEntryModel>> getGlobalLeaderboard() async {
    final data = await _client.from('leaderboard_global').select();
    return (data as List)
        .map((json) => LeaderboardEntryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<LeaderboardEntryModel>> getNearbyLeaderboard(
    GeoPointEntity viewerLocation,
    double radiusMeters,
  ) async {
    final data = await _client.rpc<List<dynamic>>(
      'leaderboard_nearby',
      params: {
        'viewer_lon': viewerLocation.longitude,
        'viewer_lat': viewerLocation.latitude,
        'radius_meters': radiusMeters,
      },
    );
    return data
        .map((json) => LeaderboardEntryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<LeaderboardEntryModel>> getWindowedLeaderboard({
    required int windowHours,
    GeoPointEntity? viewerLocation,
    double radiusMeters = 5000,
  }) async {
    final data = await _client.rpc<List<dynamic>>(
      'leaderboard_windowed',
      params: {
        'window_hours': windowHours,
        'viewer_lon': viewerLocation?.longitude,
        'viewer_lat': viewerLocation?.latitude,
        'radius_meters': viewerLocation == null ? null : radiusMeters,
      },
    );
    return data
        .map((json) => LeaderboardEntryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<DecayWarningModel>> getDecayWarnings() async {
    final data = await _client.rpc<List<dynamic>>('decaying_territories');
    return data
        .map((json) => DecayWarningModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
