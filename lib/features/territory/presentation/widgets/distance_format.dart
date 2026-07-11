/// Formats a path / closure distance for HUD display — always in km.
String formatDistanceKm(double meters, {int fractionDigits = 2}) {
  if (!meters.isFinite || meters < 0) return '0.00 km';
  return '${(meters / 1000).toStringAsFixed(fractionDigits)} km';
}

/// Formats instantaneous or average run speed for HUD display.
String formatSpeedKmh(double speedKmh, {int fractionDigits = 1}) {
  if (!speedKmh.isFinite || speedKmh < 0) return '0.0 km/h';
  return '${speedKmh.toStringAsFixed(fractionDigits)} km/h';
}

/// Average pace from total distance and elapsed time.
double averageSpeedKmh(double distanceMeters, Duration elapsed) {
  final hours = elapsed.inMilliseconds / (1000.0 * 60.0 * 60.0);
  if (hours <= 0 || !distanceMeters.isFinite || distanceMeters < 0) return 0;
  return (distanceMeters / 1000.0) / hours;
}
