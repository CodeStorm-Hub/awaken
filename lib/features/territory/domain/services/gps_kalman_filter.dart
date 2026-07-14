/// Single-point position Kalman filter for smoothing GPS drift in real time,
/// per the implementation plan's "GPS Drift" mitigation. Adapted from the
/// well-known simplified GPS Kalman filter (position-only state, variance
/// driven by reported fix accuracy) — overkill velocity/acceleration state
/// isn't needed since RDP simplification handles post-run vertex cleanup.
class GpsKalmanFilter {
  GpsKalmanFilter({this.processNoise = 3.0});

  /// How much we trust the device to keep moving smoothly vs. snap to each
  /// raw fix — higher trusts new fixes more.
  final double processNoise;

  double? _lat;
  double? _lng;
  double _variance = -1;

  /// Feeds one raw fix (lat/lng in degrees, accuracy in meters from the
  /// platform location API) and returns the smoothed lat/lng.
  (double lat, double lng) filter(
    double lat,
    double lng,
    double accuracyMeters,
  ) {
    if (_variance < 0) {
      _lat = lat;
      _lng = lng;
      _variance = accuracyMeters * accuracyMeters;
      return (lat, lng);
    }

    _variance += processNoise;

    final measurementVariance = accuracyMeters * accuracyMeters;
    final kalmanGain = _variance / (_variance + measurementVariance);

    _lat = _lat! + kalmanGain * (lat - _lat!);
    _lng = _lng! + kalmanGain * (lng - _lng!);
    _variance = (1 - kalmanGain) * _variance;

    return (_lat!, _lng!);
  }

  void reset() {
    _lat = null;
    _lng = null;
    _variance = -1;
  }
}
