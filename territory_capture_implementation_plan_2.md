# Territory Capture Feature - Comprehensive Implementation Plan

This document outlines the end-to-end technical and design architecture for implementing the Territory Capture feature in the Awaken app, formulated from deep research into location-based game mechanics, Flutter UI/UX trends, and Supabase PostGIS spatial operations.

## User Review Required
> [!IMPORTANT]
> **Dependencies**: Implementing this will require adding several heavy dependencies: `flutter_map` (for map rendering), `geolocator` (for GPS), and native activity recognition plugins (for anti-cheat). 
> **Database Extensions**: PostGIS must be explicitly enabled on the Supabase project, and a `pg_cron` extension will be used for daily territory decay.
> Please review the architecture and design choices below and approve to proceed.

---

## 1. Client UI/UX Architecture (Flutter)

To achieve a modern, premium "cyberpunk" aesthetic suitable for a territory game, we will implement the following design systems:

### Map Engine Selection
*   **`flutter_map`**: We will use `flutter_map` (OpenStreetMap based) rather than Google Maps. `flutter_map` excels at high polygon counts because it supports built-in **polygon culling** (only drawing what is on screen) and avoids the heavy platform-channel bridge overhead that causes UI freezing in Google Maps when rendering hundreds of territories.

### Visual Aesthetics
*   **Dark Mode Base Layer**: We will use a dark/night map tile server (e.g., CartoDB Dark Matter) to provide high contrast.
*   **Neon Polygons**: Territory overlays will use custom painters to create a "neon tube" effect—a solid, bright core (Neon Blue/Pink) surrounded by a semi-transparent shadow (`BoxShadow` with high blur radius).
*   **Glassmorphism**: UI components floating above the map (like the territory stats Bottom Sheet) will use `BackdropFilter` (frosted glass). **Note:** We will ensure the Flutter **Impeller rendering engine** is enabled, as it handles shaders and blur effects exponentially better than Skia.

### Touch-First Ergonomics
*   **The Thumb Zone**: All critical actions (Start Run, Capture) will be placed in the bottom third of the screen.
*   **Haptics**: Native haptic feedback will be used to confirm successful territory captures and UI interactions, allowing users to play without staring at the screen while running.

### Performance & State Management
*   **Isolates**: Heavy spatial processing on the client (like parsing GeoJSON or reducing polygon vertex counts) will be offloaded to Flutter Isolates using `compute()` to prevent UI jank.
*   **Targeted Rebuilds**: Riverpod will be used to rebuild only specific map layers (e.g., the active user's trail) rather than calling `setState()` on the entire map widget.

---

## 2. Location Game Mechanics (Anti-Cheat & Physics)

Raw GPS data is noisy and easily manipulated. The core gameplay loop will rely on these mathematical and algorithmic layers:

### The Drive-by Cheat (Vehicle Prevention)
*   **Sensor Fusion (Activity Recognition)**: Relying solely on GPS speed is flawed due to GPS jumps. We will integrate native OS sensor fusion (Android Activity Recognition API / iOS Core Motion) to detect the *rhythm* of footsteps. If the OS classifies the movement as `IN_VEHICLE`, the run is invalidated.
*   **Rolling Average Speed**: We will calculate distance over time using the **Haversine formula**, keeping a rolling average over the last 5-10 pings to cap speed at a realistic human limit (~20 km/h).

### GPS Drift and Path-Snapping
*   **Kalman Filtering**: We will apply a real-time Kalman filter to smooth the incoming noisy GPS coordinates, preventing jagged spikes that cause accidental self-intersections.
*   **RDP Simplification**: Post-run, we will run the **Ramer-Douglas-Peucker (RDP)** line simplification algorithm. This strips out hundreds of redundant micro-movement vertices, providing a clean polygon for the database and reducing rendering load.

### Validating the "Bounded Loop"
*   **Proximity Closure**: We will calculate the Haversine distance between $P_{start}$ and $P_{end}$. A run is considered a loop if $Distance \le 20\text{m}$.
*   **Temporal & Traversal Constraints**: To prevent users from standing still and claiming a "loop", the total elapsed time must exceed 2 minutes, and the cumulative distance traveled must exceed 200 meters.

---

## 3. Database Architecture (Supabase PostGIS)

All heavy spatial relationships (Union, Difference) will be handled directly in the database to prevent client-server latency and payload bloat.

### Schema Design
We must use the `geometry(MultiPolygon, 4326)` type. Using standard `Polygon` will cause errors when a rival captures the middle of an existing territory, splitting it into two disconnected pieces.

```sql
CREATE TABLE territories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    geom geometry(MultiPolygon, 4326) NOT NULL,
    health INT DEFAULT 100,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
-- A GiST index is strictly required for ST_Intersects performance
CREATE INDEX territories_geom_gist_idx ON territories USING GIST (geom);
```

### Core RPC: Capture & Contest
We will create a single PostgreSQL RPC function `capture_territory(user_uuid, new_geom)` that executes an ACID transaction:
1.  **Validation**: Casts the incoming line string to a polygon using `ST_MakeValid` and `ST_Multi`.
2.  **Self-Expansion (Union)**: Finds all existing territories owned by the user that intersect the new shape. It merges them using `ST_Union` and replaces the old rows.
3.  **Contestation (Difference)**: Finds all rival territories intersecting the new shape. It uses `ST_Difference(rival_geom, new_merged_geom)` to subtract the stolen land. We will use `ST_CollectionExtract(..., 3)` to ensure stray points/lines leftover from the cut are discarded.
4.  **Cleanup**: Deletes any rival territories whose `ST_Area` was reduced to < 1.0 sq meters.

### Territory Decay
We will use Supabase's native `pg_cron` to schedule a nightly cleanup job:
*   **Spatial Shrink Strategy**: Every night at midnight, the job runs an `UPDATE` that physically shrinks all polygons by 5 meters using `ST_Buffer(geom::geography, -5.0)`. Any polygon that shrinks out of existence (`ST_IsEmpty`) is deleted.

---

## 4. The Leaderboard
*   **Global/Local**: A SQL view will calculate `SUM(ST_Area(geom::geography))` grouped by `user_id` to rank players by total square meters owned.
*   **Realtime**: We will use Supabase Realtime subscriptions so that if someone steals territory while you are looking at the leaderboard, the ranking shifts live.

---
## Verification Plan

### Automated Tests
*   **Unit Tests**: Dart tests to verify the Haversine distance logic, the RDP simplification array output, and the speed-capping constraints.
*   **Database Tests**: Execute direct SQL scripts to insert overlapping polygons and verify `ST_Union` and `ST_Difference` correctly calculate the resulting area.

### Manual Verification
*   Launch the app in the iOS Simulator / Android Emulator.
*   Use the emulator's GPS simulation feature to play a pre-recorded GPX file that runs in a loop.
*   Verify the polygon renders correctly on the `flutter_map`.
*   Simulate a second user cutting through the polygon and verify the first user's polygon is visibly sliced.
