import 'package:flutter/foundation.dart';

/// Result of a successful `capture_territory` RPC call.
@immutable
class CaptureResultEntity {
  const CaptureResultEntity({
    required this.claimedAreaSqMeters,
    required this.totalOwnedAreaSqMeters,
    required this.rivalsAffected,
  });

  final double claimedAreaSqMeters;
  final double totalOwnedAreaSqMeters;

  /// How many distinct rival territories this capture cut into — drives
  /// haptic/UI feedback for "steal" vs. plain "claim".
  final int rivalsAffected;

  bool get stoleFromRival => rivalsAffected > 0;
}

/// Aggregated outcome when multiple loops are captured in one run session.
@immutable
class SessionCaptureResultEntity {
  const SessionCaptureResultEntity({
    required this.captures,
    required this.loopsCaptured,
    required this.loopsAttempted,
    required this.loopsRejectedTooSmall,
  });

  final List<CaptureResultEntity> captures;
  final int loopsCaptured;
  final int loopsAttempted;
  final int loopsRejectedTooSmall;

  double get totalClaimedAreaSqMeters =>
      captures.fold(0.0, (sum, c) => sum + c.claimedAreaSqMeters);

  double get totalOwnedAreaSqMeters =>
      captures.isEmpty ? 0 : captures.last.totalOwnedAreaSqMeters;

  int get totalRivalsAffected =>
      captures.fold(0, (sum, c) => sum + c.rivalsAffected);

  bool get stoleFromRival => totalRivalsAffected > 0;

  bool get hasPartialFailure =>
      loopsRejectedTooSmall > 0 && loopsCaptured > 0;
}
