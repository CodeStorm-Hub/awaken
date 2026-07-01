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
