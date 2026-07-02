# Territory Capture Feature Research Report (Awaken Flutter App)

## 1. Outcome-first recommendation

Use your current `flutter_map + geolocator + Supabase/PostGIS` foundation as the primary implementation path, then add a **visual-quality upgrade layer** (vector tiles + offline-ready tile container) only where needed for "Google-map-like" polish. This is the lowest-risk path because your territory feature is already structurally aligned with the user story (tracking, loop closure, anti-cheat, capture, leaderboard), and most remaining work is **quality/completeness hardening**, not a rewrite.

Key reason: your code already implements core gameplay mechanics and backend wiring (`capture_territory`, `touch_territory_defense`, nearby/global leaderboard, realtime watch, Kalman + RDP + speed checks), so replacing map stack now would increase regression risk without guaranteed visual gain.  
Evidence: `lib/features/territory/presentation/screens/territory_run_screen.dart`, `.../active_run_providers.dart`, `.../territory_supabase_datasource.dart`, `.../territory_providers.dart`, `territory_capture_user_story.md`.

---

## 2. What already exists in your app (audit)

## 2.1 User story coverage status

From `territory_capture_user_story.md`:
- Story 1 (Track run + anti-cheat): implemented client-side speed cap and live path tracking (`maxRunSpeedKmh`, Kalman smoothing, RDP simplification, rolling speed check).  
  Evidence: `territory_capture_user_story.md:11-16, 90-96`, `lib/core/constants/app_constants.dart:42-60`, `lib/features/territory/presentation/providers/active_run_providers.dart:130-183`, `.../run_validation_service.dart:12-54`, `.../gps_kalman_filter.dart:1-44`.
- Story 2 (close loop within 20m and claim): implemented loop closure threshold and capture RPC.  
  Evidence: `territory_capture_user_story.md:25-29`, `app_constants.dart:47`, `run_validation_service.dart:29-33`, `territory_supabase_datasource.dart:77-83`.
- Story 3 (steal overlaps): implemented by server-side capture RPC contract and local simulation fallback repo.  
  Evidence: `territory_capture_user_story.md:39-43`, `territory_repository.dart:18-24`, `territory_local_repository_impl.dart:118-306`.
- Story 4 (leaderboard by total area): implemented nearby/global modes and sorted display.  
  Evidence: `territory_capture_user_story.md:52-55`, `territory_providers.dart:29-52`, `territory_leaderboard_screen.dart`.

## 2.2 Existing UI quality baseline

Strengths:
- Dark map + neon territory visual language already matches game tone.
- Clear run controls in thumb zone and map HUD guidance.
- Follow-me toggle, zoom rail, start/current markers, closure feedback.
- Good rebuild isolation (`_TerritoryMapView` and `_RunStatsSheetConsumer` split) for runtime performance.

Evidence:
- `territory_run_screen.dart:31-40, 229-327, 458-605`
- `run_stats_sheet.dart`
- `run_controls.dart`
- `territory_polygon_layer.dart`

Gaps:
- Tile attribution is missing from map widget in run screen despite provider requirements.
- Tile source is fixed to Carto dark raster URL, no provider abstraction, no fallback strategy.
- No dedicated "territory details / ownership context / conflict summary" screen after capture.
- No explicit map loading/error empty-state overlay around tile failures.

Evidence:
- Tile layer usage: `territory_run_screen.dart:505-512`
- No attribution widget in the map children list in that file.

## 2.3 Backend integration baseline

Current app-side backend contract is solid:
- Realtime territory stream on `territories` table changes.
- RPC-driven spatial actions (`capture_territory`, `touch_territory_defense`, `leaderboard_nearby`, `decaying_territories`).
- Run persistence in `runs` table.

Evidence: `territory_supabase_datasource.dart:18-121`.

Main uncertainty:
- SQL migrations/functions are not in repo (`supabase/**/*.sql` not found), so final server truth must be validated in Supabase project directly.

---

