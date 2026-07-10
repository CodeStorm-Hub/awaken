# Territory Capture - Context

This document captures the current codebase analysis, architectural boundaries, and state of the Territory Capture feature before work starts.

## Codebase Analysis & Status

### Domain Layer (`lib/features/territory/domain/`)
- `entities/`: Models such as `GeoPointEntity`, `TerritoryEntity`, `LeaderboardEntryEntity`, `DecayWarningEntity`, `CaptureResultEntity`, `RunTrackEntity` exist as data containers.
- `services/`:
  - `GpsKalmanFilter`: Real-time position smoothing using a Kalman filter. (Implemented)
  - `RdpSimplifier`: Post-run vertex reduction using Ramer-Douglas-Peucker line simplification. (Implemented)
  - `RunValidationService`: Validates speed caps, minimum run duration, loop closure, and distance. (Implemented)

### Data Layer (`lib/features/territory/data/`)
- `datasources/`:
  - `TerritorySupabaseDatasource`: Interacts with Supabase database. Invokes `capture_territory` RPC, `touch_territory_defense` RPC, `decaying_territories` RPC, and reads tables. (Requires database schemas to be set up on the Supabase instance).
- `repositories/`:
  - `TerritorySupabaseRepositoryImpl`: Impements `TerritoryRepository` targeting the Supabase datasource. (Implemented but needs testing against a live DB setup).
- **Missing components**: There is no offline/signed-out repository fallback (Memory/SharedPreferences) implemented yet, despite R3 requiring it.

### Presentation Layer (`lib/features/territory/presentation/`)
- `providers/`:
  - `activeRunProvider`: Manages state machine of a run (requesting permission, tracking, finishing, finished). (Implemented)
  - `territoryRepositoryProvider`: Provides the `TerritorySupabaseRepositoryImpl`. Does not yet swap to local storage when logged out. (Needs to be updated to implement swapping).
- `screens/`:
  - `TerritoryRunScreen`: Renders the live location on a `flutter_map` using CartoDB Dark Matter tiles. (Skeletal, needs zoom buttons, double-tap zoom, Follow Me mode, neon overlays).
  - `TerritoryLeaderboardScreen`: Shows Global and Nearby rankings. (Skeletal).

## Supabase & Database State
- Supabase project URL: `https://fsdfqcnjcjtdmdjshrvu.supabase.co`
- Supabase Anon Key is configured in `supabase_config.dart`.
- The database schema for territories (`territories` table, `runs` table, GIS index, and `capture_territory`/`touch_territory_defense` RPCs) needs to be initialized.
