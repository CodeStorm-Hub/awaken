# Handoff Report: Territory Capture Feature Analysis

## 1. Observation
I have explored the codebase of the Awaken Flutter app, located at `c:\Users\afsan\Workspace\awaken\`, and analyzed the Territory Capture feature. I observed the following implementation details:

* **File Layout:**
  Under `lib/features/territory/`, the feature follows Clean Architecture layers:
  - `domain/entities/`: Contains entities `geo_point_entity.dart`, `territory_entity.dart`, `run_track_entity.dart`, `capture_result_entity.dart`, `decay_warning_entity.dart`, `leaderboard_entry_entity.dart`.
  - `domain/repositories/`: Defines interface `territory_repository.dart`.
  - `domain/services/`: Implements pure logic algorithms including `gps_kalman_filter.dart`, `rdp_simplifier.dart`, `run_validation_service.dart`, `geo_utils.dart`.
  - `data/models/`: Holds data serialization classes including `territory_geo_codec.dart` which translates coordinates to/from PostGIS EWKT geometries:
    ```dart
    static String pointsToPolygonEwkt(List<GeoPointEntity> points) {
      final coords = points.map((p) => '${p.longitude} ${p.latitude}').toList();
      if (coords.isEmpty || coords.first != coords.last) coords.add(coords.first);
      return 'SRID=4326;POLYGON((${coords.join(', ')}))';
    }
    ```
  - `data/datasources/`: `territory_supabase_datasource.dart` handles database queries, realtime triggers on the `territories` table, and calls to remote RPC functions:
    ```dart
    Future<CaptureResultModel> captureTerritory(List<GeoPointEntity> loopPoints) async {
      final result = await _client.rpc<List<dynamic>>(
        'capture_territory',
        params: {'new_geom': TerritoryGeoCodec.pointsToPolygonEwkt(loopPoints)},
      );
      return CaptureResultModel.fromJson(result.first as Map<String, dynamic>);
    }
    ```
  - `presentation/providers/`: Riverpod providers. `active_run_providers.dart` defines `ActiveRunNotifier` (which operates as `activeRunProvider`) to manage tracking state, Geolocator listeners, and Kalman filtering:
    ```dart
    final (smoothedLat, smoothedLng) = _kalmanFilter.filter(
      position.latitude,
      position.longitude,
      position.accuracy,
    );
    ```
  - `presentation/screens/`: Contains layout code for map and controls (`territory_run_screen.dart`) and scoring (`territory_leaderboard_screen.dart`).

* **Core Gameplay Mechanics:**
  - **GPS Tracking:** Performed in `ActiveRunNotifier` using `Geolocator.getPositionStream`.
  - **Smoothing:** Double-pass approach: real-time Kalman filtering via `GpsKalmanFilter` during tracking, and post-run Ramer-Douglas-Peucker line simplification via `RdpSimplifier.simplify` with epsilon of 3.0 meters.
  - **Speed Cap & Anti-Cheat:** `RunValidationService.isSustainedOverSpeed` evaluates speed over a rolling window of the last 6 points against a max limit of 25.0 km/h. If exceeded across all points, `_sawSustainedOverSpeed` becomes `true` and invalidates territory claiming.
  - **Loop Closure Check:** `RunValidationService.isClosedLoop` verifies if first and last points are within 20m. Minimum duration (2 mins) and distance (200m) are also checked client-side.
  - **Merging & Rival Stealing:** Handled server-side in Supabase PostGIS via the SQL function `capture_territory(user_uuid, new_geom)`. It uses `ST_Union` to merge intersecting shapes, and `ST_Difference` to cut stolen shapes from overlapping rival geometries, cleaning up slivers under 1.0 $m^2$.
  - **Territory Decay & Warning:** Monitored using `last_defended_at` on the `territories` table. A nightly cron buffers geometries by -5m. Warnings are fetched via `decaying_territories` RPC and trigger local OS push notifications.
  - **Leaderboard Views:** Uses SegmentedControl to toggle between Global and Nearby. Nearby uses `leaderboard_nearby` RPC (5000m radius). Live updates are enabled because `leaderboardProvider` watches `territoryListProvider` which stream-listens to Supabase Realtime changes.

* **Dependency Mocking & Verification:**
  - `widget_test.dart` runs successfully with `flutter test` (all tests passed) and demonstrates how to mock Supabase and repository logic by overriding Riverpod providers:
    ```dart
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        alarmRepositoryProvider.overrideWithValue(FakeAlarmRepository()),
        sessionRepositoryProvider.overrideWithValue(FakeSessionRepository()),
      ],
      child: const AwakenApp(),
    )
    ```
  - Static analysis (`flutter analyze lib/`) passes cleanly with no warnings or issues under the `features/territory` directory.

---

## 2. Logic Chain
Based on these observations, I reasoned as follows:
1. Since the application is structured with a Feature-First Clean Architecture and uses Riverpod for state management, dependencies are successfully decoupled into abstraction layers (such as interfaces defined in the `domain` layer and injected via providers).
2. Because the UI screens and state controllers depend on abstract interfaces (like `TerritoryRepository` or `AuthRepository`) rather than concrete platform or network classes, we can fully isolate and test the UI in headless test environments (CI/CD, headless emulators) simply by overriding Riverpod providers with mocked/stubbed implementations in `ProviderScope`.
3. Since native plugins like Geolocator and local notifications rely on static platforms/method channels, we can mock them either by swapping their static delegate implementations (e.g. assigning `GeolocatorPlatform.instance` to a fake class in tests) or setting mock method call handlers on the default binary messenger in tests.
4. Because the spatial algorithms (Kalman filter, Ramer-Douglas-Peucker simplification, Haversine computations, and speed calculations) are implemented as pure Dart classes with zero dependencies on the Flutter framework or external assets, they can be tested via standard Dart unit tests. These unit tests run headlessly out-of-the-box and complete instantly.

---

## 3. Caveats
* **Supabase Client mocking:** While mocking repository interfaces is simple, unit-testing the direct datasource class (`TerritorySupabaseDatasource`) requires mocking Supabase's fluent API (`client.from().select()`), which is highly chain-nested and verbose to stub. It is recommended to test the repository layer with fake implementations instead of mocking the underlying database clients.
* **Map rendering verification:** Visual glitches (such as Impeller-based glassmorphism shaders or CartoDB dark mode tile loading) cannot be verified in standard headless unit/widget tests. Visual regression testing requires full-device UI integration tests or manual verification.

---

## 4. Conclusion
The Territory Capture feature is modularly decoupled, mathematically sound, and ready for testing.
* **Logical tests:** Direct unit tests should be written for `GpsKalmanFilter`, `RdpSimplifier`, `RunValidationService`, and `GeoUtils` to ensure math and physics constraints are validated.
* **UI & E2E tests:** Headless E2E tests can be written using standard Flutter widget tests and Riverpod `ProviderScope` overrides to stub out Supabase (`territoryRepositoryProvider`) and the Geolocator platform (`GeolocatorPlatform.instance`), allowing deterministic validation of run-session state flow without real GPS hardware or cloud databases.

---

## 5. Verification Method
To verify these findings and execute the tests:
1. **Static Analysis:**
   Run `flutter analyze lib/` in the project root to ensure code compliance.
2. **Execution of Test Suite:**
   Run `flutter test` in the project root to verify all existing and future unit/widget tests execute and pass.
3. **Inspect Implementation Files:**
   Open and inspect files listed in Section 1 (such as `lib/features/territory/presentation/providers/active_run_providers.dart`) to confirm how the GPS streams are filtered and validated.
