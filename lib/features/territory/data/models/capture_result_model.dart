import 'package:awaken/features/territory/domain/entities/capture_result_entity.dart';

class CaptureResultModel {
  const CaptureResultModel({
    required this.claimedAreaSqMeters,
    required this.totalOwnedAreaSqMeters,
    required this.rivalsAffected,
  });

  factory CaptureResultModel.fromJson(Map<String, dynamic> json) {
    return CaptureResultModel(
      claimedAreaSqMeters: (json['claimed_area_sqm'] as num).toDouble(),
      totalOwnedAreaSqMeters: (json['total_owned_area_sqm'] as num).toDouble(),
      rivalsAffected: (json['rivals_affected'] as num).toInt(),
    );
  }

  final double claimedAreaSqMeters;
  final double totalOwnedAreaSqMeters;
  final int rivalsAffected;

  CaptureResultEntity toEntity() {
    return CaptureResultEntity(
      claimedAreaSqMeters: claimedAreaSqMeters,
      totalOwnedAreaSqMeters: totalOwnedAreaSqMeters,
      rivalsAffected: rivalsAffected,
    );
  }
}
