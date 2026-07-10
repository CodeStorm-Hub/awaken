import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/features/territory/domain/entities/capture_result_entity.dart';
import 'package:awaken/features/territory/domain/entities/decay_warning_entity.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/leaderboard_entry_entity.dart';
import 'package:awaken/features/territory/domain/entities/run_track_entity.dart';
import 'package:awaken/features/territory/domain/entities/territory_entity.dart';
import 'package:awaken/features/territory/domain/repositories/territory_repository.dart';
import 'package:awaken/features/territory/domain/services/geo_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TerritoryLocalRepositoryImpl implements TerritoryRepository {
  TerritoryLocalRepositoryImpl();

  static const _territoriesKey = 'awaken_local_territories';
  static const _runsKey = 'awaken_local_runs';

  final _controller = StreamController<List<TerritoryEntity>>.broadcast();
  List<TerritoryEntity>? _cachedTerritories;
  List<RunTrackEntity>? _cachedRuns;

  String get _currentUserId => 'local-user';
  String get _currentUserDisplayName => 'Local Runner';

  Future<void> _ensureLoaded() async {
    if (_cachedTerritories != null && _cachedRuns != null) return;

    final prefs = await SharedPreferences.getInstance();

    final rawTerritories = prefs.getStringList(_territoriesKey) ?? [];
    _cachedTerritories = rawTerritories.map((item) {
      final json = jsonDecode(item) as Map<String, dynamic>;
      return _territoryFromJson(json);
    }).toList();

    final rawRuns = prefs.getStringList(_runsKey) ?? [];
    _cachedRuns = rawRuns.map((item) {
      final json = jsonDecode(item) as Map<String, dynamic>;
      return _runTrackFromJson(json);
    }).toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    if (_cachedTerritories != null) {
      final raw = _cachedTerritories!
          .map((t) => jsonEncode(_territoryToJson(t)))
          .toList();
      await prefs.setStringList(_territoriesKey, raw);
      _controller.add(List.unmodifiable(_cachedTerritories!));
    }
    if (_cachedRuns != null) {
      final raw = _cachedRuns!
          .map((r) => jsonEncode(_runTrackToJson(r)))
          .toList();
      await prefs.setStringList(_runsKey, raw);
    }
  }

  @override
  Future<List<TerritoryEntity>> getAllTerritories() async {
    await _ensureLoaded();
    return List.unmodifiable(_cachedTerritories!);
  }

  @override
  Stream<List<TerritoryEntity>> watchTerritories() {
    Timer.run(() async {
      try {
        await _ensureLoaded();
        if (!_controller.isClosed) {
          _controller.add(List.unmodifiable(_cachedTerritories!));
        }
      } catch (_) {}
    });
    return _controller.stream;
  }

  @override
  Future<void> recordRun(RunTrackEntity run) async {
    await _ensureLoaded();
    _cachedRuns!.add(run);
    await _save();
  }

  @override
  Future<CaptureResultEntity> captureTerritory(
      List<GeoPointEntity> loopPoints) async {
    await _ensureLoaded();

    final area = _calculatePolygonArea(loopPoints);
    if (area < AppConstants.minLoopAreaSqMeters) {
      throw Exception(
          'loop_too_small: Enclosed area of ${area.toStringAsFixed(1)} m² is below the minimum of ${AppConstants.minLoopAreaSqMeters} m²');
    }

    final userId = _currentUserId;
    final displayName = _currentUserDisplayName;

    // Find the current user's existing territory index
    final userTerritoryIndex =
        _cachedTerritories!.indexWhere((t) => t.userId == userId);

    List<PolygonRing> userPolygons = [];
    if (userTerritoryIndex != -1) {
      userPolygons = List.from(_cachedTerritories![userTerritoryIndex].polygons);
    }

    int rivalsAffected = 0;
    final newBbox = _getBoundingBox(loopPoints);

    final List<TerritoryEntity> updatedRivalTerritories = [];

    // Process rival stealing (ST_Difference simulation)
    for (final t in _cachedTerritories!) {
      if (t.userId == userId) continue;

      List<PolygonRing> remainingRivalPolygons = [];
      double rivalArea = 0.0;
      bool rivalAffectedByThisTerritory = false;

      for (final poly in t.polygons) {
        final rivalBbox = _getBoundingBox(poly);
        if (_boundingBoxesIntersect(newBbox, rivalBbox)) {
          // Bounding boxes intersect; check if actual polygon intersection exists.
          bool pointsOverlap = false;
          for (final p in poly) {
            if (_isPointInPolygon(p, loopPoints)) {
              pointsOverlap = true;
              break;
            }
          }
          if (!pointsOverlap) {
            for (final p in loopPoints) {
              if (_isPointInPolygon(p, poly)) {
                pointsOverlap = true;
                break;
              }
            }
          }

          if (pointsOverlap) {
            rivalAffectedByThisTerritory = true;

            // Vertex-based ST_Difference approximation (matches server sliver
            // cleanup at ST_Area >= 1.0 m² per resulting polygon).
            final isInside =
                poly.map((p) => _isPointInPolygon(p, loopPoints)).toList();
            if (!isInside.contains(true)) {
              // Edge-only overlap: no vertex inside either polygon. Geometry
              // is unchanged (PostGIS would cut along edges).
              remainingRivalPolygons.add(poly);
              rivalArea += _calculatePolygonArea(poly);
            } else if (!isInside.contains(false)) {
              continue; // completely inside — deleted
            } else {
              // Find first index that is inside to start our traversal
              final startIndex = isInside.indexOf(true);
              final runs = <List<GeoPointEntity>>[];
              List<GeoPointEntity> currentRun = [];
              for (var i = 0; i < poly.length; i++) {
                final idx = (startIndex + i) % poly.length;
                if (!isInside[idx]) {
                  currentRun.add(poly[idx]);
                } else {
                  if (currentRun.length >= 3) {
                    runs.add(currentRun);
                  }
                  currentRun = [];
                }
              }
              if (currentRun.length >= 3) {
                runs.add(currentRun);
              }

              for (final run in runs) {
                final runArea = _calculatePolygonArea(run);
                if (runArea >= 1.0) {
                  remainingRivalPolygons.add(run);
                  rivalArea += runArea;
                }
              }
            }
          } else {
            remainingRivalPolygons.add(poly);
            rivalArea += _calculatePolygonArea(poly);
          }
        } else {
          remainingRivalPolygons.add(poly);
          rivalArea += _calculatePolygonArea(poly);
        }
      }

      if (rivalAffectedByThisTerritory) {
        rivalsAffected++;
      }

      if (remainingRivalPolygons.isNotEmpty) {
        updatedRivalTerritories.add(TerritoryEntity(
          id: t.id,
          userId: t.userId,
          ownerDisplayName: t.ownerDisplayName,
          polygons: remainingRivalPolygons,
          areaSqMeters: rivalArea,
          lastDefendedAt: t.lastDefendedAt,
          isOwnedByCurrentUser: false,
        ));
      }
    }

    // Process self-union (ST_Union simulation)
    bool mergedWithSelf = false;
    List<PolygonRing> mergedPolygons = [];

    for (final poly in userPolygons) {
      final userBbox = _getBoundingBox(poly);
      if (_boundingBoxesIntersect(newBbox, userBbox)) {
        bool overlaps = false;
        for (final p in poly) {
          if (_isPointInPolygon(p, loopPoints)) {
            overlaps = true;
            break;
          }
        }
        if (!overlaps) {
          for (final p in loopPoints) {
            if (_isPointInPolygon(p, poly)) {
              overlaps = true;
              break;
            }
          }
        }

        if (overlaps) {
          mergedWithSelf = true;
          final allInside =
              loopPoints.every((p) => _isPointInPolygon(p, poly));
          if (allInside) {
            mergedPolygons.add(poly);
          } else {
            final mergedPoints = <GeoPointEntity>[];
            mergedPoints.addAll(poly);
            for (final p in loopPoints) {
              if (!mergedPoints.any((mp) =>
                  mp.latitude == p.latitude && mp.longitude == p.longitude)) {
                mergedPoints.add(p);
              }
            }
            mergedPolygons.add(mergedPoints);
          }
        } else {
          mergedPolygons.add(poly);
        }
      } else {
        mergedPolygons.add(poly);
      }
    }

    if (!mergedWithSelf) {
      mergedPolygons.add(loopPoints);
    }

    double totalUserArea = 0.0;
    for (final poly in mergedPolygons) {
      totalUserArea += _calculatePolygonArea(poly);
    }

    final userTerritory = TerritoryEntity(
      id: userTerritoryIndex != -1
          ? _cachedTerritories![userTerritoryIndex].id
          : 'territory-$userId',
      userId: userId,
      ownerDisplayName: displayName,
      polygons: mergedPolygons,
      areaSqMeters: totalUserArea,
      lastDefendedAt: DateTime.now(),
      isOwnedByCurrentUser: true,
    );

    _cachedTerritories!.clear();
    _cachedTerritories!.addAll(updatedRivalTerritories);
    _cachedTerritories!.add(userTerritory);

    await _save();

    return CaptureResultEntity(
      claimedAreaSqMeters: area,
      totalOwnedAreaSqMeters: totalUserArea,
      rivalsAffected: rivalsAffected,
    );
  }

  @override
  Future<void> touchDefense(List<GeoPointEntity> path) async {
    await _ensureLoaded();

    final userId = _currentUserId;
    final idx = _cachedTerritories!.indexWhere((t) => t.userId == userId);
    if (idx == -1) return;

    final t = _cachedTerritories![idx];
    bool touched = false;

    for (final poly in t.polygons) {
      for (final pathPt in path) {
        for (final polyPt in poly) {
          if (GeoUtils.haversineMeters(pathPt, polyPt) <= 20.0) {
            touched = true;
            break;
          }
        }
        if (touched) break;
      }
      if (touched) break;
    }

    if (touched) {
      _cachedTerritories![idx] = TerritoryEntity(
        id: t.id,
        userId: t.userId,
        ownerDisplayName: t.ownerDisplayName,
        polygons: t.polygons,
        areaSqMeters: t.areaSqMeters,
        lastDefendedAt: DateTime.now(),
        isOwnedByCurrentUser: true,
      );
      await _save();
    }
  }

  @override
  Future<List<LeaderboardEntryEntity>> getGlobalLeaderboard() async {
    await _ensureLoaded();
    final sorted = List<TerritoryEntity>.from(_cachedTerritories!)
      ..sort((a, b) => b.areaSqMeters.compareTo(a.areaSqMeters));

    return List.generate(sorted.length, (i) {
      final t = sorted[i];
      return LeaderboardEntryEntity(
        userId: t.userId,
        displayName: t.ownerDisplayName,
        totalAreaSqMeters: t.areaSqMeters,
        rank: i + 1,
      );
    });
  }

  @override
  Future<List<LeaderboardEntryEntity>> getNearbyLeaderboard(
    GeoPointEntity viewerLocation, {
    double radiusMeters = 5000,
  }) async {
    await _ensureLoaded();
    final nearby = _cachedTerritories!.where((t) {
      for (final poly in t.polygons) {
        for (final pt in poly) {
          if (GeoUtils.haversineMeters(viewerLocation, pt) <= radiusMeters) {
            return true;
          }
        }
      }
      return false;
    }).toList();

    nearby.sort((a, b) => b.areaSqMeters.compareTo(a.areaSqMeters));

    return List.generate(nearby.length, (i) {
      final t = nearby[i];
      return LeaderboardEntryEntity(
        userId: t.userId,
        displayName: t.ownerDisplayName,
        totalAreaSqMeters: t.areaSqMeters,
        rank: i + 1,
      );
    });
  }

  @override
  Future<List<LeaderboardEntryEntity>> getWindowedLeaderboard({
    required int windowHours,
    GeoPointEntity? viewerLocation,
    double radiusMeters = 5000,
  }) {
    // Offline/local mode keeps no capture-history log (only current
    // territory state is persisted), so a time-windowed "momentum" board
    // isn't representable — fall back to current standings, same as the
    // all-time board. This only affects signed-out users.
    return viewerLocation == null
        ? getGlobalLeaderboard()
        : getNearbyLeaderboard(viewerLocation, radiusMeters: radiusMeters);
  }

  @override
  Future<List<DecayWarningEntity>> getDecayWarnings() async {
    await _ensureLoaded();
    final now = DateTime.now();
    final warnings = <DecayWarningEntity>[];
    for (final t in _cachedTerritories!) {
      if (t.userId != _currentUserId) continue;
      final age = now.difference(t.lastDefendedAt);
      final daysLeft = AppConstants.territoryDecayGracePeriod.inDays -
          (age.inSeconds / (24 * 3600));
      if (daysLeft <= 2.0 && daysLeft > 0) {
        warnings.add(DecayWarningEntity(
          territoryId: t.id,
          daysUntilDecay: daysLeft,
          areaSqMeters: t.areaSqMeters,
        ));
      }
    }
    return warnings;
  }

  // --- Geometry Helpers ---

  double _calculatePolygonArea(List<GeoPointEntity> points) {
    if (points.length < 3) return 0.0;
    final ref = points.first;
    final latRad = ref.latitude * math.pi / 180.0;
    const metersPerDegreeLat = 111320.0;
    final metersPerDegreeLon = 111320.0 * math.cos(latRad);

    final List<(double, double)> projected = [];
    for (final p in points) {
      final x = (p.longitude - ref.longitude) * metersPerDegreeLon;
      final y = (p.latitude - ref.latitude) * metersPerDegreeLat;
      projected.add((x, y));
    }

    double area = 0.0;
    final n = projected.length;
    for (var i = 0; i < n; i++) {
      final current = projected[i];
      final next = projected[(i + 1) % n];
      area += (current.$1 * next.$2) - (next.$1 * current.$2);
    }
    return area.abs() / 2.0;
  }

  ({double minLat, double maxLat, double minLon, double maxLon})
      _getBoundingBox(List<GeoPointEntity> points) {
    if (points.isEmpty) {
      return (minLat: 0.0, maxLat: 0.0, minLon: 0.0, maxLon: 0.0);
    }
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLon = points.first.longitude;
    double maxLon = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLon) minLon = p.longitude;
      if (p.longitude > maxLon) maxLon = p.longitude;
    }
    return (minLat: minLat, maxLat: maxLat, minLon: minLon, maxLon: maxLon);
  }

  bool _boundingBoxesIntersect(
    ({double minLat, double maxLat, double minLon, double maxLon}) a,
    ({double minLat, double maxLat, double minLon, double maxLon}) b,
  ) {
    return a.minLat <= b.maxLat &&
        a.maxLat >= b.minLat &&
        a.minLon <= b.maxLon &&
        a.maxLon >= b.minLon;
  }

  bool _isPointInPolygon(GeoPointEntity p, List<GeoPointEntity> polygon) {
    var intersectCount = 0;
    for (var i = 0; i < polygon.length; i++) {
      final nextIndex = (i + 1) % polygon.length;
      final p1 = polygon[i];
      final p2 = polygon[nextIndex];
      if ((p1.latitude > p.latitude) != (p2.latitude > p.latitude)) {
        final xIntersection = (p2.longitude - p1.longitude) *
                (p.latitude - p1.latitude) /
                (p2.latitude - p1.latitude) +
            p1.longitude;
        if (p.longitude < xIntersection) {
          intersectCount++;
        }
      }
    }
    return intersectCount % 2 != 0;
  }

  // --- Serialization Helpers ---

  Map<String, dynamic> _geoPointToJson(GeoPointEntity point) => {
        'latitude': point.latitude,
        'longitude': point.longitude,
        'timestamp': point.timestamp.toIso8601String(),
      };

  GeoPointEntity _geoPointFromJson(Map<String, dynamic> json) => GeoPointEntity(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> _territoryToJson(TerritoryEntity t) => {
        'id': t.id,
        'user_id': t.userId,
        'owner_display_name': t.ownerDisplayName,
        'polygons': t.polygons
            .map((ring) => ring.map(_geoPointToJson).toList())
            .toList(),
        'area_sq_meters': t.areaSqMeters,
        'last_defended_at': t.lastDefendedAt.toIso8601String(),
      };

  TerritoryEntity _territoryFromJson(Map<String, dynamic> json) =>
      TerritoryEntity(
        id: json['id'] as String,
        userId: json['user_id'] as String,
        ownerDisplayName: json['owner_display_name'] as String?,
        polygons: (json['polygons'] as List<dynamic>)
            .map((ring) => (ring as List<dynamic>)
                .map((pt) => _geoPointFromJson(pt as Map<String, dynamic>))
                .toList())
            .toList(),
        areaSqMeters: (json['area_sq_meters'] as num).toDouble(),
        lastDefendedAt: DateTime.parse(json['last_defended_at'] as String),
        isOwnedByCurrentUser: json['user_id'] as String == _currentUserId,
      );

  Map<String, dynamic> _runTrackToJson(RunTrackEntity run) => {
        'points': run.points.map(_geoPointToJson).toList(),
        'distance_meters': run.distanceMeters,
        'duration_seconds': run.duration.inSeconds,
        'outcome': run.outcome.name,
      };

  RunTrackEntity _runTrackFromJson(Map<String, dynamic> json) => RunTrackEntity(
        points: (json['points'] as List<dynamic>)
            .map((pt) => _geoPointFromJson(pt as Map<String, dynamic>))
            .toList(),
        distanceMeters: (json['distance_meters'] as num).toDouble(),
        duration: Duration(seconds: json['duration_seconds'] as int),
        outcome: RunOutcome.values.byName(json['outcome'] as String),
      );
}
