import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/entities/loop_segment_entity.dart';
import 'package:awaken/features/territory/domain/entities/run_track_entity.dart';
import 'package:awaken/features/territory/domain/services/geo_utils.dart';
import 'package:awaken/features/territory/domain/services/loop_segment_extractor.dart';

/// Applies the anti-cheat and loop-closure rules from the implementation
/// plan to a finished run: sustained speed cap, min duration/distance, and
/// segment-based loop closure. Server-side `capture_territory` independently
/// enforces the minimum loop area — this is the client-side pre-check so a
/// doomed run doesn't waste a round-trip.
abstract final class RunValidationService {
  /// Checks a rolling window of the most recent fixes for sustained
  /// over-speed — a single GPS jump should not invalidate a run, but
  /// `AppConstants.speedRollingWindowSize` consecutive fast pings should.
  static bool isSustainedOverSpeed(List<GeoPointEntity> recentPoints) {
    if (recentPoints.length < 2) return false;
    final window = recentPoints.length > AppConstants.speedRollingWindowSize
        ? recentPoints.sublist(
            recentPoints.length - AppConstants.speedRollingWindowSize,
          )
        : recentPoints;

    for (var i = 1; i < window.length; i++) {
      if (GeoUtils.speedKmh(window[i - 1], window[i]) <=
          AppConstants.maxRunSpeedKmh) {
        return false;
      }
    }
    return true;
  }

  static bool isClosedLoop(List<GeoPointEntity> points) {
    if (points.length < 2) return false;
    return GeoUtils.haversineMeters(points.first, points.last) <=
        AppConstants.loopClosureRadiusMeters;
  }

  /// Extracts all valid closed-loop segments from a run path (supports
  /// overrun past the start and multiple loops per session).
  static List<LoopSegmentEntity> extractLoopSegments(
    List<GeoPointEntity> points,
  ) {
    return LoopSegmentExtractor.extract(points);
  }

  /// Classifies a finished run into its outcome per §2 of the
  /// implementation plan. Does not check minimum loop area — that's
  /// enforced server-side against the true polygon, not the raw path.
  ///
  /// When [loopSegments] is non-empty the run is treated as having closed
  /// at least one loop, even if the final GPS fix is far from the start.
  static RunOutcome classify({
    required List<GeoPointEntity> points,
    required double distanceMeters,
    required Duration duration,
    required bool wasInvalidatedBySpeed,
    List<LoopSegmentEntity> loopSegments = const [],
  }) {
    if (wasInvalidatedBySpeed) return RunOutcome.invalidatedSpeedCap;

    if (duration < AppConstants.minRunDuration ||
        distanceMeters < AppConstants.minRunDistanceMeters) {
      return RunOutcome.invalidatedTooShort;
    }

    final segments = loopSegments.isNotEmpty
        ? loopSegments
        : extractLoopSegments(points);
    if (segments.isEmpty && !isClosedLoop(points)) {
      return RunOutcome.loopNotClosed;
    }

    return RunOutcome.territoryClaimed;
  }
}
