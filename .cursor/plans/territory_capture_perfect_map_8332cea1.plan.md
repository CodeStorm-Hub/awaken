---
name: Territory Capture Perfect Map
overview: "Harden and visually perfect the already-largely-implemented Territory Capture feature: replace the licensing-risky CartoDB raster basemap with a fully free, open-source vector-tile stack (OpenFreeMap + vector_map_tiles) for genuine \"Google Maps-like\" rendering quality, then add the missing UX surfaces (capture result sheet, territory overview screen, GPS-quality/conflict cues) identified against the user story and existing research."
todos:
  - id: map-engine
    content: Add vector_map_tiles dependency; build OpenFreeMap dark-style loader + bundled re-themed style asset
    status: completed
  - id: map-layer-swap
    content: Replace raster TileLayer with VectorTileLayer in territory_run_screen.dart; add RichAttributionWidget and tile-error/retry overlay
    status: completed
  - id: run-hud-polish
    content: Add GPS quality chip and rival-territory conflict cue to the run HUD
    status: completed
  - id: capture-result-sheet
    content: Build capture_result_sheet.dart bottom sheet (claimed area, minimap, share, view leaderboard) and wire into _onRunFinished
    status: completed
  - id: territory-overview-screen
    content: Build territory_overview_screen.dart (owned-area stats, decay risk list) + overlay route + nav entry points
    status: completed
  - id: leaderboard-enhancements
    content: Add leaderboard tap-to-locate; document backend RPC change needed for time-window filters
    status: completed
  - id: backend-verification
    content: Flag manual verification checklist for Supabase RPCs/RLS/row-locking against the live project
    status: completed
isProject: false
---

# Territory Capture — Map Perfection & Feature Completion Plan

## 0. Audit findings (confirmed by reading the actual code, not just the prior research doc)

The feature is **already functionally implemented**, not greenfield:
- All 4 user stories (track run, closed-loop claim, steal/contest, leaderboard) are wired end-to-end: [lib/features/territory/presentation/providers/active_run_providers.dart](lib/features/territory/presentation/providers/active_run_providers.dart), [lib/features/territory/data/datasources/territory_supabase_datasource.dart](lib/features/territory/data/datasources/territory_supabase_datasource.dart), [lib/features/territory/presentation/screens/territory_leaderboard_screen.dart](lib/features/territory/presentation/screens/territory_leaderboard_screen.dart).
- Anti-cheat (speed cap, Kalman filter, RDP simplification, min-area/min-duration checks) is implemented per `territory_capture_implementation_plan_2.md`'s resolved product decisions.
- Territory decay warnings already trigger a **push notification** via `TerritoryDecayNotificationService`, wired from `dashboard_screen.dart` (`decayWarningsProvider`) — this was listed as a "gap" in `research/research-territory_capture_user_story.md` but is actually done.
- There are uncommitted local edits already in flight (`git diff --stat`) that are pure copy/label polish (sentence case, header text) — no structural changes. This plan builds on top of them, doesn't redo them.

Real remaining gaps, confirmed by reading `territory_run_screen.dart`, `territory_polygon_layer.dart`, `territory_providers.dart`, `app_router.dart`:
1. **Map tile source is CartoDB Dark Matter raster, fetched directly from `basemaps.cartocdn.com`** — no attribution widget in the widget tree at all.
2. No map loading/error/retry UX for tile failures.
3. Capture result is a plain auto-dismissing text banner (`_ResultBanner`), not a rich result surface.
4. No territory-overview/ownership screen (decay risk list, owned-area stats) despite `decayWarningsProvider` already existing.
5. No GPS-quality indicator or rival-territory conflict cue during a run.
6. No leaderboard time-window filter or "jump to territory" affordance.

## 1. Critical finding not in prior research: CartoDB tile licensing risk

