import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/loop_segment_entity.dart';
import 'package:awaken/features/territory/domain/services/geo_utils.dart';

/// Tracks incremental loop-closure state during a live GPS run.
///
/// Mirrors the batch rules in [LoopSegmentExtractor.extract] so live
/// detection and finish-time re-extraction stay consistent.
class LoopClosureTracker {
  LoopClosureTracker({
    this.anchorIndex = 0,
    this.maxDistFromAnchor = 0,
    this.closureArmed = false,
  });

  int anchorIndex;
  double maxDistFromAnchor;
  bool closureArmed;

  /// Evaluates the latest fix. Returns a new [LoopSegmentEntity] when a valid
  /// closure is detected, otherwise null.
  LoopSegmentEntity? evaluate(
    List<GeoPointEntity> points, {
    double? gpsAccuracyMeters,
  }) {
    if (points.length < 2) return null;
    final i = points.length - 1;
    if (i <= anchorIndex) return null;

    final anchor = points[anchorIndex];
    final current = points[i];
    final distToAnchor = GeoUtils.haversineMeters(current, anchor);
    final segmentDist = GeoUtils.pathDistanceMeters(
      points.sublist(anchorIndex, i + 1),
    );

    if (distToAnchor > maxDistFromAnchor) {
      maxDistFromAnchor = distToAnchor;
    }
    if (distToAnchor >= AppConstants.loopExitRadiusMeters) {
      closureArmed = true;
    }

    if (!_canClose(
      segmentDist: segmentDist,
      distToAnchor: distToAnchor,
      pointCount: i - anchorIndex + 1,
      gpsAccuracyMeters: gpsAccuracyMeters,
    )) {
      return null;
    }

    final segment = LoopSegmentEntity(
      startIndex: anchorIndex,
      endIndex: i,
      points: List<GeoPointEntity>.unmodifiable(
        points.sublist(anchorIndex, i + 1),
      ),
      closedAt: current.timestamp,
    );

    anchorIndex = i;
    maxDistFromAnchor = 0;
    closureArmed = false;
    return segment;
  }

  bool _canClose({
    required double segmentDist,
    required double distToAnchor,
    required int pointCount,
    required double? gpsAccuracyMeters,
  }) {
    if (!closureArmed) return false;
    if (segmentDist < AppConstants.minLoopSegmentDistanceMeters) return false;
    if (maxDistFromAnchor < AppConstants.loopClosureGraceMeters) return false;
    if (distToAnchor > AppConstants.loopClosureRadiusMeters) return false;
    if (pointCount <= AppConstants.minLoopSegmentPointCount) return false;
    if (gpsAccuracyMeters != null &&
        gpsAccuracyMeters > AppConstants.loopClosureRadiusMeters) {
      return false;
    }
    return true;
  }
}

/// Extracts all valid closed-loop segments from a full run path.
abstract final class LoopSegmentExtractor {
  static List<LoopSegmentEntity> extract(List<GeoPointEntity> points) {
    if (points.length < 2) return const [];

    final tracker = LoopClosureTracker();
    final segments = <LoopSegmentEntity>[];

    for (var i = 1; i < points.length; i++) {
      final partial = points.sublist(0, i + 1);
      final segment = tracker.evaluate(partial);
      if (segment != null) {
        segments.add(segment);
        if (segments.length >= AppConstants.maxLoopsPerSession) break;
      }
    }

    return segments;
  }
}
