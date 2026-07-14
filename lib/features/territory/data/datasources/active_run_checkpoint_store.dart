import 'dart:convert';

import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/loop_segment_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Durable snapshot of an in-progress territory run so the session survives
/// process death (user swipes the app away / OS kills the isolate).
class ActiveRunCheckpoint {
  const ActiveRunCheckpoint({
    required this.statusName,
    required this.points,
    required this.distanceMeters,
    required this.elapsed,
    required this.startTime,
    required this.pausedAccumulated,
    required this.sawSustainedOverSpeed,
    required this.pendingLoops,
    required this.currentSegmentAnchorIndex,
    required this.loopTrackerAnchorIndex,
    required this.loopTrackerMaxDistFromAnchor,
    required this.loopTrackerClosureArmed,
    this.gpsAccuracyMeters,
  });

  /// [RunSessionStatus.name] — only `tracking` / `paused` are resumable.
  final String statusName;
  final List<GeoPointEntity> points;
  final double distanceMeters;
  final Duration elapsed;
  final DateTime startTime;
  final Duration pausedAccumulated;
  final bool sawSustainedOverSpeed;
  final List<LoopSegmentEntity> pendingLoops;
  final int currentSegmentAnchorIndex;
  final int loopTrackerAnchorIndex;
  final double loopTrackerMaxDistFromAnchor;
  final bool loopTrackerClosureArmed;
  final double? gpsAccuracyMeters;

  bool get isResumable => statusName == 'tracking' || statusName == 'paused';

  Map<String, dynamic> toJson() => {
    'status': statusName,
    'distance_meters': distanceMeters,
    'elapsed_ms': elapsed.inMilliseconds,
    'start_time': startTime.toIso8601String(),
    'paused_accumulated_ms': pausedAccumulated.inMilliseconds,
    'saw_sustained_over_speed': sawSustainedOverSpeed,
    'current_segment_anchor_index': currentSegmentAnchorIndex,
    'loop_tracker_anchor_index': loopTrackerAnchorIndex,
    'loop_tracker_max_dist_from_anchor': loopTrackerMaxDistFromAnchor,
    'loop_tracker_closure_armed': loopTrackerClosureArmed,
    if (gpsAccuracyMeters != null) 'gps_accuracy_meters': gpsAccuracyMeters,
    'points': points.map(_pointToJson).toList(),
    'pending_loops': pendingLoops.map(_loopToJson).toList(),
  };

  factory ActiveRunCheckpoint.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? const [];
    final rawLoops = json['pending_loops'] as List<dynamic>? ?? const [];
    return ActiveRunCheckpoint(
      statusName: json['status'] as String? ?? 'idle',
      points: rawPoints
          .map((raw) => _pointFromJson(raw as Map<String, dynamic>))
          .toList(),
      distanceMeters: (json['distance_meters'] as num?)?.toDouble() ?? 0,
      elapsed: Duration(milliseconds: json['elapsed_ms'] as int? ?? 0),
      startTime: DateTime.parse(json['start_time'] as String),
      pausedAccumulated: Duration(
        milliseconds: json['paused_accumulated_ms'] as int? ?? 0,
      ),
      sawSustainedOverSpeed: json['saw_sustained_over_speed'] as bool? ?? false,
      pendingLoops: rawLoops
          .map((raw) => _loopFromJson(raw as Map<String, dynamic>))
          .toList(),
      currentSegmentAnchorIndex:
          json['current_segment_anchor_index'] as int? ?? 0,
      loopTrackerAnchorIndex: json['loop_tracker_anchor_index'] as int? ?? 0,
      loopTrackerMaxDistFromAnchor:
          (json['loop_tracker_max_dist_from_anchor'] as num?)?.toDouble() ?? 0,
      loopTrackerClosureArmed:
          json['loop_tracker_closure_armed'] as bool? ?? false,
      gpsAccuracyMeters: (json['gps_accuracy_meters'] as num?)?.toDouble(),
    );
  }

  static Map<String, dynamic> _pointToJson(GeoPointEntity p) => {
    'lat': p.latitude,
    'lng': p.longitude,
    'timestamp': p.timestamp.toIso8601String(),
  };

  static GeoPointEntity _pointFromJson(Map<String, dynamic> m) =>
      GeoPointEntity(
        latitude: (m['lat'] as num).toDouble(),
        longitude: (m['lng'] as num).toDouble(),
        timestamp: DateTime.parse(m['timestamp'] as String),
      );

  static Map<String, dynamic> _loopToJson(LoopSegmentEntity loop) => {
    'start_index': loop.startIndex,
    'end_index': loop.endIndex,
    'closed_at': loop.closedAt.toIso8601String(),
    'points': loop.points.map(_pointToJson).toList(),
  };

  static LoopSegmentEntity _loopFromJson(Map<String, dynamic> m) {
    final rawPoints = m['points'] as List<dynamic>? ?? const [];
    return LoopSegmentEntity(
      startIndex: m['start_index'] as int? ?? 0,
      endIndex: m['end_index'] as int? ?? 0,
      closedAt: DateTime.parse(m['closed_at'] as String),
      points: rawPoints
          .map((raw) => _pointFromJson(raw as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// SharedPreferences-backed active-run checkpoint.
class ActiveRunCheckpointStore {
  const ActiveRunCheckpointStore();

  static const String prefsKey = 'awaken_active_run_checkpoint';

  Future<void> save(ActiveRunCheckpoint checkpoint) async {
    if (!checkpoint.isResumable) {
      await clear();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, jsonEncode(checkpoint.toJson()));
  }

  Future<ActiveRunCheckpoint?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final checkpoint = ActiveRunCheckpoint.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      if (!checkpoint.isResumable) {
        await clear();
        return null;
      }
      return checkpoint;
    } on Object {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey);
  }
}
