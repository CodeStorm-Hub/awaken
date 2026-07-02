import 'dart:math' as math;

import 'package:awaken/features/territory/domain/services/gps_kalman_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GpsKalmanFilter', () {
    test('returns first fix unchanged and initializes state', () {
      final filter = GpsKalmanFilter(processNoise: 3.0);
      final (lat, lng) = filter.filter(40.7128, -74.0060, 3.0);
      expect(lat, equals(40.7128));
      expect(lng, equals(-74.0060));
    });

    test('smooths small GPS jitter toward the mean', () {
      final filter = GpsKalmanFilter(processNoise: 3.0);
      filter.filter(40.7128, -74.0060, 3.0);
      final (lat, lng) = filter.filter(40.71281, -74.00601, 3.0);
      expect((lat - 40.712805).abs(), lessThan(0.00005));
      expect((lng - (-74.006005)).abs(), lessThan(0.00005));
    });

    test('rejects huge GPS jumps when accuracy is poor', () {
      final filter = GpsKalmanFilter(processNoise: 3.0);
      filter.filter(40.7128, -74.0060, 3.0);
      final (lat, lng) = filter.filter(40.7228, -74.0160, 100.0);
      expect((lat - 40.7128).abs(), lessThan(0.0002));
      expect((lng - (-74.0060)).abs(), lessThan(0.0002));
    });

    test('follows a consistent coordinate stream with low uncertainty', () {
      final filter = GpsKalmanFilter(processNoise: 3.0);
      filter.filter(40.7128, -74.0060, 3.0);

      var lat = 40.7128;
      var lng = -74.0060;
      for (var i = 0; i < 10; i++) {
        lat += 0.0001;
        lng += 0.0001;
        final (fLat, fLng) = filter.filter(lat, lng, 1.0);
        expect((fLat - lat).abs(), lessThan(0.00005));
        expect((fLng - lng).abs(), lessThan(0.00005));
      }
    });

    test('recovers toward stable stream after noisy measurements', () {
      final filter = GpsKalmanFilter(processNoise: 3.0);
      filter.filter(40.7128, -74.0060, 3.0);

      for (var i = 0; i < 20; i++) {
        filter.filter(
          40.7128 + 0.005 * math.sin(i),
          -74.0060 + 0.005 * math.cos(i),
          50.0,
        );
      }

      var finalLat = 0.0;
      var finalLng = 0.0;
      for (var i = 0; i < 10; i++) {
        final res = filter.filter(40.7128, -74.0060, 2.0);
        finalLat = res.$1;
        finalLng = res.$2;
      }
      expect((finalLat - 40.7128).abs(), lessThan(0.0002));
      expect((finalLng - (-74.0060)).abs(), lessThan(0.0002));
    });

    test('reset clears state so next fix is accepted raw again', () {
      final filter = GpsKalmanFilter(processNoise: 3.0);
      filter.filter(40.7128, -74.0060, 3.0);
      filter.filter(40.7130, -74.0062, 3.0);

      filter.reset();
      final (lat, lng) = filter.filter(41.0000, -75.0000, 3.0);
      expect(lat, equals(41.0000));
      expect(lng, equals(-75.0000));
    });

    test('higher process noise tracks new fixes more aggressively', () {
      final conservative = GpsKalmanFilter(processNoise: 1.0);
      final aggressive = GpsKalmanFilter(processNoise: 10.0);

      conservative.filter(40.7128, -74.0060, 3.0);
      aggressive.filter(40.7128, -74.0060, 3.0);

      final conservativeResult = conservative.filter(40.7130, -74.0062, 3.0);
      final aggressiveResult = aggressive.filter(40.7130, -74.0062, 3.0);

      final conservativeDelta =
          (conservativeResult.$1 - 40.7128).abs() + (conservativeResult.$2 - (-74.0060)).abs();
      final aggressiveDelta =
          (aggressiveResult.$1 - 40.7128).abs() + (aggressiveResult.$2 - (-74.0060)).abs();

      expect(aggressiveDelta, greaterThan(conservativeDelta));
    });
  });
}
