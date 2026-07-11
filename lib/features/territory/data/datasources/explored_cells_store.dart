import 'dart:convert';
import 'dart:math' as math;

import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local fog-of-war explored-cell store (~70m geohash-like grid).
class ExploredCellsStore {
  ExploredCellsStore({this._prefs});

  static const _prefsKey = 'territory_explored_cells_v1';

  SharedPreferences? _prefs;
  final Set<String> _cells = {};

  Future<void> load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = (jsonDecode(raw) as List<dynamic>).cast<String>();
      _cells
        ..clear()
        ..addAll(list);
    } catch (_) {
      // Corrupt payload — start fresh.
      _cells.clear();
    }
  }

  Set<String> get cells => Set.unmodifiable(_cells);

  bool get isEmpty => _cells.isEmpty;

  static String cellKey(double lat, double lng) {
    const step = AppConstants.fogCellDegrees;
    final i = (lat / step).floor();
    final j = (lng / step).floor();
    return '$i:$j';
  }

  static (double, double) cellCenter(String key) {
    final parts = key.split(':');
    final i = int.parse(parts[0]);
    final j = int.parse(parts[1]);
    const step = AppConstants.fogCellDegrees;
    return ((i + 0.5) * step, (j + 0.5) * step);
  }

  /// Marks cells along a polyline (and a small radius around the user).
  Future<void> revealPath(List<GeoPointEntity> points) async {
    if (points.isEmpty) return;
    _prefs ??= await SharedPreferences.getInstance();
    for (final p in points) {
      _cells.add(cellKey(p.latitude, p.longitude));
      // Soften GPS jitter: also mark 8-neighbors.
      const step = AppConstants.fogCellDegrees;
      for (var di = -1; di <= 1; di++) {
        for (var dj = -1; dj <= 1; dj++) {
          _cells.add(cellKey(
            p.latitude + di * step,
            p.longitude + dj * step,
          ));
        }
      }
    }
    await _persist();
  }

  Future<void> revealAround(double lat, double lng, {int radiusCells = 2}) async {
    _prefs ??= await SharedPreferences.getInstance();
    const step = AppConstants.fogCellDegrees;
    for (var di = -radiusCells; di <= radiusCells; di++) {
      for (var dj = -radiusCells; dj <= radiusCells; dj++) {
        if (di * di + dj * dj > radiusCells * radiusCells) continue;
        _cells.add(cellKey(lat + di * step, lng + dj * step));
      }
    }
    await _persist();
  }

  Future<void> mergeRemoteCells(Iterable<String> remote) async {
    _prefs ??= await SharedPreferences.getInstance();
    final before = _cells.length;
    _cells.addAll(remote);
    if (_cells.length != before) await _persist();
  }

  Future<void> _persist() async {
    // Cap growth so prefs stay bounded.
    if (_cells.length > 8000) {
      final trimmed = _cells.toList()
        ..sort()
        ..removeRange(0, _cells.length - 8000);
      _cells
        ..clear()
        ..addAll(trimmed);
    }
    await _prefs!.setString(_prefsKey, jsonEncode(_cells.toList()));
  }

  /// Builds fog polygons covering [bounds] minus revealed cells.
  /// Returns opaque rectangles for unexplored cells in the viewport.
  List<List<(double lat, double lng)>> fogRectsForViewport({
    required double south,
    required double north,
    required double west,
    required double east,
    int maxCells = 900,
  }) {
    const step = AppConstants.fogCellDegrees;
    final i0 = (south / step).floor() - 1;
    final i1 = (north / step).ceil() + 1;
    final j0 = (west / step).floor() - 1;
    final j1 = (east / step).ceil() + 1;

    final rows = i1 - i0;
    final cols = j1 - j0;
    if (rows * cols > maxCells) {
      // Coarsen when zoomed out so we don't explode polygon count.
      final factor = math.sqrt(rows * cols / maxCells).ceil();
      return _coarseFog(
        i0: i0,
        i1: i1,
        j0: j0,
        j1: j1,
        factor: factor,
        step: step,
      );
    }

    final rects = <List<(double, double)>>[];
    for (var i = i0; i < i1; i++) {
      for (var j = j0; j < j1; j++) {
        final key = '$i:$j';
        if (_cells.contains(key)) continue;
        final lat0 = i * step;
        final lng0 = j * step;
        rects.add([
          (lat0, lng0),
          (lat0, lng0 + step),
          (lat0 + step, lng0 + step),
          (lat0 + step, lng0),
        ]);
      }
    }
    return rects;
  }

  List<List<(double, double)>> _coarseFog({
    required int i0,
    required int i1,
    required int j0,
    required int j1,
    required int factor,
    required double step,
  }) {
    final rects = <List<(double, double)>>[];
    for (var i = i0; i < i1; i += factor) {
      for (var j = j0; j < j1; j += factor) {
        var anyRevealed = false;
        for (var di = 0; di < factor && !anyRevealed; di++) {
          for (var dj = 0; dj < factor; dj++) {
            if (_cells.contains('${i + di}:${j + dj}')) {
              anyRevealed = true;
              break;
            }
          }
        }
        if (anyRevealed) continue;
        final lat0 = i * step;
        final lng0 = j * step;
        final size = step * factor;
        rects.add([
          (lat0, lng0),
          (lat0, lng0 + size),
          (lat0 + size, lng0 + size),
          (lat0 + size, lng0),
        ]);
      }
    }
    return rects;
  }
}