Verified directly against CARTO's current license terms (`docs.carto.com/faqs/carto-basemaps`, `github.com/CartoDB/basemap-styles/LICENSE.md`): **CARTO's hosted basemap tiles (including Dark Matter, used today at `{s}.basemaps.cartocdn.com/dark_all/...`) require a paid CARTO Enterprise license for any commercial use.** Free access is grantee/non-commercial only. Stadia Maps (an alternative raster dark style) has the same restriction — free tier is explicitly "non-commercial use" only. Shipping the app today, unmodified, carries real compliance risk.

**Resolution — switch to [OpenFreeMap](https://openfreemap.org/):** fully open-source (self-hostable), OSM-sourced vector tiles, publicly hosted with **no API key, no registration, no request limits, free for commercial use**, funded by donations. It ships a ready-made `dark` style (`https://tiles.openfreemap.org/styles/dark`, forked from `openmaptiles/dark-matter-gl-style`) that can be forked/re-themed to match `AppColors` exactly.

This single change also gets the user the "Google Maps-like visuals" ask better than a raster-tile fix would: vector tiles render crisp at every zoom level (no pixelation on zoom), support smooth continuous zoom rather than tile-snap, and let us recolor roads/water/land/labels to match the app's neon dark theme instead of being stuck with CARTO's fixed palette.

## 2. Map engine change (Phase 1 — highest priority, "perfect map" ask)

- Add dependency: `vector_map_tiles: ^8.0.0` (BSD-3-Clause, compatible with the current `flutter_map: ^7.0.2` pin already in [pubspec.yaml](pubspec.yaml) — no flutter_map version bump needed).
- New file `lib/features/territory/presentation/widgets/territory_map_style.dart`: loads/caches the OpenFreeMap dark style via `vector_map_tiles`'s `StyleReader`, with a local `MemoryCacheStore`/`AssetCacheStore` for tile caching per the package's caching guidance.
- Fork the OpenFreeMap dark style JSON's paint properties (water/land/road/label colors) to align with `AppColors` tokens (`background`, `card`, `mutedForeground`, `primary`/`accent` hints on major roads) — ship as a bundled asset (`assets/map_styles/awaken_dark.json`) rather than fetching+re-patching at runtime, so the visual identity is deterministic and offline-cacheable.
- Replace the raster `TileLayer` in `_TerritoryMapView` (`territory_run_screen.dart:505-512`) with `VectorTileLayer` driven by the new style loader.
- Add `RichAttributionWidget` (flutter_map's built-in attribution layer) crediting OpenStreetMap + OpenMapTiles, as required by OSM's tile-usage/data license regardless of tile source.
- Add a `_MapLoadErrorOverlay` + retry action for style/tile load failures (currently silent).
- Keep a raster fallback path (behind a simple `mapEngineProvider` flag) using OSM's direct raster tiles as an emergency degrade path, since vector rendering can jank on very low-end Android — profile before defaulting to it being the *only* path, per the existing research doc's own caution (`docs.fleaflet.dev/why-and-how/how-does-it-work/raster-vs-vector-tiles`).
- Apply the same tile layer/attribution setup anywhere else a map surface exists (currently only `territory_run_screen.dart`; the new overview screen in §4 will reuse the same widget rather than duplicating tile config).

## 3. Run-screen HUD polish (Phase 2)

Building on the already-in-flight uncommitted `_RunHeader`/hint-text polish in [territory_run_screen.dart](lib/features/territory/presentation/screens/territory_run_screen.dart):
- **GPS quality chip**: small colored-dot chip (good/fair/poor) derived from `Position.accuracy` in the position stream (`active_run_providers.dart:138-162`) — surface via a new `gpsAccuracyProvider`/state field rather than a new stream.
- **Conflict prediction**: as `points` grow, point-in-polygon test the latest point against `territoryListProvider`'s rival polygons (reuse `geo_utils.dart`'s math, add a simple ray-casting point-in-polygon helper) and show a subtle "Crossing rival territory" pill next to the closure indicator.
- Both are additive to the existing `_RunStatsSheetConsumer`/`RunStatsSheet` split — keep the per-second timer isolated from the map per the existing rebuild-isolation pattern already documented in the file's own comments.

## 4. Capture Result Sheet (Phase 3 — new widget)

New file `lib/features/territory/presentation/widgets/capture_result_sheet.dart`:
- Modal bottom sheet (glassmorphic, consistent with `run_stats_sheet.dart`'s `BackdropFilter` pattern) shown from `_onRunFinished` in `territory_run_screen.dart` instead of/alongside the current `_ResultBanner`.
- Content: claimed area (`CaptureResultEntity.claimedAreaSqMeters`), new total owned area, rival(s) affected (`stoleFromRival`), a small static `FlutterMap` thumbnail zoomed to the captured polygon's bounds (reuses `TerritoryPolygonLayer` at a fixed non-interactive `MapOptions`).
- Actions: "Share result" (native share sheet via existing platform channels — no new heavy dependency required, `share_plus` if not already present) and "View leaderboard" (`context.go(AppRoutes.leaderboard)`).

## 5. Territory Overview screen (Phase 4 — new screen)

New file `lib/features/territory/presentation/screens/territory_overview_screen.dart`:
- Personal stats header: total owned area, count of owned polygons.
- Decay-risk list: consumes the already-existing `decayWarningsProvider` (currently only used for the push-notification trigger) to render sorted risk cards ("decays in 2 days").
- Entry point: since the bottom nav (`app_router.dart:130-188`) is a fixed 3-tab shell (Home/Territory/Ranks) and shouldn't grow a 4th tab for a secondary screen, add it as an **overlay route** (`/territory/overview`, alongside `/auth`, `/alarm/*` in `app_router.dart:76-95`) reached via a new icon button in `TerritoryRunScreen`'s top bar (next to the existing back button) and/or a "View details" tap target added to the dashboard's existing `_TerritoryCard`.

## 6. Leaderboard enhancements (Phase 5)

- Time-window filter chips (`24h`/`7d`/`all-time`) on `territory_leaderboard_screen.dart` — **flagged as backend-dependent**: the current `leaderboard_nearby`/global RPCs return only current totals (`territory_supabase_datasource.dart`), so this needs a corresponding SQL view/RPC change (out of client-only scope; call out explicitly to the user before building the UI for it).
- Tap-to-locate: tapping a leaderboard row centers the shared map on that user's territory centroid — reuse the new overview/map camera plumbing from §2/§5 rather than building a second map instance.

## 7. Backend validation (Phase 6 — informational, no code)

`territory_supabase_datasource.dart` assumes RPCs (`capture_territory`, `touch_territory_defense`, `leaderboard_nearby`, `decaying_territories`) and RLS policies that aren't checked into this repo (`supabase/**/*.sql` not found). This plan does not modify the Supabase project; flag to the user that these must be verified directly against the live `fsdfqcnjcjtdmdjshrvu` project before/while shipping the client changes above, especially the row-locking (`FOR UPDATE`) concurrency fix described in `territory_capture_implementation_plan_2.md` §3.

## Package additions (all open-source, license-checked)

- `vector_map_tiles: ^8.0.0` — BSD-3-Clause, actively maintained, compatible with existing `flutter_map ^7.0.2`.
- Tile/style source: OpenFreeMap public instance — no package, just an HTTP(S) endpoint; OSM-derived data, no API key, unrestricted commercial use.
- `share_plus` (only if not already a transitive dependency) for the capture-result share action — MIT license, common Flutter package.
- No GPL packages (e.g. `flutter_map_tile_caching`) introduced, consistent with the prior research's licensing caution.

## Rollout order

1. Map engine swap + attribution + error states (fixes the compliance risk and delivers the core "perfect map" visual ask).
2. HUD polish (GPS quality, conflict cue).
3. Capture result sheet.
4. Territory overview screen + route + nav entry point.
5. Leaderboard filters (client-only parts now; flag backend RPC change separately).
6. Manual backend/RLS/RPC verification against the live Supabase project.
