# Territory Capture — Backend Verification Results

Verified live against the `awaken` Supabase project (`fsdfqcnjcjtdmdjshrvu`,
ap-northeast-1) via the Supabase MCP tools on 2026-07-02.

**Fresh migration (2026-07-08):** Schema rebuilt on new project `nankdbntvvopnfvvvaoo`
(ap-southeast-1, Postgres 17) via MCP `apply_migration`. Auth dashboard setup
required — see [`docs/supabase_auth_setup.md`](supabase_auth_setup.md). This replaces the
original speculative checklist now that the actual schema/RPCs/policies
have been inspected directly (`list_tables`, `execute_sql` against
`pg_proc`/`pg_policies`/`information_schema`, `get_advisors`).

## ✅ 1. RPCs — signatures match the client exactly

| RPC | Security | Returns |
|---|---|---|
| `capture_territory(new_geom geometry)` | `DEFINER` | `(claimed_area_sqm, total_owned_area_sqm, rivals_affected)` |
| `touch_territory_defense(run_path geometry)` | `DEFINER` | `void` |
| `leaderboard_nearby(viewer_lon, viewer_lat, radius_meters default 5000)` | `DEFINER` | `(user_id, display_name, total_area_sqm, rank)` |
| `decaying_territories()` | `INVOKER` | `(id, days_until_decay, area_sqm)`, scoped via internal `WHERE user_id = auth.uid()` |

`leaderboard_global` is a view with the same shape as `leaderboard_nearby`
minus the distance filter. The client's `*Model.fromJson` snake_case keys
(`claimed_area_sqm`, `total_owned_area_sqm`, `days_until_decay`, `area_sqm`,
`total_area_sqm`) match these column names exactly — **no mismatch**. (My
original checklist guessed slightly different names before I could actually
read the live schema — those guesses were wrong; the real code was already
correct.)

Territory reads go through a `territories_geojson` view (not the raw
`territories` table) with columns `id, user_id, display_name, geojson,
area_sqm, last_defended_at` — also an exact match for `TerritoryModel`.

## ✅ 2. Concurrency: row-locking on capture — already correctly implemented

`capture_territory`'s actual body:

```sql
-- 1. Lock every existing row this capture will touch, in a stable order, BEFORE
--    reading/mutating any of them — prevents concurrent captures from reading
--    stale rival geometry and clobbering each other's steals.
PERFORM 1 FROM territories
  WHERE ST_Intersects(geom, new_geom)
  ORDER BY id
  FOR UPDATE;
```

This locks **every** intersecting row (own + rival) in stable `id` order
before any read/mutation — exactly the fix the plan flagged as an open
concurrency risk. It's already done, not a gap.

## ✅ 3. RLS policies — correct

- `territories`: RLS enabled, single policy `territories_select_all` (`SELECT`, `true`, `authenticated`) — anyone signed in can read the whole shared map. **No `INSERT`/`UPDATE`/`DELETE` policy exists**, so direct writes are impossible for any client role; the only way to mutate the table is through the `SECURITY DEFINER` RPCs, which is exactly the intended anti-cheat boundary.
- `alarms`, `sessions`, `streaks`: RLS enabled, scoped to `auth.uid() = user_id`.
- `runs`: RLS enabled, `SELECT`/`INSERT` scoped to own rows.
- `profiles`: RLS enabled, public `SELECT`, own-row `UPDATE`.

## ✅ 4. PostGIS correctness — correct

- `ST_MakeValid` is applied to the incoming polygon (`ST_Multi(ST_MakeValid(new_geom))`) before any union/difference.
- `ST_Area` is always computed on a `::geography` cast, never raw degrees.
- SRID is explicitly set to `4326` in the function (`ST_SetSRID(new_geom, 4326)`), and the `territories.geom` column's registered SRID is confirmed `4326` / `MULTIPOLYGON` via `geometry_columns`.
- A GiST index exists on `territories.geom` (`territories_geom_gist_idx`).

## ✅ 5. Realtime — enabled

`territories` is confirmed present in the `supabase_realtime` publication (`pg_publication_tables`), so `territoryListProvider.watchTerritories()` will receive live updates.

## Advisor findings — fix attempt results (2026-07-02)

1. **`public.spatial_ref_sys` has RLS disabled** (Supabase advisor: `CRITICAL`) — **not fixable via migration.** Attempted `ALTER TABLE public.spatial_ref_sys ENABLE ROW LEVEL SECURITY;` and it failed: `ERROR: 42501: must be owner of table spatial_ref_sys`. This table is owned by the `postgis` extension's installing role, not the role migrations run as on this project — a known Supabase/PostGIS platform limitation, not something client-side tooling can work around. Real risk is low (it only holds public SRID/projection reference constants, not user data), but if you want it fixed, it has to be done from the Supabase SQL editor logged in with sufficient privilege, or left as an accepted platform-level exception.
2. **`postgis` extension installed in the `public` schema** (WARN) — **not attempted.** Checked `pg_extension.extrelocatable` for `postgis` on this project: `false`. A non-relocatable extension can't be moved with `ALTER EXTENSION ... SET SCHEMA`; doing it safely would require dropping and recreating the extension (and everything that depends on the `geometry`/`geography` types — the `territories` and `territory_captures` tables, every capture/leaderboard RPC) in a maintenance window, which is too destructive to run unattended. Leaving as-is; revisit only as a deliberate, backed-up migration if this ever needs to be resolved.
3. **`capture_territory`, `leaderboard_nearby`, `touch_territory_defense`, `leaderboard_windowed` are `SECURITY DEFINER` and callable by `authenticated`** (WARN) — confirmed **intentional**, not fixed: these functions need elevated privilege to write across other users' territory rows (the steal mechanic) and to read across `profiles` for leaderboards, which plain RLS wouldn't permit for an ordinary caller. Verified none of them are callable by `anon` (checked `information_schema.routine_privileges`) — `leaderboard_windowed` initially inherited an `anon` grant from Supabase's schema-level default privileges and was explicitly revoked to match the others.
4. **Leaked-password protection disabled** (WARN) — **not fixable via SQL/MCP.** This is an Auth service setting (HaveIBeenPwned check), not a database object; none of the available Supabase MCP tools expose Auth config. Enable it manually: Supabase Dashboard → Authentication → Policies → "Leaked password protection".
5. `unused_index` / `auth_rls_initplan` performance notices on `alarms`/`sessions`/`runs` — pre-existing, unrelated to territory capture, left alone.