## 3. Package + ecosystem research (open-source and authenticity)

Below are practical package choices that satisfy "no Google Maps API" and open-source constraints.

| Package | Role | License | Signal | Recommendation |
|---|---|---|---|---|
| `flutter_map` | Core map renderer | BSD-3-Clause ([license](https://raw.githubusercontent.com/fleaflet/flutter_map/master/LICENSE)) | Active docs + recent releases ([pub API](https://pub.dev/api/packages/flutter_map), repo metadata via `gh api repos/fleaflet/flutter_map`) | **Keep as base** |
| `geolocator` | GPS + permissions | MIT ([license](https://raw.githubusercontent.com/Baseflow/flutter-geolocator/main/LICENSE)) | Mature multi-platform plugin ([pub API](https://pub.dev/api/packages/geolocator)) | **Keep** |
| `vector_map_tiles` | Vector tile rendering for `flutter_map` | BSD-3-Clause ([license](https://raw.githubusercontent.com/greensopinion/flutter-vector-map-tiles/main/LICENSE)) | Community plugin; known performance caveats in docs ([raster vs vector](https://docs.fleaflet.dev/why-and-how/how-does-it-work/raster-vs-vector-tiles.md)) | **Optional visual upgrade** |
| `flutter_map_pmtiles` | PMTiles source (single-file tiles) | MIT ([package license file](https://github.com/josxha/flutter_map_plugins/blob/main/flutter_map_pmtiles/LICENSE), [pub API](https://pub.dev/api/packages/flutter_map_pmtiles)) | Good for offline/distribution strategy | **Recommended for offline path** |
| `maplibre_gl` | Alternative map engine | Mixed permissive (BSD-family in plugin stack) ([pub API](https://pub.dev/api/packages/maplibre_gl), [license file](https://github.com/maplibre/flutter-maplibre-gl/blob/main/maplibre_gl/LICENSE)) | Now active under MapLibre org | **Only if you need native vector style parity and accept migration cost** |
| `flutter_map_tile_caching` | Advanced caching/bulk download | GPL-3.0 ([pub page](https://pub.dev/packages/flutter_map_tile_caching)) | Powerful, but strong copyleft | **Avoid unless your distribution model accepts GPL obligations** |

### Important licensing note

If this app will remain proprietary/closed-source, avoid GPL-licensed tile cache plugins unless legal has approved source distribution obligations. The `flutter_map` docs themselves call out GPL for FMTC and suggest alternatives in offline mapping guidance: [offline mapping docs](https://docs.fleaflet.dev/tile-servers/offline-mapping.md).

---

## 4. Map provider and policy best practices (critical for production)

For OSM direct usage, you must comply with tile usage policy:
- Visible attribution
- Distinct User-Agent
- Caching requirements (at least policy-conformant)
- No bulk scraping/prefetch abuse

Sources:
- OSM tile policy: https://operations.osmfoundation.org/policies/tiles/
- OSM copyright/attribution: https://www.openstreetmap.org/copyright
- flutter_map OSM guidance: https://docs.fleaflet.dev/tile-servers/using-openstreetmap-direct.md
- flutter_map attribution layer docs: https://docs.fleaflet.dev/layers/attribution-layer.md
- flutter_map caching docs: https://docs.fleaflet.dev/layers/tile-layer/caching.md

### Immediate code-level improvement in your app

Add an attribution widget to the run map (and any territory map surface), e.g. `RichAttributionWidget` with OSM attribution text and link.

Current evidence of missing attribution in map screen:
- `territory_run_screen.dart:481-574` has `TileLayer` + overlays but no attribution layer widget.

---

## 5. Geospatial/backend best-practice model for this feature

For territory math correctness and multiplayer concurrency, keep geometry operations server-side in PostGIS RPCs.

Recommended server operations (already aligned with your architecture):
- Validate/repair polygons: `ST_IsValid`, `ST_MakeValid`
- Merge own territory: `ST_Union`
- Steal overlap: `ST_Difference` (+ cleanup tiny slivers)
- Area in true metric units: `ST_Area(geography)` (square meters)
- Nearby queries: `ST_DWithin` using GiST indexes

Sources:
- PostGIS: `ST_Union`, `ST_Difference`, `ST_Intersection`, `ST_MakeValid`, `ST_IsValid`, `ST_Area`, `ST_DWithin`  
  https://postgis.net/docs/ST_Union.html  
  https://postgis.net/docs/ST_Difference.html  
  https://postgis.net/docs/ST_Intersection.html  
  https://postgis.net/docs/ST_MakeValid.html  
  https://postgis.net/docs/ST_IsValid.html  
  https://postgis.net/docs/ST_Area.html  
  https://postgis.net/docs/ST_DWithin.html
- Supabase PostGIS + RPC + realtime + RLS:  
  https://supabase.com/docs/guides/database/extensions/postgis  
  https://supabase.com/docs/guides/database/functions  
  https://supabase.com/docs/guides/realtime/postgres-changes  
  https://supabase.com/docs/guides/database/postgres/row-level-security

### Backend safety checklist

1. `territories.geom` should be `geometry(MultiPolygon, 4326)` with GiST index.
2. Capture RPC should lock intersecting rows before mutate (to avoid race corruption).
3. RLS must explicitly guard by `auth.uid()` and role.
4. Realtime publication should include all mutated tables/views used by client listeners.
5. Nearby leaderboard should rely on spatial indexable predicates (`ST_DWithin`).

---

## 6. UI/UX research-driven design spec for "perfect map" experience

## 6.1 Visual direction (without Google Maps API)

Two viable paths:

### Path A (recommended first): High-quality raster with strong overlay design
- Keep `flutter_map` raster tiles.
- Invest in overlay quality: neon territories, glow trails, depth, motion cues, conflict highlights.
- Fastest and most stable path given current code.

### Path B (phase 2): Vector style parity
- Introduce `vector_map_tiles` for crisper zoom + style control.
- Pair with PMTiles/vector tile source strategy for better consistency and optional offline.
- Must profile heavily: docs warn of FPS/jank risks for vector rendering on main thread.
  Source: https://docs.fleaflet.dev/why-and-how/how-does-it-work/raster-vs-vector-tiles.md

## 6.2 Screen-by-screen UX spec

### A) Territory Run Screen (existing, enhance)
- Add attribution, map source badge, and connection status.
- Add "GPS quality chip" (good/fair/poor) based on accuracy field.
- Distinguish run states with stronger visual hierarchy:
  - Idle: CTA emphasis
  - Tracking: minimal chrome, strong closure guidance
  - Finishing: locked interactions + deterministic progress state
- Add conflict prediction hint ("You are crossing rival territory") when path intersects rival polygons.

Existing base: `territory_run_screen.dart`, `run_stats_sheet.dart`, `run_controls.dart`.

### B) Capture Result Surface (new/expanded)
- Replace transient text-only banner with a richer bottom sheet:
  - Claimed area
  - Total owned area
  - Rival(s) affected
  - Tiny minimap thumbnail before/after
- Include "Share result" and "View leaderboard" actions.

### C) Leaderboard Screen (existing, enhance)
- Keep Nearby/Global segmented control (already implemented).
- Add filter chips for window (`24h`, `7d`, `all-time`) if backend supports.
- Add row affordance to jump map camera to top user territory centroid (privacy-safe if public mode).

Existing base: `territory_leaderboard_screen.dart`.

### D) Territory Overview / Ownership Screen (new)
- Personal stats (current area, weekly delta, contested zones).
- Decay risk card (already has provider support for warnings).
- List of owned polygons sorted by risk/last defended.

Provider baseline: `decayWarningsProvider` in `territory_providers.dart`.

## 6.3 Interaction details

- Keep thumb-zone primary action placement (already strong in your current design).
- Haptic differentiation:
  - claim success: medium
  - steal success: heavy
  - invalidation: warning vibration pattern
- Accessibility:
  - minimum tap targets >= 44dp
  - do not encode ownership solely by red/blue color; include texture/pattern option for color-vision deficiency mode.

---

## 7. Anti-cheat and location-quality recommendations

Your current speed-cap + smoothing approach is good for v1. For stronger anti-cheat:

1. Keep rolling speed invalidation and expose warning early (already in HUD).
2. Add optional activity classification (walk/run/in_vehicle) as a second signal for suspicious runs.
3. Keep strict loop-closure + min distance + min duration + min area checks.
4. On backend, reject geometrically invalid or degenerate loops before mutation.

Current implementation references:
- Speed cap and closure constants: `app_constants.dart:46-55`
- Runtime checks and classification: `run_validation_service.dart`
- Kalman and RDP: `gps_kalman_filter.dart`, `active_run_providers.dart:174-183`

Permissions and platform guidance:
- Geolocator config + Android 14 foreground location permission note: https://pub.dev/packages/geolocator
- Android location permissions model: https://developer.android.com/develop/sensors-and-location/location/permissions

---

## 8. Performance plan for map perfection

From flutter_map docs and your codebase, the right optimization stack is:

1. Keep culling and simplification enabled; tune `simplificationTolerance` by zoom level if needed.  
   Sources: polygon/polyline layer docs  
   https://docs.fleaflet.dev/layers/polygon-layer.md  
   https://docs.fleaflet.dev/layers/polyline-layer.md
2. Continue isolating map rebuilds from timer ticks (already done).
3. Cap polyline point rendering window for active trail at high point counts (e.g., decimate visual trail while preserving full backend path).
4. Use persistent tile caching provider strategy compliant with tile policy.
5. If moving to vector tiles, profile old/low-end Android devices first; vector path can regress FPS.

---

## 9. Concrete implementation blueprint for this repository

## Phase 1 (ship-quality hardening, minimal architecture risk)
1. Add attribution layer and tile-source abstraction to `TerritoryRunScreen`.
2. Add map loading/error overlays and retry UX.
3. Add richer capture result sheet using existing `CaptureResultEntity`.
4. Add territory overview screen and route (decay warnings + owned area insights).
5. Validate all Supabase RPCs and RLS policies in live DB against contracts in `territory_supabase_datasource.dart`.

## Phase 2 (visual parity uplift)
1. Introduce optional vector rendering path (`vector_map_tiles`) behind feature flag.
2. Add PMTiles support for deterministic map style/offline scenarios (`flutter_map_pmtiles`).
3. Implement dynamic style tokens mapped to existing `AppColors` so map and UI feel unified.

## Phase 3 (competitive polish)
1. Conflict prediction overlays during run.
2. Replay/after-action map animation.
3. Territory health/decay visual gradient and reminders.

---

## 10. Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Missing tile attribution/policy compliance | Blocking/usage suspension by provider | Add attribution + UA + compliant caching immediately |
| SQL logic drift between app assumptions and DB functions | Incorrect capture outcomes | Lock down RPC versioning and integration tests |
| Vector tile migration jank | UX regression on low-end devices | Feature flag + performance thresholds before default-on |
| GPL dependency accidental inclusion | License conflict for proprietary distribution | Prefer MIT/BSD alternatives; legal review before adoption |
| Realtime-only assumptions under network instability | stale map state | optimistic local UI + periodic full refresh + reconnect handling |

---

## 11. Final recommendation

For this codebase, do **not** replace `flutter_map` right now.  
Ship a polished v1 by hardening policy compliance, map UX states, capture result experience, and backend correctness. Then selectively add vector tiles/PMTiles for visual parity where profiling proves it safe.

This gives you the best balance of:
- feature completeness against the user story,
- open-source/authentic dependency requirements,
- production safety for geospatial multiplayer logic.

---

## 12. Evidence index (repo + web)

### Repo evidence reviewed
- `territory_capture_user_story.md`
- `pubspec.yaml`
- `lib/features/territory/presentation/screens/territory_run_screen.dart`
- `lib/features/territory/presentation/screens/territory_leaderboard_screen.dart`
- `lib/features/territory/presentation/widgets/territory_polygon_layer.dart`
- `lib/features/territory/presentation/widgets/run_controls.dart`
- `lib/features/territory/presentation/widgets/run_stats_sheet.dart`
- `lib/features/territory/presentation/providers/active_run_providers.dart`
- `lib/features/territory/presentation/providers/territory_providers.dart`
- `lib/features/territory/domain/services/run_validation_service.dart`
- `lib/features/territory/domain/services/gps_kalman_filter.dart`
- `lib/features/territory/domain/services/geo_utils.dart`
- `lib/features/territory/data/datasources/territory_supabase_datasource.dart`
- `lib/features/territory/data/repositories/territory_supabase_repository_impl.dart`
- `lib/features/territory/data/repositories/territory_local_repository_impl.dart`
- `lib/features/territory/data/models/territory_geo_codec.dart`
- `lib/core/theme/app_colors.dart`
- `lib/core/theme/app_typography.dart`
- `lib/core/constants/app_constants.dart`

### Web evidence reviewed
- flutter_map docs and policies:
  - https://docs.fleaflet.dev/
  - https://docs.fleaflet.dev/llms.txt
  - https://docs.fleaflet.dev/layers/attribution-layer.md
  - https://docs.fleaflet.dev/layers/tile-layer/caching.md
  - https://docs.fleaflet.dev/tile-servers/using-openstreetmap-direct.md
  - https://docs.fleaflet.dev/tile-servers/offline-mapping.md
  - https://docs.fleaflet.dev/layers/polyline-layer.md
  - https://docs.fleaflet.dev/layers/polygon-layer.md
  - https://docs.fleaflet.dev/why-and-how/how-does-it-work/raster-vs-vector-tiles.md
- OSM requirements:
  - https://operations.osmfoundation.org/policies/tiles/
  - https://www.openstreetmap.org/copyright
- Supabase/PostGIS:
  - https://supabase.com/docs/guides/database/extensions/postgis
  - https://supabase.com/docs/guides/database/functions
  - https://supabase.com/docs/guides/realtime/postgres-changes
  - https://supabase.com/docs/guides/database/postgres/row-level-security
  - https://postgis.net/docs/ST_Intersection.html
  - https://postgis.net/docs/ST_Difference.html
  - https://postgis.net/docs/ST_Union.html
  - https://postgis.net/docs/ST_MakeValid.html
  - https://postgis.net/docs/ST_IsValid.html
  - https://postgis.net/docs/ST_Area.html
  - https://postgis.net/docs/ST_DWithin.html
- Package/authenticity signals:
  - https://pub.dev/api/packages/flutter_map
  - https://pub.dev/api/packages/geolocator
  - https://pub.dev/api/packages/vector_map_tiles
  - https://pub.dev/api/packages/flutter_map_pmtiles
  - https://pub.dev/api/packages/maplibre_gl
  - https://raw.githubusercontent.com/fleaflet/flutter_map/master/LICENSE
  - https://raw.githubusercontent.com/Baseflow/flutter-geolocator/main/LICENSE
  - https://raw.githubusercontent.com/greensopinion/flutter-vector-map-tiles/main/LICENSE
  - https://github.com/maplibre/flutter-maplibre-gl/blob/main/maplibre_gl/LICENSE
  - https://github.com/josxha/flutter_map_plugins/blob/main/flutter_map_pmtiles/LICENSE

### Additional package health snapshot
- Retrieved via GitHub API (`gh api repos/...`):
  - `fleaflet/flutter_map`
  - `baseflow/flutter-geolocator`
  - `greensopinion/flutter-vector-map-tiles`
  - `maplibre/flutter-maplibre-gl`
  - `josxha/flutter_map_plugins`

