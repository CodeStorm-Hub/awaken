## 2026-07-01T12:18:00Z

You are the Worker agent responsible for Milestone 1: E2E Test Infrastructure Design.
Your working directory is: c:\Users\afsan\Workspace\awaken\.agents\teamwork_preview_worker_e2e_infra
Your task is:
1. Write c:\Users\afsan\Workspace\awaken\TEST_INFRA.md outlining the test philosophy, feature inventory (N=7 features: F1-F7 as defined below), test architecture/runner, input/output formats, and Tier 4 application scenarios.
Features:
- F1: GPS Tracking & Kalman Smoothing
- F2: Speed Cap Anti-Cheat
- F3: RDP Simplification
- F4: Loop Claiming & Validation
- F5: Territory Merging & Stealing
- F6: Territory Decay & Warnings
- F7: Leaderboard & Realtime Sync

2. Create c:\Users\afsan\Workspace\awaken\test\territory\territory_e2e_test.dart (and any helper mock files).
3. Set up complete mocks for:
   - GeolocatorPlatform: A mock implementation that allows feeding mock GPS coordinates over time (e.g. via StreamController) when GeolocatorPlatform.instance.getPositionStream() is called.
   - TerritoryRepository (or TerritorySupabaseDatasource): An in-memory mock repository (e.g. FakeTerritoryRepository) that simulates all database spatial operations (ST_Union, ST_Difference, Leaderboard queries, Decay check, etc.) locally in Dart.
   - Method channels (especially for flutter_local_notifications if needed, and system channels).
4. Implement a clean test runner structure where we can easily write and execute Tiers 1-4 tests. Write a few initial tests to prove the infrastructure works (e.g., mock GPS coordinates trace a simple closed loop, FakeTerritoryRepository processes the claim and returns a successful result).
5. Run the tests using 'flutter test test/territory/territory_e2e_test.dart' and verify they compile and pass.
6. Write a detailed handoff.md in your working directory summarizing what you implemented, the file paths, and the test run results (including stdout command and output).

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A Forensic Auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.
