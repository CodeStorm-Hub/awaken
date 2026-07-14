import 'dart:convert';

import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A closed-loop capture that failed to sync remotely and should be retried.
class PendingCapture {
  const PendingCapture({
    required this.id,
    required this.points,
    required this.enqueuedAt,
  });

  final String id;
  final List<GeoPointEntity> points;
  final DateTime enqueuedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'enqueued_at': enqueuedAt.toIso8601String(),
    'points': points
        .map(
          (p) => {
            'lat': p.latitude,
            'lng': p.longitude,
            'timestamp': p.timestamp.toIso8601String(),
          },
        )
        .toList(),
  };

  factory PendingCapture.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'] as List<dynamic>? ?? const [];
    return PendingCapture(
      id: json['id'] as String,
      enqueuedAt: DateTime.parse(json['enqueued_at'] as String),
      points: rawPoints.map((raw) {
        final m = raw as Map<String, dynamic>;
        return GeoPointEntity(
          latitude: (m['lat'] as num).toDouble(),
          longitude: (m['lng'] as num).toDouble(),
          timestamp: DateTime.parse(m['timestamp'] as String),
        );
      }).toList(),
    );
  }
}

/// SharedPreferences-backed queue of territory captures that failed remotely.
class PendingCaptureQueue {
  const PendingCaptureQueue();

  static const String _queueKey = 'awaken_pending_capture_sync_queue';

  Future<List<PendingCapture>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_queueKey) ?? [];
    return jsonList
        .map(
          (jsonStr) => PendingCapture.fromJson(
            jsonDecode(jsonStr) as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<void> _writeAll(List<PendingCapture> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _queueKey,
      items.map((c) => jsonEncode(c.toJson())).toList(),
    );
  }

  Future<void> enqueue(PendingCapture capture) async {
    final items = await _readAll();
    if (items.any((c) => c.id == capture.id)) return;
    items.add(capture);
    await _writeAll(items);
  }

  Future<List<PendingCapture>> peek() => _readAll();

  Future<void> remove(String id) async {
    final items = await _readAll();
    items.removeWhere((c) => c.id == id);
    await _writeAll(items);
  }
}