## ✅ Built: leaderboard time-window filters (24h / 7d / all-time)

Previously flagged as needing new backend work — now implemented and live on `fsdfqcnjcjtdmdjshrvu`:

- **`territory_captures`** — new append-only history table (`id, user_id, geom, area_sqm, rivals_affected, captured_at`) logging every successful capture. RLS enabled, `SELECT` open to `authenticated` (needed for the shared leaderboard), no `INSERT`/`UPDATE`/`DELETE` policy — only written by `capture_territory` as `SECURITY DEFINER`, same write-boundary pattern as `territories`. GiST index on `geom`, btree indexes on `user_id`/`captured_at`.
- **`capture_territory`** now inserts one row into `territory_captures` per successful capture (using the raw claimed-loop geometry, not the merged total, so spatial "nearby" windowed queries reflect where that specific run happened).
- **`leaderboard_windowed(window_hours, viewer_lon, viewer_lat, radius_meters)`** — new RPC, `SUM(area_sqm)` from `territory_captures` within the window, optionally scoped with `ST_DWithin` when viewer coordinates are supplied (mirrors the nearby/global split of the existing RPCs). Callable by `authenticated` only (verified `anon` has no grant).
- **Client**: `LeaderboardWindow` enum (`day` / `week` / `allTime`) + `leaderboardWindowProvider`; `leaderboardProvider` now branches to `getWindowedLeaderboard` for `day`/`week` and keeps the original current-ownership RPCs for `allTime` (default, so existing behavior is unchanged unless a user picks a window). Offline/local mode has no capture-history log, so `TerritoryLocalRepositoryImpl.getWindowedLeaderboard` falls back to current standings — documented in that method's doc comment. UI: a secondary `24H / 7D / ALL` pill row on `territory_leaderboard_screen.dart`, below the Nearby/Global toggle, with header/hint copy that distinguishes "momentum" (captured recently) from "current ownership".
- `flutter analyze lib/` — no issues.

## ✅ Repo migrations baseline (2026-07-02)

The live remote project already had migrations applied via the Supabase dashboard
(see `list_migrations` — versions `20260628…` through `20260701…`). This repo
now also carries a **consolidated baseline** under `supabase/migrations/`
(`20250702…` series) that mirrors the verified live schema for local dev and
version control:

| File | Contents |
|---|---|
| `20250702000001_enable_postgis.sql` | PostGIS extension |
| `20250702000002_core_app_schema.sql` | `profiles`, `alarms`, `sessions`, `streaks`, RLS, `handle_new_user` trigger |
| `20250702000003_territory_tables.sql` | `territories`, `runs`, `territory_captures`, RLS |
| `20250702000004_territory_views.sql` | `territories_geojson`, `leaderboard_global` |
| `20250702000005_territory_rpcs.sql` | All five territory RPCs |
| `20250702000006_territory_grants.sql` | `authenticated`-only EXECUTE grants |
| `20250702000007_realtime_publication.sql` | `supabase_realtime` on `territories` |

**Do not re-apply** this baseline to the linked remote (`fsdfqcnjcjtdmdjshrvu`) —
objects already exist. For a fresh local stack: `supabase start` then
`supabase db reset`. After linking an empty project, use
`supabase migration repair --status applied` on each version instead of running
the SQL twice.

## Fresh migration on `nankdbntvvopnfvvvaoo` (2026-07-08)

Applied via Supabase MCP `apply_migration`:

| Migration | Status |
|---|---|
| `enable_postgis` | Applied |
| `core_app_schema` | Applied |
| `territory_tables` | Applied |
| `territory_views` | Applied (updated with `security_invoker = true`) |
| `territory_rpcs` | Applied |
| `territory_grants` | Applied |
| `realtime_publication` | Applied |
| `performance_optimization_fixes` | Applied |
| `revoke_anon_rpc_grants` | Applied (Supabase default re-granted anon EXECUTE) |
| `security_invoker_views_and_handle_new_user` | Applied |

### Advisor findings (accepted)

| Finding | Action |
|---|---|
| `spatial_ref_sys` RLS disabled | Platform PostGIS limitation — accept |
| `postgis` in `public` schema | Non-relocatable — accept |
| Territory RPCs `SECURITY DEFINER` + `authenticated` EXECUTE | Intentional steal mechanic |
| `st_estimatedextent` / `rls_auto_enable` anon EXECUTE | PostGIS/platform defaults — accept |
| `unused_index` (performance INFO) | Expected on empty DB — indexes will be used under load |

### Pending manual step

Google OAuth + email auth: see [`docs/supabase_auth_setup.md`](supabase_auth_setup.md).
