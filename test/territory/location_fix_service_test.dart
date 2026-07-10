import 'package:awaken/features/territory/domain/services/location_fix_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'mocks/mock_geolocator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGeolocatorPlatform mock;

  setUp(() {
    mock = MockGeolocatorPlatform();
    GeolocatorPlatform.instance = mock;
  });

  tearDown(() {
    mock.completeStream();
  });

  Position positionAt(double lat, double lng) => Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

  test('returns current position when available', () async {
    mock.feedPosition(positionAt(43.65, -79.38));

    final fix = await LocationFixService.acquireForMapCentering();

    expect(fix, isNotNull);
    expect(fix!.latitude, closeTo(43.65, 0.001));
    expect(fix.longitude, closeTo(-79.38, 0.001));
  });

  test('calls onInterim with last-known before fresher fix', () async {
    mock.feedPosition(positionAt(40.0, -74.0));
    Position? interim;

    final fix = await LocationFixService.acquireForMapCentering(
      onInterim: (p) => interim = p,
    );

    expect(interim, isNotNull);
    expect(interim!.latitude, closeTo(40.0, 0.001));
    expect(fix, isNotNull);
  });
}
