import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:flutter/foundation.dart';

/// Outcome of validating a finished run against the anti-cheat / loop rules.
enum RunOutcome {
  /// Closed loop, passed all checks — territory was claimed.
  territoryClaimed,

  /// Valid workout, but the path never closed into a loop near its start.
  loopNotClosed,

  /// Sustained speed exceeded [AppConstants.maxRunSpeedKmh] — likely a vehicle.
  invalidatedSpeedCap,

  /// Enclosed area was below [AppConstants.minLoopAreaSqMeters].
  invalidatedTooSmall,

  /// Didn't meet the minimum time/distance traversal constraints.
  invalidatedTooShort,
}

/// A completed (or in-progress) run: the recorded path plus derived stats.
@immutable
class RunTrackEntity {
  const RunTrackEntity({
    required this.points,
    required this.distanceMeters,
    required this.duration,
    required this.outcome,
  });

  final List<GeoPointEntity> points;
  final double distanceMeters;
  final Duration duration;
  final RunOutcome outcome;

  bool get isClosedLoop => outcome == RunOutcome.territoryClaimed;
}
