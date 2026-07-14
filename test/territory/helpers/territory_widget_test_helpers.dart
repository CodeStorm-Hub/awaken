import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:awaken/features/auth/presentation/providers/auth_providers.dart';
import 'package:awaken/features/territory/domain/entities/geo_point_entity.dart';
import 'package:awaken/features/territory/domain/services/geo_utils.dart';
import 'package:awaken/features/territory/presentation/providers/territory_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Inserts intermediate GPS fixes along each leg so loop-segment extraction
/// sees a realistic point density (~5 m spacing, matching production
/// `distanceFilter`). Timestamps advance at ~12 km/h so speed-cap checks
/// stay realistic on densified paths.
List<GeoPointEntity> densifyGpsPath(
  List<GeoPointEntity> points, {
  double stepMeters = 5.0,
  double speedKmh = 12.0,
}) {
  if (points.length < 2) return points;

  final result = <GeoPointEntity>[points.first];
  final secondsPerMeter = 3.6 / speedKmh;

  for (var i = 1; i < points.length; i++) {
    final from = points[i - 1];
    final to = points[i];
    final legMeters = GeoUtils.haversineMeters(from, to);
    final steps = (legMeters / stepMeters).floor();

    for (var s = 1; s <= steps; s++) {
      final t = s / (steps + 1);
      final lat = from.latitude + (to.latitude - from.latitude) * t;
      final lng = from.longitude + (to.longitude - from.longitude) * t;
      final stepDist = legMeters * t;
      final ts = from.timestamp.add(
        Duration(milliseconds: (stepDist * secondsPerMeter * 1000).round()),
      );
      result.add(GeoPointEntity(latitude: lat, longitude: lng, timestamp: ts));
    }
    result.add(to);
  }
  return result;
}

/// Closed rectangular loop with densified vertices for segment extraction tests.
List<GeoPointEntity> createDenseRectangleLoop({
  required double startLat,
  required double startLng,
  required double widthMeters,
  required double heightMeters,
  required DateTime startTime,
  Duration interval = const Duration(seconds: 30),
  double densifyStepMeters = 5.0,
}) {
  final refLatRad = startLat * math.pi / 180.0;
  const metersPerDegreeLat = 111194.9266;
  final metersPerDegreeLon = 111194.9266 * math.cos(refLatRad);

  final dLat = heightMeters / metersPerDegreeLat;
  final dLon = widthMeters / metersPerDegreeLon;

  final sparse = [
    GeoPointEntity(
      latitude: startLat,
      longitude: startLng,
      timestamp: startTime,
    ),
    GeoPointEntity(
      latitude: startLat + dLat,
      longitude: startLng,
      timestamp: startTime.add(interval),
    ),
    GeoPointEntity(
      latitude: startLat + dLat,
      longitude: startLng + dLon,
      timestamp: startTime.add(interval * 2),
    ),
    GeoPointEntity(
      latitude: startLat,
      longitude: startLng + dLon,
      timestamp: startTime.add(interval * 3),
    ),
    GeoPointEntity(
      latitude: startLat,
      longitude: startLng,
      timestamp: startTime.add(interval * 4),
    ),
  ];
  return densifyGpsPath(sparse, stepMeters: densifyStepMeters);
}

/// Rectangle loop that closes, then continues straight for [overrunMeters].
List<GeoPointEntity> createDenseRectangleLoopWithOverrun({
  required double startLat,
  required double startLng,
  required double widthMeters,
  required double heightMeters,
  required double overrunMeters,
  required DateTime startTime,
  Duration interval = const Duration(seconds: 30),
}) {
  final loop = createDenseRectangleLoop(
    startLat: startLat,
    startLng: startLng,
    widthMeters: widthMeters,
    heightMeters: heightMeters,
    startTime: startTime,
    interval: interval,
  );
  final last = loop.last;
  const metersPerDegreeLat = 111194.9266;
  final dLat = overrunMeters / metersPerDegreeLat;
  final overrunEnd = GeoPointEntity(
    latitude: last.latitude - dLat,
    longitude: last.longitude,
    timestamp: last.timestamp.add(interval),
  );
  return densifyGpsPath([...loop, overrunEnd]);
}

/// Unblocks gated territory Realtime/GPS providers in unit tests.
void enableTerritoryMapForTests(ProviderContainer container) {
  container.read(territoryMapReadyProvider.notifier).state = true;
}

/// Activates territory shell tab gating (map + GPS providers).
void enableTerritoryTabForTests(ProviderContainer container) {
  container.read(territoryShellTabIndexProvider.notifier).state = 1;
}

/// Returns a transparent 1x1 PNG for any HTTP request in widget tests.
class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => MockHttpClient();
}

class MockHttpClient implements HttpClient {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl || invocation.memberName == #openUrl) {
      return Future.value(MockHttpClientRequest());
    }
    return null;
  }
}

class MockHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(MockHttpClientResponse());
    }
    if (invocation.memberName == #headers) {
      return MockHttpHeaders();
    }
    return null;
  }
}

class MockHttpHeaders implements HttpHeaders {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  static const List<int> _transparentPng = [
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
    0,
    0,
    0,
    13,
    73,
    72,
    68,
    82,
    0,
    0,
    0,
    1,
    0,
    0,
    0,
    1,
    8,
    6,
    0,
    0,
    0,
    31,
    21,
    196,
    137,
    0,
    0,
    0,
    13,
    73,
    68,
    65,
    84,
    120,
    1,
    99,
    96,
    96,
    96,
    0,
    0,
    0,
    5,
    0,
    1,
    165,
    246,
    69,
    127,
    0,
    0,
    0,
    0,
    73,
    69,
    78,
    68,
    174,
    66,
    96,
    130,
  ];

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_transparentPng).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #statusCode) return 200;
    if (invocation.memberName == #contentLength) return _transparentPng.length;
    if (invocation.memberName == #headers) return MockHttpHeaders();
    return null;
  }
}

/// Signed-out auth stream so [isSignedInProvider] never touches Supabase.instance
/// while [authStateProvider] is loading.
Stream<AuthState> signedOutAuthStateStream() {
  return Stream<AuthState>.value(
    const AuthState(AuthChangeEvent.signedOut, null),
  );
}

/// Test double for [AuthStateNotifier] — `authStateProvider` is backed by a
/// manually-managed [AsyncNotifier] (not a plain `StreamProvider`), so
/// overriding it in tests requires a notifier factory rather than a raw
/// stream. Emits one signed-out event, matching [signedOutAuthStateStream].
class SignedOutAuthStateNotifier extends AuthStateNotifier {
  @override
  Future<AuthState> build() async =>
      const AuthState(AuthChangeEvent.signedOut, null);
}
