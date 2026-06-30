# Territory Capture Feature - Implementation Plan (Revised)

This document outlines the end-to-end technical and design architecture for implementing the Territory Capture feature in the Awaken app. Revised from the original Plan 2 to close gaps found while cross-checking against `territory_capture_user_story.md` and the existing `lib/` architecture.

## Scope

In scope: User Stories 1–4 (Track the Run, Claim & Expand Territory, Steal Rival Territory, The Leaderboard) and the three Critical Mechanic Refinements (Drive-by Cheat, GPS Drift, Dead Zone / Decay).

**Explicitly out of scope for this plan**: Fog of War, Fortresses/Home Base, Team Mode (Factions) — the user story's "Suggested Feature Improvements" section. Deferred by user decision; revisit as a separate plan once the core loop ships and is validated.

## User Review Required
> [!IMPORTANT]
> **Dependencies**: `flutter_map` (map rendering), `geolocator` (GPS), native activity-recognition plugins (`flutter_activity_recognition` or platform channels to Android Activity Recognition API / iOS Core Motion) for anti-cheat. All free/open-source — no paid licenses required, unlike `flutter_background_geolocation` evaluated and rejected in Plan 1.
> **Database Extensions**: PostGIS must be explicitly enabled on the Supabase project (`fsdfqcnjcjtdmdjshrvu`), and `pg_cron` will be used for nightly territory decay.
> **New feature module**: this introduces `lib/features/territory/` following the existing `data/{datasources,models,repositories}`, `domain/{entities,repositories,services}`, `presentation/{providers,screens,widgets}` structure used by `alarm`, `dashboard`, etc.
> Please review the architecture and design choices below and approve to proceed.

---

## 1. Client UI/UX Architecture (Flutter)

### Map Engine Selection
*   **`flutter_map`** (OpenStreetMap-based) over Google Maps — built-in polygon culling for high territory counts, avoids the platform-channel overhead that causes jank with hundreds of Google Maps polygons.

### Visual Aesthetics
*   Dark map tile server (e.g. CartoDB Dark Matter) — consistent with the app's dark-only theme (`AppColors`, no light mode anywhere per `app_theme.dart`).
*   Territory overlays: custom-painted "neon tube" effect (solid core + blurred glow), using `AppColors` tokens rather than new raw hex literals, per the existing design-system convention.
*   `BackdropFilter` glassmorphism for floating UI (territory stats sheet, leaderboard sheet); requires Impeller enabled for acceptable blur performance.
*   HUD numerics (area owned, distance run, timer) use the existing `AwakenTypography` extension (Space Mono, tabular figures) — do not introduce a separate numeric style.

### Touch-First Ergonomics
*   Start/Stop run controls in the bottom third of the screen (thumb zone).
*   Haptic feedback on capture/steal events so users don't need to watch the screen mid-run.

### Performance & State Management
*   Heavy client-side spatial work (vertex reduction, RDP simplification) runs via `compute()` / Isolates — never on the UI thread.
*   Riverpod providers scoped per map layer (active trail, owned territories, rival territories) so a tick of the live trail doesn't rebuild the whole map — same "hand-written providers" pattern as `alarm_providers.dart`, no new codegen dependency required for this feature.

---

## 2. Location Game Mechanics (Anti-Cheat & Physics)

### Centralized constants (fixes a contradiction in the user story)
The user story itself disagrees with its own refinement section: Story #1's acceptance criteria says **>25 km/h**, while the "Drive-by Cheat" refinement says **20–25 km/h**. Resolve this once, in code, rather than letting client and server drift independently:

```dart
// lib/core/constants/app_constants.dart (extend existing file, do not create a new one)
static const double maxRunSpeedKmh = 25.0;       // single source of truth
static const double loopClosureRadiusMeters = 20.0;
static const double minLoopAreaSqMeters = 50.0;  // new — see "Minimum loop area" below
static const Duration minRunDuration = Duration(minutes: 2);
static const double minRunDistanceMeters = 200.0;
static const Duration territoryDecayGracePeriod = Duration(days: 7);
```

### The Drive-by Cheat (Vehicle Prevention)
*   **Sensor Fusion**: native activity recognition (Android Activity Recognition API / iOS Core Motion) to detect footstep rhythm vs. vehicle motion. If classified `IN_VEHICLE`, invalidate the run.
*   **Rolling Average Speed**: Haversine distance over a rolling window of the last 5–10 GPS pings, capped at `maxRunSpeedKmh`. Sustained excess (not a single GPS jump) triggers invalidation — a momentary spike from GPS noise should not nuke a legitimate run.

### GPS Drift and Path-Snapping
*   Real-time Kalman filter smooths incoming coordinates before they're drawn or evaluated, preventing jagged self-intersections from rendering as accidental loops.
*   Post-run RDP simplification reduces vertex count before the polygon is sent to Supabase.

