# Scope: Territory Capture E2E Testing

## Architecture
- The test suite is a headless, opaque-box E2E testing framework designed for the Territory Capture feature.
- External dependencies like Geolocator (GPS tracking) and Supabase (cloud storage & PostGIS operations) are mocked.
- State is managed via Riverpod provider overrides in the widget tree.
- Custom mock implementations (`MockGeolocatorPlatform`, `FakeTerritoryRepository`) simulate runner paths and database responses.

## Feature Inventory (N = 7)
- **F1: GPS Tracking & Kalman Smoothing** (Geolocator position stream, 1D Kalman filter).
- **F2: Speed Cap Anti-Cheat** (6-point rolling window, sustained speed cap > 25 km/h, ignores single jumps).
- **F3: RDP Simplification** (Post-run vertex reduction, epsilon 3m).
- **F4: Loop Claiming & Validation** (Start/end proximity <= 20m, duration >= 2 mins, distance >= 200m, min area 50 m²).
- **F5: Territory Merging & Stealing** (Self-union, rival difference, sliver cleanup < 1 m²).
- **F6: Territory Decay & Warnings** (Nightly 5m shrink, decay warning notifications 1-2 days before grace period).
- **F7: Leaderboard & Realtime Sync** (Global ranking, nearby ranking with 5000m radius, automatic live Riverpod updates).

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|---|---|---|---|
| 1 | Test Infrastructure Design | Write TEST_INFRA.md and create mock platform layers | None | DONE |
| 2 | Tier 1 (Feature Coverage) Tests | Implement >=35 test cases (5 per feature) | M1 | DONE |
| 3 | Tier 2 (Boundary & Corner) Tests | Implement >=35 test cases (5 per feature) | M2 | DONE |
| 4 | Tier 3 (Cross-Feature) Tests | Implement >=7 test cases (pairwise interactions) | M3 | DONE |
| 5 | Tier 4 (Real-World Application) Tests | Implement >=5 test cases (end-to-end user scenarios) | M4 | DONE |
| 6 | Verification & Review | Run test suite, perform reviews and integrity audits | M5 | IN_PROGRESS (b93062c8-22d6-412f-adf4-dda0445d9e1e, 774231ef-be51-4b6c-9c0f-9f6b2d7f4d20) |
| 7 | Publication | Publish TEST_READY.md and report to parent | M6 | PLANNED |

## Interface Contracts
- **Geolocator Platform**: Mocked by overriding `GeolocatorPlatform.instance` with a custom stream controller to emit mock GPS position sequences.
- **Territory Repository**: Mocked by overriding `territoryRepositoryProvider` in `ProviderScope` to avoid real Supabase database network requests.
- **Notifications**: Mocked by intercepting `dexterous.com/flutter/local_notifications` platform channel or overriding notifications service.
