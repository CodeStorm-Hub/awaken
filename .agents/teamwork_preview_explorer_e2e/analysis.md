# Territory Capture Feature Analysis Report

## Executive Summary
This report analyzes the codebase of the Awaken Flutter application, specifically focused on the implementation of the **Territory Capture** feature. The feature utilizes clean architecture, Riverpod state management, Geolocator GPS tracking, client-side geometry smoothing, and Supabase PostGIS spatial operations. Static analysis is clean across the feature, and all existing tests pass successfully.

---

## 1. Feature File Layout & Structure
The territory capture feature is located in `lib/features/territory/` and follows a Feature-First Clean Architecture structure (`domain ← presentation` and `domain ← data`):

| Layer | Subdirectory | File Path | Purpose / Responsibility |
|---|---|---|---|
| **Domain** | **Entities** | `domain/entities/geo_point_entity.dart` | Repesents a single GPS fix (lat/lng, timestamp). |
| | | `domain/entities/territory_entity.dart` | Represents a player's multi-polygon territory. |
| | | `domain/entities/run_track_entity.dart` | Represents a completed run path and its validation outcome. |
| | | `domain/entities/capture_result_entity.dart` | Represents the output of a successful capture (area, rivals affected). |
| | | `domain/entities/decay_warning_entity.dart` | Represents a territory nearing the decay grace period limit. |
| | | `domain/entities/leaderboard_entry_entity.dart` | Represents leaderboard rows (rank, user, area). |
| | **Repositories**| `domain/repositories/territory_repository.dart`| Interface defining the contract for data operations. |
| | **Services** | `domain/services/geo_utils.dart` | Pure math: Haversine distance, speed, path distance. |
| | | `domain/services/gps_kalman_filter.dart` | Smooths live GPS coordinates using process/measurement noise. |
| | | `domain/services/rdp_simplifier.dart` | Simplifies paths post-run using Ramer-Douglas-Peucker. |
| | | `domain/services/run_validation_service.dart` | Pre-checks speed caps, loop closures, and path duration/length. |
| **Data** | **Models** | `data/models/territory_geo_codec.dart` | Converts domain points to PostGIS EWKT and parses GeoJSON. |
| | | `data/models/territory_model.dart` | JSON mapper for database territories. |
| | | `data/models/capture_result_model.dart` | JSON mapper for capture results. |
| | | `data/models/decay_warning_model.dart` | JSON mapper for decay warnings. |
| | | `data/models/leaderboard_entry_model.dart` | JSON mapper for leaderboard rows. |
| | **Datasources** | `data/datasources/territory_supabase_datasource.dart`| Performs direct query, RPC, and Realtime stream operations in Supabase. |
| | **Repositories**| `data/repositories/territory_supabase_repository_impl.dart`| Supabase-backed implementation of `TerritoryRepository`. |
| **Presentation**| **Providers** | `presentation/providers/territory_providers.dart` | Exposes repositories, shared map stream, and leaderboard state. |
| | | `presentation/providers/active_run_providers.dart` | State machine notifier for live run recording and submission. |
| | **Screens** | `presentation/screens/territory_run_screen.dart` | Interactive screen rendering live map trail and controls. |
| | | `presentation/screens/territory_leaderboard_screen.dart`| Screen showing top runners (Global and Nearby views). |
| | **Widgets** | `presentation/widgets/run_controls.dart` | Start/Stop button placed in the thumb zone. |
| | | `presentation/widgets/run_stats_sheet.dart` | Glassmorphic floating card showing distance and time. |
| | | `presentation/widgets/territory_polygon_layer.dart` | Custom neon-glow double-polygon renderer for flutter_map. |

---

## 2. Core Mechanics

### A. GPS Tracking & Smoothing
* **Live GPS Fixes:** Obtained using the `geolocator` package in `ActiveRunNotifier.startRun()` via `Geolocator.getPositionStream` with `LocationAccuracy.best` and a 5m filter distance.
* **Real-time Kalman Filtering:** Inside `_onPosition`, every raw coordinate is processed by a 1D position Kalman filter (`GpsKalmanFilter`). The measurement variance is initialized as the squared GPS accuracy. This prevents sudden spikes and jitter.
* **Post-run Vertex Reduction:** When a user stops the run, `RdpSimplifier.simplify` performs Ramer-Douglas-Peucker vertex reduction using a flat equirectangular projection (representing degrees to meters locally). The simplification uses an epsilon threshold of 3.0 meters (configured in `AppConstants.rdpSimplificationEpsilonMeters`). This keeps DB geometry size lightweight.