### Validating the "Bounded Loop"
*   **Proximity Closure**: loop counts if Haversine($P_{start}$, $P_{end}$) ≤ `loopClosureRadiusMeters` (20m).
*   **Temporal & Traversal Constraints**: elapsed time > `minRunDuration` (2 min) AND cumulative distance > `minRunDistanceMeters` (200m) — prevents standing-still-and-closing-a-loop.
*   **Minimum loop area (new — gap in the user story)**: the story only constrains start/end proximity and (here) time/distance, but never the *enclosed area*. A long, thin out-and-back path can satisfy both proximity and distance constraints while enclosing near-zero square meters. Enforce `ST_Area(new_geom::geography) > minLoopAreaSqMeters` server-side in the RPC (see §3) — reject before touching the `territories` table, not after, so slivers never get written and rolled back.

---

## 3. Database Architecture (Supabase PostGIS)

All heavy spatial relationships (Union, Difference) run in PostgreSQL, not on-device, to avoid client-server payload bloat and keep capture logic atomic.

### Schema Design
```sql
CREATE TABLE territories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    geom geometry(MultiPolygon, 4326) NOT NULL,
    health INT DEFAULT 100,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    last_defended_at TIMESTAMPTZ DEFAULT NOW()  -- new: drives decay (see Territory Decay)
);
CREATE INDEX territories_geom_gist_idx ON territories USING GIST (geom);
CREATE INDEX territories_user_id_idx ON territories (user_id);
```

`last_defended_at` replaces inferring decay eligibility from `created_at`, which would incorrectly decay long-held territory the user still actively runs through.

### Core RPC: Capture & Contest

```sql
CREATE OR REPLACE FUNCTION capture_territory(user_uuid UUID, new_geom GEOMETRY)
RETURNS TABLE(...) AS $$
DECLARE
  merged_geom GEOMETRY;
BEGIN
  -- 0. Reject slivers before touching any row (see "Minimum loop area" above)
  IF ST_Area(new_geom::geography) < 50.0 THEN
    RAISE EXCEPTION 'loop_too_small';
  END IF;

  -- 1. Lock every existing row this capture will touch, in a stable order, BEFORE
  --    reading/mutating any of them. This is the concurrency fix: without it, two
  --    runners closing overlapping loops at the same instant can each read the same
  --    rival polygon pre-mutation, compute their own ST_Difference against stale
  --    data, and the second COMMIT silently clobbers the first steal.
  PERFORM 1 FROM territories
    WHERE ST_Intersects(geom, new_geom)
    ORDER BY id
    FOR UPDATE;

  -- 2. Validation
  new_geom := ST_Multi(ST_MakeValid(new_geom));

  -- 3. Self-Expansion (Union): merge with the user's own intersecting territories
  SELECT ST_Union(geom) INTO merged_geom
    FROM territories WHERE user_id = user_uuid AND ST_Intersects(geom, new_geom);
  merged_geom := ST_Union(COALESCE(merged_geom, ST_GeomFromText('MULTIPOLYGON EMPTY', 4326)), new_geom);
  DELETE FROM territories WHERE user_id = user_uuid AND ST_Intersects(geom, new_geom);
  INSERT INTO territories (user_id, geom, last_defended_at)
    VALUES (user_uuid, merged_geom, NOW());

  -- 4. Contestation (Difference): subtract the claimed area from every rival
  --    territory it overlaps. Iterates all intersecting rivals in one pass — a
  --    single closed loop can legitimately cut into multiple different rivals at
  --    once (e.g. a loop straddling two neighboring rival plots), not just one.
  UPDATE territories
    SET geom = ST_CollectionExtract(ST_Difference(geom, merged_geom), 3)
    WHERE user_id != user_uuid AND ST_Intersects(geom, merged_geom);

  -- 5. Cleanup: drop slivers left behind by the cut
  DELETE FROM territories WHERE user_id != user_uuid AND ST_Area(geom::geography) < 1.0;
END;
$$ LANGUAGE plpgsql;
```

Notes:
- Runs at default `READ COMMITTED` isolation — the explicit `FOR UPDATE` lock is what guarantees correctness, so `SERIALIZABLE` (and its retry-on-conflict overhead) isn't needed.
- `ORDER BY id` on the lock acquisition is required to prevent deadlock when two transactions intersect the same two rows in opposite order.
- Step 4 deliberately does not stop at the first intersecting rival — the user story's acceptance criteria ("Any area where the shapes overlap is instantly subtracted from the rival") doesn't restrict this to a single rival, and the original Plan 2 RPC sketch was ambiguous on this point.

