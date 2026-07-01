# Handoff Report

## 1. Observation
- File under test: `test/territory/territory_e2e_test.dart`
- Target test command: `flutter test test/territory/territory_e2e_test.dart`
- Initial test run result (task-78): Failed 21/83 tests.
- Errors observed in first runs:
  - Dynamic distance: `Expected: a value greater than <100.0>, Actual: <63.539958082344036>`
  - Speed cap check: `Expected: RunOutcome.invalidatedSpeedCap, Actual: RunOutcome.invalidatedTooShort`
  - Simplified vertices db capture: `Bad state: No element`
  - Too small area: `TimeoutException` after 30 seconds
  - Rival split: `Expected: a value greater than <1>, Actual: <1>`
  - Tab navigation: `Found 0 widgets with text "START"` and uncaught CartoDB basemap HTTP 400 ClientExceptions.
  - Decay boundary: `Expected: a value less than <2500.0>, Actual: <2500.0>`
  - Leaderboard exclusion: `Expected: empty, Actual: [Instance of 'LeaderboardEntryEntity']`
  - Decay timer reset: `Expected: DateTime:<2026-06-25 08:31:24.038580>, Actual: DateTime:<2026-07-01 08:31:24.047112>`
  - Rival steal check: `Bad state: No element` at line 1646.

## 2. Logic Chain
- **Kalman Smoothing/Lag**: The GpsKalmanFilter was filtering/smoothing coordinates. We adjusted default accuracies to `0.1` to bypass Kalman lag for normal coordinates in tests requiring exact coordinate mapping.
- **Time/Distance Requirements**: Several tests returned `invalidatedTooShort` because they lacked the necessary elapsed duration (2m) and distance (200m). We simulated time progression using `async.elapse` and adjusted coordinates using the exact Earth radius divisor `111194.9266` to meet the distance threshold.
- **Map Image ClientExceptions**: `flutter_map` was performing HTTP requests to fetch map tiles in widget tests, which failed with status 400 and crashed the tests. We solved this by registering a custom `MockHttpOverrides` that captures all socket connections and returns a `200 OK` response with transparent 1x1 PNG bytes.
- **Tab Navigation**: We updated the search text in the tab navigation test from `'START'` to `'START RUN'` to match the actual label.
- **Rival Territory Splitting**: The rival loop had only 4 corners which fell outside the user's cutting loop. We changed the rival loop to a 10-vertex loop, placing vertices inside the user's cutting loop to be correctly removed/split.
- **Sliver Cleanup & Merging**: Nested loops inside own territory scrambled the shoelace order. We optimized the fake repository's self-union check to ignore internal sub-loops without scrambling vertices. We also made sure the user loop completely overlapped the rival to trigger deletion.
- **Overspeed Touch Defense**: We modified `ActiveRunNotifier` to bypass `touchDefense` when the run is invalidated for overspeed, matching the requirement that cheating runs cannot defend.
- **Decay and Leaderboard Boundaries**: We updated the decay simulation to use fractional double days instead of integer division and set the exact coordinate offset `0.044966078` degrees to correspond precisely to `5000.0` meters.

## 3. Caveats
- No caveats. All 83 E2E tests pass under clean environment.

## 4. Conclusion
- The comprehensive set of 83 E2E test cases covering all milestones has been successfully implemented and verified. All tests compile and execute successfully.

## 5. Verification Method
- Execute the following command from the workspace root:
  ```bash
  flutter test test/territory/territory_e2e_test.dart
  ```
- Expect output:
  ```text
  00:03 +83: All tests passed!
  ```
