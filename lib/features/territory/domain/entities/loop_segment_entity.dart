import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:flutter/foundation.dart';

/// A closed GPS path segment extracted from a longer run session.
@immutable
class LoopSegmentEntity {
  const LoopSegmentEntity({
    required this.startIndex,
    required this.endIndex,
    required this.points,
    required this.closedAt,
  });

  /// Index into the parent run's full point list where this segment begins.
  final int startIndex;

  /// Index into the parent run's full point list where closure was detected.
  final int endIndex;

  /// GPS fixes from [startIndex] through [endIndex] inclusive.
  final List<GeoPointEntity> points;

  /// Timestamp of the closure fix.
  final DateTime closedAt;
}
