# Plan - Territory Capture E2E Testing

## Objective
Design and implement a comprehensive, requirement-driven, opaque-box E2E test suite for the Territory Capture feature in the Awaken Flutter app. The test suite must cover Tiers 1-4 with a target of 82+ tests.

## Steps

1. **Codebase & Architecture Exploration**
   - Dispatch an Explorer to understand:
     - The entry points and interfaces for run tracking, GPS, territory claiming, stealing, decay, and leaderboards.
     - How authentication, database/Supabase client, and local storage (Memory/SharedPreferences) are structured.
     - What testing libraries and frameworks are configured or best suited (e.g. `integration_test`, standard Dart test, or custom mocks).
     - How to mock geolocator, supabase, notifications, and other external dependencies.

2. **Design E2E Test Infrastructure**
   - Write `TEST_INFRA.md` at the project root outlining the test philosophy, feature inventory (GPS tracking, speed cap, loop closure, claiming, merging, stealing, decay, leaderboards), test architecture/runner, input/output formats, and Tier 4 application scenarios.
   - Design a test runner or mock environment that allows simulating runs, users, and GPS coordinate streams without physical devices or real Supabase network connections.

3. **Decompose E2E Tests (Tiers 1-4)**
   - Create `SCOPE.md` in the working directory listing the milestones/subtasks.
   - Enumerate test cases across all Tiers:
     - **Tier 1 (Feature Coverage)**: >=5 test cases per feature (e.g., GPS Tracking, Speed Cap, Loop Claiming, Territory Merging, Rival Stealing, Decay warning & trigger, Global/Nearby Leaderboards).
     - **Tier 2 (Boundary & Corner Cases)**: >=5 per feature.
     - **Tier 3 (Cross-Feature Combinations)**: Pairwise coverage of major feature interactions.
     - **Tier 4 (Real-World Application Scenarios)**: Real-world workloads.
     - Total: ~82 test cases (if N=7 features, 35 for Tier 1, 35 for Tier 2, 7 for Tier 3, 5 for Tier 4).

4. **Implement Test Suite**
   - Dispatch a Worker to implement the test framework, mock services, and the full suite of Tiers 1-4 test cases.
   - Apply the mandatory integrity warning.
   - Follow layout conventions.

5. **Review and Verify**
   - Run tests using a Worker agent.
   - Dispatch Reviewer agents to verify tests.
   - Run Forensic Auditor to ensure no cheating/hardcoding of results.

6. **Publish & Notify**
   - Publish `TEST_READY.md` at the project root.
   - Send completion message to parent.
