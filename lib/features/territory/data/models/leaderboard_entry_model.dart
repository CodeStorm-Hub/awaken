import 'package:awaken/features/territory/domain/entities/leaderboard_entry_entity.dart';

class LeaderboardEntryModel {
  const LeaderboardEntryModel({
    required this.userId,
    required this.displayName,
    required this.totalAreaSqMeters,
    required this.rank,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String?,
      totalAreaSqMeters: (json['total_area_sqm'] as num).toDouble(),
      rank: (json['rank'] as num).toInt(),
    );
  }

  final String userId;
  final String? displayName;
  final double totalAreaSqMeters;
  final int rank;

  LeaderboardEntryEntity toEntity() {
    return LeaderboardEntryEntity(
      userId: userId,
      displayName: displayName,
      totalAreaSqMeters: totalAreaSqMeters,
      rank: rank,
    );
  }
}
