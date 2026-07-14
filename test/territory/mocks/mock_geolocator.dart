import 'dart:async';
import 'package:geolocator/geolocator.dart';

class MockGeolocatorPlatform extends GeolocatorPlatform {
  final StreamController<Position> _positionStreamController =
      StreamController<Position>.broadcast();
  Position? _currentPosition;
  bool isLocationServiceEnabledValue = true;
  LocationPermission permissionValue = LocationPermission.whileInUse;

  void feedPosition(Position position) {
    _currentPosition = position;
    _positionStreamController.add(position);
  }

  void completeStream() {
    _positionStreamController.close();
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return isLocationServiceEnabledValue;
  }

  @override
  Future<LocationPermission> checkPermission() async {
    return permissionValue;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    return permissionValue;
  }

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async {
    return _currentPosition;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    if (_currentPosition != null) {
      return _currentPosition!;
    }
    // Return a default position if none was fed yet
    return Position(
      latitude: 40.7128,
      longitude: -74.0060,
      timestamp: DateTime.now(),
      accuracy: 3.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    return _positionStreamController.stream;
  }
}