### Territory Decay
*   Nightly `pg_cron` job shrinks polygons with `last_defended_at` older than `territoryDecayGracePeriod` (7 days) via `ST_Buffer(geom::geography, -5.0)`; deletes any that shrink to `ST_IsEmpty`.
*   `last_defended_at` is refreshed every time a user's `capture_territory` call touches that polygon (claim, merge, or successful defense against a steal attempt on it) — running *through* owned land via Story #1's tracking (not necessarily closing a new loop there) should also bump it, since the user story says "doesn't run through or near their territory."
*   **New — decay warning (gap in the user story)**: the story specifies the shrink mechanic but never tells the user it's coming, which makes territory loss feel arbitrary. Add a scheduled check (same `pg_cron` job, or a separate daily query) that flags territories within 1–2 days of `territoryDecayGracePeriod` and triggers a push notification via the existing `flutter_local_notifications` setup ("Your territory near {area} is decaying — run there soon"), reusing the alarm feature's notification plumbing rather than building new notification infrastructure.

---

## 4. The Leaderboard

*   **Scope (resolved — gap in the user story)**: the story's narrative framing says "I know who the dominant runners are *in my area*," but the acceptance criteria describe a flat global ranking. These conflict. Recommend shipping **both**: a global leaderboard (simple `SUM(ST_Area(geom::geography)) GROUP BY user_id`, matches the literal acceptance criteria) plus a geographic filter scoped to a bounding box or H3 cell around the viewer's current territory, so a new player in a sparse area isn't permanently invisible against someone who's dominated a dense city for months. Flag this back to the user/product owner as a scope decision before building the SQL view, not after — it changes the view's `GROUP BY` and indexing.
*   **Realtime**: Supabase Realtime subscription on the leaderboard view/table so rankings shift live as territory changes hands.

---

## Verification Plan

### Automated Tests
*   Dart unit tests: Haversine distance, RDP simplification output, speed-cap logic, minimum-loop-area rejection.
*   Database tests: insert overlapping polygons, verify `ST_Union`/`ST_Difference` results, verify the multi-rival contestation path (one loop cutting two different rivals' territory in one transaction), verify sliver cleanup.
*   **New — concurrency test**: open two concurrent DB sessions, call `capture_territory` from both against geometries that overlap the same rival polygon, and assert the combined resulting area is conserved (no double-subtraction, no resurrected stolen land). This is the regression test for the row-locking fix in §3.

### Manual Verification
*   Run in iOS Simulator / Android Emulator using GPS-simulated GPX playback of a closed loop.
*   Verify polygon renders correctly on `flutter_map`.
*   Simulate a second user's loop cutting through the first user's polygon; verify the slice is visible and correct.
*   Manually trigger the decay cron job against a territory with a backdated `last_defended_at` and verify both the shrink and the warning notification fire.

---

## Product Decisions (resolved)

These were open requirements gaps surfaced while reviewing the user story. Decided below so the plan can move to implementation without further sign-off; revisit only if a decision proves wrong in practice.

1. **Leaderboard scope → both, global default + geographic filter.**
   Ship the global view first since it's the literal acceptance criteria and is one `GROUP BY` — don't block v1 on it. Add the geographic filter (bounding box around the viewer's current map position, not a fixed city list) as a second view in the same release, since the story's own framing ("dominant runners *in my area*") makes a global-only leaderboard feel broken for any new player outside a dense city. Toggle between the two with a simple segmented control on the leaderboard screen; default to "Nearby" on first open (more motivating for a new player than seeing they're #4,812 globally), with "Global" one tap away.

2. **Minimum loop area → 50 sqm, fixed (not distance-scaled).**
   Distance-scaling adds a formula the user has to mentally model ("why did my loop not count this time") for marginal cheat-resistance benefit — the 200m minimum traversal distance from §2 already rules out trivially small loops, since any loop enclosing under ~50 sqm while also covering 200m of path is already geometrically a thin sliver, not a "real" lap. Keep the constant simple and tune it once with real usage data if 50 sqm proves too strict/loose, rather than guessing at a formula upfront.

3. **Multi-rival contestation → confirmed as designed.**
   One closed loop steals from every rival territory it overlaps in the same transaction, not just the first or largest. This matches the literal acceptance criteria in Story #3 ("any area where the shapes overlap is instantly subtracted") and is already how the RPC in §3 is written — no change needed, just confirming the design choice stands.

4. **Decay warning channel → push notification, reusing existing alarm infra.**
   Use `flutter_local_notifications` (already a dependency, already wired for alarms) rather than building a separate in-app badge system. A badge only reaches users who happen to open the app before decay hits; a push notification is what actually prevents the silent-loss experience the story's decay mechanic risks. An in-app badge can be added later as a cheap supplement (surface it on the dashboard alongside the existing streak ring) but isn't required for v1 — don't build two notification paths before one is validated.