### B. Speed Cap & Anti-Cheat
* **Rolling Speed Window:** Speed cap checks are evaluated over a rolling window of the last 6 points (`AppConstants.speedRollingWindowSize`).
* **Sustained Over-speed Check:** `RunValidationService.isSustainedOverSpeed` evaluates if *every* consecutive pair of points within this rolling window exceeds `AppConstants.maxRunSpeedKmh` (25.0 km/h). If yes, a sustained over-speed is flag-set (`_sawSustainedOverSpeed = true`), showing a "TOO FAST" warning on the HUD.
* **Validation Outcome:** If over-speed was sustained at any point, the run outcome is classified as `RunOutcome.invalidatedSpeedCap`. Using a rolling window ensures a single momentary GPS drift/jump does not invalidate a legitimate run.

### C. Loop Closure Validation
* **Proximity Check:** When the run is stopped, `RunValidationService.isClosedLoop` calculates the Haversine distance between the first and last points. The loop is considered closed if the distance is $\le$ 20.0 meters (`AppConstants.loopClosureRadiusMeters`).
* **Traversal Constraints:** The run must satisfy a minimum duration of 2 minutes (`AppConstants.minRunDuration`) and a minimum distance of 200 meters (`AppConstants.minRunDistanceMeters`). If not, it is classified as `RunOutcome.invalidatedTooShort`.
* **Area Check:** If it passes the above checks, it is submitted as a polygon to the backend, which enforces that the enclosed loop area exceeds 50.0 square meters (`AppConstants.minLoopAreaSqMeters`).

### D. Territory Merging & Rival Stealing (Supabase/PostGIS)
All geometry operations are performed on the server-side within a PostgreSQL RPC function `capture_territory(user_uuid, new_geom)`:
1. **Sliver Rejection:** Rejects geometries with an area under 50.0 $m^2$ via `ST_Area(new_geom::geography) < 50.0`.
2. **Concurrency Locking:** Acquires rows using `SELECT 1 FROM territories WHERE ST_Intersects(geom, new_geom) ORDER BY id FOR UPDATE`. Sorting by `id` prevents deadlocks when concurrent users claim overlapping regions.
3. **Self-Union:** Finds existing territories owned by the user that intersect the new polygon and merges them using `ST_Union` to update the user's territory.
4. **Contestation (Stealing):** Subtracts the new merged polygon from all intersecting rival territories using `ST_Difference` combined with `ST_CollectionExtract(..., 3)` to discard stray point/line leftovers.
5. **Sliver Cleanup:** Deletes any rival territories whose remaining area falls below 1.0 $m^2$.

### E. Territory Decay & Warnings
* **Last Defended Update:** When a user claims territory or runs through/near their owned territory (which triggers the `touch_territory_defense` RPC), the `last_defended_at` timestamp is updated to `NOW()`.
* **Nightly Shrinking:** A `pg_cron` job runs nightly, shrinking territories with a `last_defended_at` older than 7 days (`AppConstants.territoryDecayGracePeriod`) by 5 meters using `ST_Buffer(geom::geography, -5.0)`. Any polygon that becomes empty (`ST_IsEmpty`) is deleted.
* **Warning Notifications:** The app polls decay warnings via the `decaying_territories` RPC (using `decayWarningsProvider`). On app start, if any warning is active, the app shows a local push notification ("Your territory near... is decaying") via `TerritoryDecayNotificationService.notifyIfDecaying`.

### F. Leaderboard Views
* **Segmented Toggle:** The screen switches between `LeaderboardMode.nearby` (default) and `LeaderboardMode.global`.
* **Nearby View:** Calls the database RPC `leaderboard_nearby` passing the user's current GPS position and a 5000-meter search radius, returning local rankings.
* **Global View:** Queries the `leaderboard_global` database view.
* **Realtime Sync:** The leaderboard provider watches `territoryListProvider` (which listens to database changes via Supabase Realtime). When a capture or steal is processed, the leaderboard automatically invalidates and fetches updated ranks, shifting them live in the UI.

---

## 3. Dependency Injection & Mocking Strategy

To make headless testing and CI running possible, we can mock the four primary external dependencies:

### A. Supabase
* **Current Wiring:** Accessed globally via `Supabase.instance.client` in `TerritorySupabaseDatasource` and `SupabaseAuthRepository`.
* **Mocking in Repository/Widget Tests:** Since Riverpod is used, the easiest approach is overriding the providers during test setup on the `ProviderScope`:
  ```dart
  ProviderScope(
    overrides: [
      territoryRepositoryProvider.overrideWithValue(FakeTerritoryRepository()),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
    ],
    child: const AwakenApp(),
  )
  ```
