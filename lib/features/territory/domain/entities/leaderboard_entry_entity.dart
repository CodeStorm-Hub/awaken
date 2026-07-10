import 'package:flutter/foundation.dart';

@immutable
class LeaderboardEntryEntity {
  const LeaderboardEntryEntity({
    required this.userId,
    required this.displayName,
    required this.totalAreaSqMeters,
    required this.rank,
  });

  final String userId;
  final String? displayName;
  final double totalAreaSqMeters;
  final int rank;
}
