# Awaken E2E Test Infrastructure Design

This document outlines the end-to-end (E2E) testing framework designed to validate the Territory Capture feature in the Awaken fitness application. It details the testing philosophy, feature inventory, testing architecture, input/output formats, and Tier 4 application scenarios.

---

## 1. Test Philosophy

- **Requirement-Driven E2E Coverage**: Our testing framework is structured to verify all functional requirements from the tracking phase down to database persistence.
- **Opaque-Box Boundaries**: We treat the territory capture system as a closed subsystem. Tests inject raw GPS coordinates, and then verify outputs through repository state changes, leaderboard rank shifts, and notification events.
- **Deterministic and Offline (Hermetic)**: No live hardware sensors, external networks, or real database backends are hit. Mocks simulate realistic physical and spatial mathematics purely in memory.
- **Real State Simulation**: All mocks maintain internal state (e.g. tracking areas, adjusting overlapping boundaries, decay timers) to produce authentic behavior rather than returning static, pre-canned values.

---

## 2. Feature Inventory (N = 7)

### F1: GPS Tracking & Kalman Smoothing
- **Description**: Real-time smoothing of noisy GPS location updates using a 1D Kalman filter to mitigate signal drift.
- **Input**: A stream of raw GPS updates (`Position` objects carrying latitude, longitude, and accuracy).
- **Processing**: The `GpsKalmanFilter` computes a running weighted average where the weight (Kalman gain) changes depending on reported accuracy.
- **Verification**: Asserts that coordinates with high accuracy pull the state towards them, while noisy, low-accuracy coordinates are smoothed out.

### F2: Speed Cap Anti-Cheat
- **Description**: Invalidation of workouts that exceed realistic running speed thresholds to prevent cheating (e.g., driving or cycling).
- **Input**: A series of GPS updates with timestamps.
- **Processing**: Evaluates a rolling window of length `AppConstants.speedRollingWindowSize` (6 fixes) for sustained speed above `AppConstants.maxRunSpeedKmh` (25 km/h).
- **Verification**: Asserts that a single noisy GPS jump is ignored, but sustained speed above 25 km/h flags the workout outcome as `invalidatedSpeedCap`.

### F3: RDP Simplification
- **Description**: Vertex reduction on the path before sending it to the database, removing collinear or redundant coordinates.
- **Input**: A list of coordinates representing the raw, completed run path.
- **Processing**: The `RdpSimplifier.simplify` function applies the Ramer-Douglas-Peucker algorithm using a tolerance of `epsilon = 3m`.
- **Verification**: Asserts that a path with redundant points is simplified to fewer vertices while preserving overall shape and loop endpoints.

### F4: Loop Claiming & Validation
- **Description**: Validates that a run forms a closed loop and meets physical duration, distance, and area requirements to qualify for a territory claim.
- **Input**: A path of coordinates, total distance, and duration.
- **Processing**: 
  - Proximity closure check: `haversineMeters(start, end) <= 20m`.
  - Minimum constraints check: `duration >= 2 minutes`, `distance >= 200m`.
  - Area check: projected loop area $\ge 50\text{ m}^2$.
- **Verification**: Valid loops result in `RunOutcome.territoryClaimed`. Short, open, or tiny loops result in appropriate failure classifications (`invalidatedTooShort`, `loopNotClosed`, `invalidatedTooSmall`).

### F5: Territory Merging & Stealing
- **Description**: Handles spatial resolution when a user captures territory that overlaps their existing land (union) or a rival's land (steal).
- **Input**: Closed-loop polygon coordinates representing a successful capture.
- **Processing**:
  - *Merging (ST_Union)*: Checks if the new polygon overlaps any of the user's existing polygons. If so, they are combined, and the area is calculated.
  - *Stealing (ST_Difference)*: Checks if the new polygon cuts into rival territories. If it does, the rival's area is subtracted.
  - *Sliver Cleanup*: Removes any rival polygon whose remaining area is $< 1.0\text{ m}^2$.
- **Verification**: Confirms the claimant's total owned area increases, affected rivals lose area, and sliver fragments are deleted.

### F6: Territory Decay & Warnings
- **Description**: Simulates the degradation of un-defended territory. Users receive warnings before their land begins to decay.
- **Input**: Elapsed duration since `lastDefendedAt`.
- **Processing**: 
  - Warnings trigger when a territory is 1-2 days away from the end of the 7-day grace period.
  - Decay shrinks territory size (5% or 5 $\text{m}^2$ per day of neglect).
