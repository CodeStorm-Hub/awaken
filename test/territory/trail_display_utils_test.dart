import 'package:awaken/core/constants/app_constants.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/services/trail_display_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decimateTrailForDisplay', () {
    test('returns input unchanged when under max points', () {
      final points = List.generate(
        10,
        (i) => GeoPointEntity(
          latitude: i.toDouble(),
          longitude: i.toDouble(),
          timestamp: DateTime.fromMillisecondsSinceEpoch(i),
        ),
      );

      expect(decimateTrailForDisplay(points), same(points));
    });

    test('reduces long trails while preserving the last point', () {
      final points = List.generate(
        2000,
        (i) => GeoPointEntity(
          latitude: i.toDouble(),
          longitude: 0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(i),
        ),
      );

      final sampled = decimateTrailForDisplay(points);
      // Last point is always appended, so length may be maxPoints + 1.
      expect(
        sampled.length,
        lessThanOrEqualTo(AppConstants.territoryTrailDisplayMaxPoints + 1),
      );
      expect(sampled.last, points.last);
      expect(sampled.first, points.first);
    });
  });
}
