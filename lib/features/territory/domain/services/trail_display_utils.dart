import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';

/// Reduces overlay polyline point count for map rendering. The full GPS path
/// in [ActiveRunState.points] is unchanged and still used for capture.
List<GeoPointEntity> decimateTrailForDisplay(
  List<GeoPointEntity> points, {
  int maxPoints = AppConstants.territoryTrailDisplayMaxPoints,
}) {
  if (points.length <= maxPoints) return points;

  final step = (points.length / maxPoints).ceil().clamp(1, points.length);
  final sampled = <GeoPointEntity>[];
  for (var i = 0; i < points.length; i += step) {
    sampled.add(points[i]);
  }
  final last = points.last;
  if (sampled.isEmpty || sampled.last != last) {
    sampled.add(last);
  }
  return sampled;
}