- **Verification**: Verify that outdated territories show up in `getDecayWarnings()` and decay correctly when the simulation advances.

### F7: Leaderboard & Realtime Sync
- **Description**: Synchronizes ranking metrics and maps in real time.
- **Input**: Active capture events and viewer coordinates.
- **Processing**:
  - *Global Leaderboard*: Returns all users ranked by total owned area descending.
  - *Nearby Leaderboard*: Filters to users with territory within a 5,000m radius of the viewer.
  - *Realtime Sync*: Stream-based updates via `watchTerritories()`.
- **Verification**: Asserts that rankings adjust instantly on territory capture or decay, and nearby filter limits coordinates properly.

---

## 3. Test Architecture & Runner

The E2E test runner executes in a headless Dart VM context using `flutter_test`. 

### State Orchestration
State is managed via `flutter_riverpod` providers. In tests, we override the real database-bound providers:
```dart
ProviderScope(
  overrides: [
    territoryRepositoryProvider.overrideWithValue(fakeTerritoryRepository),
  ],
  child: ...
)
```

### Mocks and Fakes
1. **`MockGeolocatorPlatform`**: Extends `GeolocatorPlatform` from the `geolocator` package. Replaces `GeolocatorPlatform.instance`. Pushes mock location updates into a broadcast `StreamController` to simulate a runner's path over time.
2. **`FakeTerritoryRepository`**: Implements `TerritoryRepository`. Simulates PostgreSQL + PostGIS spatial geometry operations (`ST_Union`, `ST_Difference`), leaderboard queries, decay warnings, and run persistence.
3. **Method Channel Mocks**: Intercepts `flutter_local_notifications` channel invocations so notification logic fires without native plugins.

---

## 4. Input & Output Formats

### Inputs
- **GPS Coordinates**: WGS84 coordinates.
```json
{
  "latitude": 40.7128,
  "longitude": -74.0060,
  "accuracy": 3.0,
  "timestamp": "2026-07-01T08:00:00Z"
}
```
- **Spatial EWKT (PostGIS)**: Used to define geometries inside the database mock.
  - LineString: `SRID=4326;LINESTRING(-74.0060 40.7128, -74.0061 40.7129)`
  - Polygon: `SRID=4326;POLYGON((lon1 lat1, lon2 lat2, lon3 lat3, lon1 lat1))`

### Outputs
- **Workouts**: Persisted as a `RunTrackEntity` with a classified `RunOutcome`.
- **Leaderboards**: Emits list of `LeaderboardEntryEntity` sorted by area.
- **Notifications**: Fires a local warning notification payload.

---

## 5. Tier 4 Application Scenarios

### Scenario A: Clean Loop Capture (Normal Flow)
1. User starts tracking a run.
2. User walks a closed square loop (e.g. 60m per side, area ~3,600 $\text{m}^2$, duration > 2 mins, distance > 240m).
3. GPS Kalman filter smooths small path anomalies.
4. User stops tracking.
5. The system simplifier reduces points via RDP.
6. The client validates the loop as closed.
7. The database mock verifies the area $\ge 50\text{ m}^2$, records the run as `territoryClaimed`, and creates the new territory.

### Scenario B: Drive-by Invalidation (Anti-Cheat Flow)
1. User starts tracking a run.
2. User drives a vehicle at 45 km/h.
3. The speed check detects sustained over-speed over 6 consecutive GPS updates.
4. When stopping the run, the system validates the cheat and sets `RunOutcome.invalidatedSpeedCap`.
5. The database mock persists the run record, but denies territory claiming or touch defense.

### Scenario C: Territory Stealing and Rank Shift (Rivalry Flow)
1. User A (current user) captures a large loop.
2. User B (rival) captures a new loop that slices through User A's territory.
3. The database mock processes User B's claim:
   - Performs a mock `ST_Difference` subtracting User B's loop from User A's polygon.
   - User A's area decreases, and User B's area increases.
   - If User A's territory shrinks below $1.0\text{ m}^2$, it is deleted (sliver cleanup).
4. Leaderboard rankings update in real time. User B overtakes User A on the leaderboard.