* **Mocking in Datasource Tests:** To test the datasource itself, we can refactor `TerritorySupabaseDatasource` to accept an optional `SupabaseClient` in its constructor:
  ```dart
  class TerritorySupabaseDatasource {
    const TerritorySupabaseDatasource({SupabaseClient? client}) : _customClient = client;
    final SupabaseClient? _customClient;
    SupabaseClient get _client => _customClient ?? Supabase.instance.client;
  }
  ```
  We can then inject a mocked `SupabaseClient` (mocked with `mocktail` or `mockito`) in unit tests and stub query calls (e.g., `client.from(...)`).

### B. Geolocator
* **Current Wiring:** Called statically in `ActiveRunNotifier` and UI screens.
* **Mocking Platform Instance:** The `geolocator` package permits replacing the platform channel instance. We can create a mock implementation subclassing `GeolocatorPlatform` and assign it in our tests:
  ```dart
  import 'package:geolocator/geolocator.dart';
  import 'package:plugin_platform_interface/plugin_platform_interface.dart';
  import 'package:mocktail/mocktail.dart';

  class MockGeolocatorPlatform extends Mock
      with MockPlatformInterfaceMixin
      implements GeolocatorPlatform {
    // Stub getCurrentPosition, getPositionStream, checkPermission, requestPermission, etc.
  }

  void main() {
    setUp(() {
      GeolocatorPlatform.instance = MockGeolocatorPlatform();
    });
  }
  ```

### C. flutter_map
* **Current Wiring:** Renders OSM tiles using `TileLayer` with network queries to CartoDB dark tile servers.
* **Mocking in Headless/Widget Tests:** Network queries for tiles will fail or timeout in headless environments.
  1. We can mock standard HTTP requests using `HttpOverrides` globally in the test file, returning a 1x1 transparent GIF/PNG for any URL matching `.png` or `basemaps.cartocdn.com`.
  2. We can provide a custom `TileProvider` (like a mock memory provider) for tests, or stub out `TileLayer` when running in test mode.

### D. flutter_local_notifications
* **Current Wiring:** Accesses the plugin statically via `FlutterLocalNotificationsPlugin` instances in service classes.
* **Mocking Method Channels:** The plugin communicates with the OS via method channels. In tests, we can register a mock method channel handler to capture notification invocations:
  ```dart
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (methodCall) async {
    if (methodCall.method == 'initialize') return true;
    if (methodCall.method == 'show') return null;
    return null;
  });
  ```
* **Clean-Architecture Alternative:** Wrap notification services in a mockable interface (e.g. `NotificationService`) and expose it through a Riverpod provider (`notificationServiceProvider`), allowing clean overrides.

---

## 4. Test Infrastructure & E2E Testing

### A. Current Structure
The app has a single widget test file `test/widget_test.dart` that performs a smoke test. It demonstrates the pattern of overriding Riverpod providers (`authRepositoryProvider`, `alarmRepositoryProvider`, etc.) to run the UI headlessly without database or platform exceptions.

### B. Unit Testing Core Logic
Because the tracking services are written as pure Dart classes with no Flutter UI dependency, we can write fast, headless unit tests to verify:
1. **Kalman Filter Smoothing:** Feed a series of noisy coordinates and verify that the output points have reduced variance and follow a smoother path.
2. **RDP Simplifier:** Pass a polyline containing redundant vertices and verify that the output contains fewer points while maintaining the structural shape within the epsilon threshold.
3. **Speed Validation:** Feed 6 points representing rapid movement (vehicle) and 6 points representing slow movement (jogging) and assert that `isSustainedOverSpeed` correctly flags the former and approves the latter.
4. **Geo Codec:** Convert coordinates to/from EWKT strings and ensure they match PostGIS specs.

### C. Headless E2E / Integration Testing
To test the complete workflow (Start Run → GPS Movement → Stop Run → Claim & Merge → Show on Leaderboard) headlessly in CI:
1. **Mock Platform Layer:** Setup a mock `GeolocatorPlatform` that emits a stream of positions over time when `getPositionStream` is called, simulating a runner completing a closed loop.
2. **Override Database Layer:** Override `territoryRepositoryProvider` with a fake in-memory implementation (`InMemoryTerritoryRepository`) that mimics the spatial operations (union, difference) locally in Dart, or uses pre-baked JSON mock datasets.
3. **Pumping the Widget Tree:** Use `integration_test` or `flutter_test` widget testing:
   - Pump `AwakenApp` with overrides.
   - Navigate to `/territory/run`.
   - Tap "START RUN".
   - Let the simulated geolocator stream play its path.
   - Tap "STOP".
   - Verify that the result banner displays "Territory claimed! +X m²".
   - Navigate to the Leaderboard and assert that the user's name rises to the correct rank.
