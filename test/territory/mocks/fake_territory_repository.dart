import 'dart:async';
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

class FakeTerritoryRepository implements TerritoryRepository {
  final List<TerritoryEntity> territories = [];
  final List<RunTrackEntity> recordedRuns = [];
  final StreamController<List<TerritoryEntity>> _controller = StreamController<List<TerritoryEntity>>.broadcast();

  String currentUserId = 'user-1';
  String currentUserDisplayName = 'Player 1';

  @override
  Future<List<TerritoryEntity>> getAllTerritories() async {
    return List.unmodifiable(territories);
  }

  @override
  Stream<List<TerritoryEntity>> watchTerritories() {
    // Emit initial state immediately on new subscription
    Timer.run(() {
      if (!_controller.isClosed) {
        _controller.add(List.unmodifiable(territories));
      }
    });
    return _controller.stream;
  }

  @override
  Future<void> recordRun(RunTrackEntity run) async {
    recordedRuns.add(run);
  }

  @override
  Future<CaptureResultEntity> captureTerritory(List<GeoPointEntity> loopPoints) async {
    final area = calculatePolygonArea(loopPoints);
    if (area < AppConstants.minLoopAreaSqMeters) {
      throw Exception('loop_too_small: Enclosed area of ${area.toStringAsFixed(1)} m² is below the minimum of ${AppConstants.minLoopAreaSqMeters} m²');
    }

    final userId = currentUserId;
    final displayName = currentUserDisplayName;

    // Find the current user's existing territory index
    final userTerritoryIndex = territories.indexWhere((t) => t.userId == userId);

    List<PolygonRing> userPolygons = [];
    if (userTerritoryIndex != -1) {
      userPolygons = List.from(territories[userTerritoryIndex].polygons);
    }

    int rivalsAffected = 0;
    final newBbox = _getBoundingBox(loopPoints);

    final List<TerritoryEntity> updatedRivalTerritories = [];

    // Process rival stealing (ST_Difference simulation)
    for (final t in territories) {
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
            
            // Calculate overlap and subtract
            final overlapBbox = _getBoundingBoxIntersection(newBbox, rivalBbox);
            final overlapArea = overlapBbox != null ? _getBboxArea(overlapBbox) : 0.0;
            final actualOverlap = math.min(overlapArea, calculatePolygonArea(poly));
            final newRivalPolyArea = calculatePolygonArea(poly) - actualOverlap;

              if (newRivalPolyArea < 1.0) {
                // Sliver cleanup: polygon completely stolen/deleted
                continue;
              } else {
                // Partial reduction of coordinates falling inside User's loop
                final isInside = poly.map((p) => _isPointInPolygon(p, loopPoints)).toList();
                if (!isInside.contains(true)) {
                  remainingRivalPolygons.add(poly);
                  rivalArea += calculatePolygonArea(poly);
                } else if (!isInside.contains(false)) {
                  continue; // completely inside
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
                  
                  if (runs.isNotEmpty) {
                    for (final run in runs) {
                      remainingRivalPolygons.add(run);
                      rivalArea += calculatePolygonArea(run);
                    }
                  }
                }
              }
          } else {
            remainingRivalPolygons.add(poly);
            rivalArea += calculatePolygonArea(poly);
          }
        } else {
          remainingRivalPolygons.add(poly);
          rivalArea += calculatePolygonArea(poly);
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
          final allInside = loopPoints.every((p) => _isPointInPolygon(p, poly));
          if (allInside) {
            mergedPolygons.add(poly);
          } else {
            final mergedPoints = <GeoPointEntity>[];
            mergedPoints.addAll(poly);
            for (final p in loopPoints) {
              if (!mergedPoints.any((mp) => mp.latitude == p.latitude && mp.longitude == p.longitude)) {
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
      totalUserArea += calculatePolygonArea(poly);
    }

    final userTerritory = TerritoryEntity(
      id: userTerritoryIndex != -1 ? territories[userTerritoryIndex].id : 'territory-$userId',
      userId: userId,
      ownerDisplayName: displayName,
      polygons: mergedPolygons,
      areaSqMeters: totalUserArea,
      lastDefendedAt: DateTime.now(),
      isOwnedByCurrentUser: true,
    );

    territories.clear();
    territories.addAll(updatedRivalTerritories);
    territories.add(userTerritory);

    _controller.add(List.unmodifiable(territories));

    return CaptureResultEntity(
      claimedAreaSqMeters: area,
      totalOwnedAreaSqMeters: totalUserArea,
      rivalsAffected: rivalsAffected,
    );
  }

  @override
  Future<void> touchDefense(List<GeoPointEntity> path) async {
    final userId = currentUserId;
    final idx = territories.indexWhere((t) => t.userId == userId);
    if (idx == -1) return;

    final t = territories[idx];
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
      territories[idx] = TerritoryEntity(
        id: t.id,
        userId: t.userId,
        ownerDisplayName: t.ownerDisplayName,
        polygons: t.polygons,
        areaSqMeters: t.areaSqMeters,
        lastDefendedAt: DateTime.now(),
        isOwnedByCurrentUser: true,
      );
      _controller.add(List.unmodifiable(territories));
    }
  }

  @override
  Future<List<LeaderboardEntryEntity>> getGlobalLeaderboard() async {
    final sorted = List<TerritoryEntity>.from(territories)
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
    final nearby = territories.where((t) {
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
  Future<List<DecayWarningEntity>> getDecayWarnings() async {
    final now = DateTime.now();
    final warnings = <DecayWarningEntity>[];
    for (final t in territories) {
      if (t.userId != currentUserId) continue;
      final age = now.difference(t.lastDefendedAt);
      final daysLeft = AppConstants.territoryDecayGracePeriod.inDays - (age.inSeconds / (24 * 3600));
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

  void simulateDecay(Duration ageOffset) {
    final now = DateTime.now();
    for (var i = 0; i < territories.length; i++) {
      final t = territories[i];
      final newLastDefended = t.lastDefendedAt.subtract(ageOffset);
      final age = now.difference(newLastDefended);
      
      double newArea = t.areaSqMeters;
      List<PolygonRing> newPolygons = List.from(t.polygons);
      
      if (age > AppConstants.territoryDecayGracePeriod) {
        final decaySeconds = age.inSeconds - AppConstants.territoryDecayGracePeriod.inSeconds;
        final decayDays = decaySeconds / (24 * 3600.0);
        final shrinkAmount = math.max(0.0, decayDays * 5.0);
        newArea = math.max(0.0, t.areaSqMeters - shrinkAmount);
        
        if (newArea < 1.0) {
          newArea = 0.0;
          newPolygons = [];
        }
      }
      
      territories[i] = TerritoryEntity(
        id: t.id,
        userId: t.userId,
        ownerDisplayName: t.ownerDisplayName,
        polygons: newPolygons,
        areaSqMeters: newArea,
        lastDefendedAt: newLastDefended,
        isOwnedByCurrentUser: t.isOwnedByCurrentUser,
      );
    }
    _controller.add(List.unmodifiable(territories));
  }

  void close() {
    _controller.close();
  }

  // --- Helper Geometry Functions ---

  double calculatePolygonArea(List<GeoPointEntity> points) {
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

  ({double minLat, double maxLat, double minLon, double maxLon}) _getBoundingBox(List<GeoPointEntity> points) {
    if (points.isEmpty) return (minLat: 0.0, maxLat: 0.0, minLon: 0.0, maxLon: 0.0);
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

  ({double minLat, double maxLat, double minLon, double maxLon})? _getBoundingBoxIntersection(
    ({double minLat, double maxLat, double minLon, double maxLon}) a,
    ({double minLat, double maxLat, double minLon, double maxLon}) b,
  ) {
    if (!_boundingBoxesIntersect(a, b)) return null;
    return (
      minLat: math.max(a.minLat, b.minLat),
      maxLat: math.min(a.maxLat, b.maxLat),
      minLon: math.max(a.minLon, b.minLon),
      maxLon: math.min(a.maxLon, b.maxLon),
    );
  }

  double _getBboxArea(({double minLat, double maxLat, double minLon, double maxLon}) bbox) {
    final latRad = bbox.minLat * math.pi / 180.0;
    const metersPerDegreeLat = 111320.0;
    final metersPerDegreeLon = 111320.0 * math.cos(latRad);
    final width = (bbox.maxLon - bbox.minLon).abs() * metersPerDegreeLon;
    final height = (bbox.maxLat - bbox.minLat).abs() * metersPerDegreeLat;
    return width * height;
  }

  bool _isPointInPolygon(GeoPointEntity p, List<GeoPointEntity> polygon) {
    var intersectCount = 0;
    for (var i = 0; i < polygon.length; i++) {
      final nextIndex = (i + 1) % polygon.length;
      final p1 = polygon[i];
      final p2 = polygon[nextIndex];
      if ((p1.latitude > p.latitude) != (p2.latitude > p.latitude)) {
        final xIntersection = (p2.longitude - p1.longitude) * (p.latitude - p1.latitude) / (p2.latitude - p1.latitude) + p1.longitude;
        if (p.longitude < xIntersection) {
          intersectCount++;
        }
      }
    }
    return intersectCount % 2 != 0;
  }
}
