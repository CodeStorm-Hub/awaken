import 'package:flutter/foundation.dart';

/// The user's nemesis — the rival with whom the most territory has been
/// mutually contested. Returned by the `get_nemesis` RPC.
@immutable
class NemesisEntity {
  const NemesisEntity({
    required this.rivalUserId,
    required this.rivalDisplayName,
    required this.mutualStealCount,
    required this.myDisputedSqMeters,
    required this.rivalDisputedSqMeters,
  });

  final String rivalUserId;
  final String rivalDisplayName;

  /// Total number of territories stolen between both users (in either direction).
  final int mutualStealCount;

  /// Square metres the current user has had stolen by the rival.
  final double myDisputedSqMeters;

  /// Square metres the rival has had stolen by the current user.
  final double rivalDisputedSqMeters;

  /// Parses a row from the `get_nemesis` RPC result set.
  factory NemesisEntity.fromRpc(Map<String, dynamic> row) {
    return NemesisEntity(
      rivalUserId: row['rival_user_id'] as String,
      rivalDisplayName: (row['rival_display_name'] as String?) ?? 'Unknown',
      mutualStealCount: (row['mutual_steal_count'] as num?)?.toInt() ?? 0,
      myDisputedSqMeters:
          (row['my_disputed_sq_meters'] as num?)?.toDouble() ?? 0.0,
      rivalDisputedSqMeters:
          (row['rival_disputed_sq_meters'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Total disputed area for both sides — used for proportional bar widths.
  double get totalDisputedSqMeters =>
      myDisputedSqMeters + rivalDisputedSqMeters;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NemesisEntity &&
          runtimeType == other.runtimeType &&
          rivalUserId == other.rivalUserId;

  @override
  int get hashCode => rivalUserId.hashCode;
}
