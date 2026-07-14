# Awaken — Codebase Review, Issue Register & Improvement Plan

> Generated 2026-07-14. Sources: a fresh read of `lib/` (145 Dart files), `pubspec.yaml` + `flutter pub outdated`, a clean `flutter analyze lib/` run, a live Supabase MCP session against project `nankdbntvvopnfvvvaoo` (`list_tables`, `get_advisors` security + performance), and the prior `PROJECT_ANALYSIS_REPORT.md` (the only doc consulted). All issue statuses below were re-verified against the live code/database — not copied forward.
>
> **Baseline health:** `flutter analyze lib/` → **0 issues**. 229 tests were passing as of the last hardening pass. The seven alarm-flow bugs from the previous report (high-knees DB constraint, sit-ups dead code, roulette hash instability, camera-permission race, frame-vs-time bad-form windows, out-of-frame debounce) are all **confirmed fixed** in the current tree. What follows is what's still open, plus new findings from this pass.

---

## 1. Issue Register

Severity: 🔴 fix before release · 🟠 fix soon · 🟡 improvement / tech debt · 🔵 acknowledge & monitor

### 1.1 New findings — application code (this review)

#### 🔴 A1. Alarm audio plays on the **media** stream — a muted phone can produce a silent alarm
[alarm_audio_service.dart](lib/core/services/alarm_audio_service.dart) creates a bare `AudioPlayer()` with no audio-session/attributes configuration. `just_audio` defaults to `USAGE_MEDIA` on Android, so the alarm's loudness follows the *media* volume slider — if the user went to bed with media volume at 0 (very common), the alarm fires visually but silently. Android maintains a separate, independently-controlled **alarm stream** (`AudioAttributes.USAGE_ALARM`) precisely for this ([Android audio output docs](https://developer.android.com/media/platform/output)).

**Fix:** the `audio_session` package is already in the dependency tree (transitive via `just_audio`). Promote it to a direct dependency and configure before playing:
```dart
final session = await AudioSession.instance;
await session.configure(const AudioSessionConfiguration(
  androidAudioAttributes: AndroidAudioAttributes(
    usage: AndroidAudioUsage.alarm,
    contentType: AndroidAudioContentType.sonification,
  ),
  androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransient,
  avAudioSessionCategory: AVAudioSessionCategory.playback, // iOS: play in silent mode
));
```
Also consider `session.setActive(true)` for audio focus, and on iOS the `.playback` category so the alarm sounds through the ring/silent switch. The out-of-frame volume ramp (`rampVolumeUp`) keeps working — it adjusts player volume within the alarm stream.

#### 🔴 A2. Pose skeleton overlay is misaligned with the camera preview (aspect-ratio mismatch)
[camera_hud_overlay.dart:95-104](lib/features/alarm/presentation/widgets/camera_hud_overlay.dart) renders the preview with `FittedBox(fit: BoxFit.cover)` — aspect-ratio-preserving, center-cropped. But [pose_overlay_painter.dart:99-141](lib/features/alarm/presentation/widgets/pose_overlay_painter.dart) maps landmarks by *independently stretching* x to `screen.width` and y to `screen.height`. Whenever the (rotated) image aspect ratio ≠ screen aspect ratio — i.e. essentially always on a portrait phone with a 4:3 sensor — the skeleton is vertically/horizontally distorted and progressively offset toward the edges. Users see joints floating off their body, which undermines trust in the "camera-verified" premise.

**Fix:** apply the same cover transform in `_toScreen`: compute `scale = max(screen.width / rotatedW, screen.height / rotatedH)`, map `(x, y) → (x·scale − cropDx, y·scale − cropDy)` where `cropDx/cropDy` recenters the overflow, *then* mirror. This is the standard approach in Google's own [ML Kit Android vision samples](https://github.com/googlesamples/mlkit) (`GraphicOverlay`). Also add `imageSize`/`rotation` to `shouldRepaint` (currently only `pose`, `isSquatting`, `accentColor` are compared).

#### 🟠 A3. Camera *hardware failure* is reported as *permission denial*
In [alarm_pose_pipeline.dart:137-147](lib/features/alarm/presentation/services/alarm_pose_pipeline.dart), a `CameraException` during `controller.initialize()` (camera in use by another app, HAL error — not rare on cheap Androids at wake time) sets `permissionDenied.value = true`. The HUD then shows "ACCESSIBILITY MODE — Camera is off … OPEN CAMERA SETTINGS", sending the user to settings for a permission they already granted. **Fix:** add a separate `cameraFailed` state with its own copy ("Camera unavailable — tap to count reps, or restart the app") and a retry button that re-runs `_openCamera()`. The tap-to-count fallback can be shared between both states.

#### 🟠 A4. Alarm list tile hardcodes "squats" for every exercise
[dashboard_screen.dart:1101](lib/features/dashboard/presentation/screens/dashboard_screen.dart) renders `'${alarm.requiredReps} squats'` regardless of `alarm.exerciseType`/`exerciseMode`. A push-ups or Roulette alarm displays as "20 squats". **Fix:** reuse the exercise label logic already in `ArmedAlarmCard` (exercise chip incl. ROULETTE).

#### 🟠 A5. Accessibility fallback can dead-end into an un-dismissable ringing alarm
When camera permission is denied, taps count only up to `accessibilityMaxTapReps` (3). After that, with `PopScope(canPop:false)`, looping audio, and a settings deep-link as the only exit, a user who *cannot* grant camera (broken camera, managed device policy) is stuck with a ringing phone. The volume ramp keeps escalating too (A1's `rampVolumeUp` timer keeps firing while no pose is detected). This is a deliberate design tension ("no free dismissals"), but there is no last-resort escape hatch at all — not even a long-press-10-seconds "emergency stop" with a bailout penalty applied. **Recommendation:** route the existing bailout system through a hidden escape (e.g. hold 10 s → alarm stops, bailout recorded, 2× penalty applied). The punishment system already exists; using it here converts a potential 1-star-review/ANR scenario into a designed outcome.

#### 🟠 A6. Zero `Semantics` usage across the entire app
`grep Semantics|semanticLabel` over `lib/` returns **no matches** in 145 files. Combined with: icon-only `GestureDetector` buttons with no tooltips (dashboard header avatar/add-alarm, `_NavItem`s), 9 px bottom-nav labels, hardcoded `TextStyle(fontSize: …)` everywhere (most HUD text won't respond to system font scaling since styles don't opt out of or clamp `TextScaler` deliberately — they just ignore layout implications), and `Switch`es with no semantic label — TalkBack/VoiceOver users effectively can't operate the app. For an app whose *core interaction* is physical-accessibility-sensitive, this matters. See §4.3 for the concrete checklist. References: [Flutter accessibility docs](https://docs.flutter.dev/ui/accessibility), [practical a11y guide (DCM)](https://dcm.dev/blog/2025/06/30/accessibility-flutter-practical-tips-tools-code-youll-actually-use/).

#### 🟡 A7. Malformed alarm deep link crashes route building
[app_router.dart:147](lib/core/router/app_router.dart) — `_alarmFromQueryParams` calls `DateTime.parse(...)` on the `scheduled` query param. A corrupted notification payload or malicious deep link (`awaken://alarm/active?id=x&scheduled=garbage`) throws during build. Use `DateTime.tryParse(...) ?? DateTime.now()`.

#### 🟡 A8. Swipe-to-delete alarm is irreversible with no undo
[dashboard_screen.dart:1039-1056](lib/features/dashboard/presentation/screens/dashboard_screen.dart) — `Dismissible` → `removeAlarm` immediately. One accidental swipe silently destroys an alarm (and its schedule). Material guidance: show a `SnackBar` with an UNDO action (re-add + reschedule), or require `confirmDismiss` for destructive rows.

#### 🟡 A9. No localization infrastructure; hand-rolled date formatting
All strings are hardcoded English; [dashboard_screen.dart:311-336](lib/features/dashboard/presentation/screens/dashboard_screen.dart) hand-rolls weekday/month names; `_AlarmTile` hand-formats 12-hour time (ignoring the device's 24-hour setting — `MediaQuery.alwaysUse24HourFormat` / `TimeOfDay.format(context)` handle this for free). Adopt `flutter_localizations` + `intl` (`DateFormat.yMMMEd()`, `DateFormat.jm()`) even if English stays the only language — it fixes the 24-hour-clock bug immediately.

#### 🟡 A10. Avatar images use raw `Image.network` — refetched every rebuild, no disk cache
[dashboard_screen.dart:390](lib/features/dashboard/presentation/screens/dashboard_screen.dart), [profile_screen.dart:194](lib/features/auth/presentation/screens/profile_screen.dart). Add [`cached_network_image`](https://pub.dev/packages/cached_network_image) with a small `memCacheWidth` (they render at 40 px), or at minimum wrap with `Image.network(..., cacheWidth: 120)`.

#### 🟡 A11. `AlarmAudioService` start/stop race
`start()` awaits several steps against the static `_player`; if `stop()` runs concurrently (fast complete-while-starting), `_player` is nulled and disposed mid-`start`, and the outer catch masks it. Guard with a session token or make `start()` capture a local `player` instance and only publish it to `_player` at the end. Low likelihood, but this is the one service that must never be in a weird state.

#### 🟡 A12. Alarm-dismissal side effects live in `dispose()`
Audio stop + wake-lock release happen in `_ActiveAlarmScreenState.dispose()` ([active_alarm_screen.dart:133-143](lib/features/alarm/presentation/screens/active_alarm_screen.dart)). It works with the current `go()` replacement navigation, but any future change that keeps the route mounted (dialog overlay, nested navigation) silently keeps the alarm audio alive. Prefer an explicit `_completeAlarmSession()` called on the success transition, with `dispose()` as a safety net only.

#### 🟡 A13. Minor territory-screen nits
- [territory_run_screen.dart:1147](lib/features/territory/presentation/screens/territory_run_screen.dart) hardcodes `3.14159265` — use `math.pi`.
- The heading-wedge doc comment says heading `0` hides the wedge, but the code (`heading! >= 0`) *shows* it pointing north; geolocator reports `0.0` both for "due north" and frequently for "unknown". Consider hiding when `heading <= 0 && speed < ~0.5 m/s`.
- Map rotation is enabled (`InteractiveFlag.all`) but there's no compass/reset-north control — a rotated map is disorienting mid-run and there's no way back. Either add a reset-rotation button or exclude rotation: `InteractiveFlag.all & ~InteractiveFlag.rotate`.

#### 🟡 A14. Project docs drift
`CLAUDE.md` still says "Tab switches away from an active run prompt discard confirmation via `_ShellScaffold`" — the current code intentionally keeps GPS alive across tab switches with no prompt (the live-dot on the Territory tab replaced it). Update CLAUDE.md so future sessions don't "fix" the wrong behavior.

### 1.2 Carried-forward open items (re-verified, still true)

| # | Item | Severity |
|---|---|---|
| B1 | `sessions` reps/calories and `streaks` writes are client-trusted (RLS ownership only, no plausibility validation) — any signed-in user can forge workout stats; territory is server-validated but fitness stats are not | 🟠 |
| B2 | Fixed squat-depth threshold (0.6) with no adaptive/partial-credit path — friction for the half-asleep target moment (design choice, revisit with real-user data) | 🟡 |
| B3 | `polybool` declared in pubspec but never imported in `lib/` — remove | 🟡 |
| B4 | Decay warnings are once-per-session; a long-resident app can miss them (design choice) | 🔵 |
| B5 | Supabase anon key + Google client IDs + Firebase API keys committed (anon/Firebase keys are designed to be public + RLS/rules-guarded; needs explicit sign-off, plus Firebase API-key HTTP-referrer/app restrictions in Google Cloud console) | 🔵 |

### 1.3 Database — live `get_advisors` results (2026-07-14)

#### Security
| # | Finding | Level | Action |
|---|---|---|---|
| D1 | `public.spatial_ref_sys` RLS disabled (PostGIS-owned SRID reference table, 8,500 public rows, no user data) | ERROR | Don't blindly `ENABLE ROW LEVEL SECURITY` (can break `ST_Transform`). Preferred: `REVOKE INSERT, UPDATE, DELETE ON public.spatial_ref_sys FROM anon, authenticated;` and acknowledge the read exposure. [Lint 0013](https://supabase.com/docs/guides/database/database-linter?lint=0013_rls_disabled_in_public) |
| D2 | `trg_notify_turf_hit_push()` — a `SECURITY DEFINER` **trigger function** that fires FCM pushes — is executable by `anon` and `authenticated` via `/rest/v1/rpc/` | WARN (worst of the set) | `REVOKE EXECUTE ON FUNCTION public.trg_notify_turf_hit_push() FROM PUBLIC, anon, authenticated;` — it only ever needs to run as the trigger owner. [Lint 0028](https://supabase.com/docs/guides/database/database-linter?lint=0028_anon_security_definer_function_executable) |
| D3 | `allocate_territory_color()` and `is_squad_member(uuid)` (both `SECURITY DEFINER`) executable by `anon` | WARN | `REVOKE EXECUTE ... FROM anon;` keep `authenticated` (the app calls both client-side) |
| D4 | **New this pass:** PostGIS's `st_estimatedextent` (3 overloads, `SECURITY DEFINER`, C language) executable by `anon`/`authenticated` | WARN | Extension-owned; revoke `EXECUTE` from `anon` and `authenticated` for all three signatures — nothing in the app calls it via PostgREST |
| D5 | `hsl_to_hex`, `profiles_lock_territory_color` have mutable `search_path` | WARN | Add `SET search_path = public, pg_temp` to each definition. [Lint 0011](https://supabase.com/docs/guides/database/database-linter?lint=0011_function_search_path_mutable) |
| D6 | Leaked-password protection disabled in Auth | WARN | One toggle: Auth → Providers → Email → enable HaveIBeenPwned check. [Docs](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection) |
| D7 | `postgis` extension in `public` schema | WARN | Acknowledge; migration is invasive and not worth it on a live project. [Lint 0014](https://supabase.com/docs/guides/database/database-linter?lint=0014_extension_in_public) |

D2–D4 share one root cause: Postgres grants `EXECUTE` to `PUBLIC` on new functions by default, and the old `revoke_anon_rpc_grants` migration predates these functions. **Recommended systemic fix** in the same migration:
```sql
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
```
so future `SECURITY DEFINER` functions ship locked-down and get explicit grants only.

#### Performance
| # | Finding | Action |
|---|---|---|
| P1 | 12 RLS policies across 9 tables re-evaluate `auth.uid()` per row (`alarm_triggers`, `push_tokens`, `turf_hit_notifications` ×2, `territory_steals`, `squads`, `squad_members` ×2, `squad_alarms`, `explored_cells`, `squad_bailouts`, `bounty_claims`) | Mechanical, one migration: wrap as `(select auth.uid())` in each `USING`/`WITH CHECK`. Invisible at today's row counts; do it before growth. [Docs](https://supabase.com/docs/guides/database/postgres/row-level-security#call-functions-with-select) |
| P2 | `squad_alarms` has two overlapping permissive `SELECT` policies (`squad_alarms_select`, `squad_alarms_upsert`) | Consolidate into one; scope the upsert policy to `INSERT`/`UPDATE` only. [Lint 0006](https://supabase.com/docs/guides/database/database-linter?lint=0006_multiple_permissive_policies) |
| P3 | 10 FKs without covering indexes (squad/social tables + `alarm_triggers.alarm_id`, `territory_steals.victim_id`, `turf_hit_notifications.attacker_user_id`, `bounty_claims.bounty_id`) | Add when squad/social usage grows; they back join-heavy queries (rosters, bailout history, nudge inboxes) |
| P4 | 9 unused indexes flagged | Expected on a young project — keep, re-check after real traffic |

### 1.4 Packages (`flutter pub outdated`, 2026-07-14)

**One discontinued dependency** and 13 major-version-behind direct dependencies:

| Package | Current | Latest | Notes |
|---|---|---|---|
| `flutter_map_cancellable_tile_provider` | 3.0.2 | 3.1.1 **(discontinued)** | flutter_map v8 built request-aborting into the core `NetworkTileProvider` — the plugin is obsolete. Bundled with the flutter_map upgrade. [What's new in v8](https://docs.fleaflet.dev/getting-started/new-in-v8) |
| `flutter_map` | 7.0.2 | 8.3.1 | v8: built-in cancellation + built-in caching (removes two workarounds this repo carries) |
| `flutter_local_notifications` | 17.2.4 | 22.0.1 | 5 majors behind — the riskiest gap given the alarm engine sits on it; changelogs include Android 15/16 behavior fixes |
| `go_router` | 13.2.5 | 17.3.0 | 4 majors; 17.3 needs Flutter ≥3.38 ([changelog](https://pub.dev/packages/go_router/changelog)) |
| `flutter_riverpod` / `riverpod_annotation` / `riverpod_generator` / `riverpod_lint` | 2.x | 3.x / 4.x | Riverpod 3: `StateProvider`/`StateNotifierProvider` become `legacy` imports; `==` update filtering; auto-retry on provider failure. This repo uses many `StateProvider`s. [Migration guide](https://riverpod.dev/docs/3.0_migration) |
| `google_sign_in` | 6.3.0 | 7.2.0 | **Breaking rewrite** — singleton `GoogleSignIn.instance`, `authenticate()` replaces `signIn()`, and **no `accessToken`** anymore, which changes the `signInWithIdToken` call into Supabase. [Supabase docs updated for v7](https://supabase.com/docs/guides/auth/social-login/auth-google), [migration guide](https://isaacadariku.medium.com/google-sign-in-flutter-migration-guide-pre-7-0-versions-to-v7-version-cdc9efd7f182) |
| `geolocator` | 13.0.4 | 14.0.3 | Check Android FGS type declarations on upgrade |
| `permission_handler` | 11.4.0 | 12.0.3 | Straightforward |
| `just_audio` | 0.9.46 | 0.10.6 | Do together with the A1 audio-session work |
| `timezone` / `flutter_timezone` | 0.9.4 / 5.1 | 0.11.1 | Pairs with flutter_local_notifications bump |
| `google_fonts` | 6.3.3 | 8.1.0 | Check whether Geist landed on Google Fonts while at it (the swap point is documented in `app_typography.dart`) |
| `vector_tile_renderer` | 5.2.1 | 6.1.0 | Coordinate with `vector_map_tiles` compatibility |
| `latlong2` | 0.9.1 | 0.10.1 | Held back by flutter_map 7 — resolves with the v8 upgrade |
| `custom_lint` / `build_runner` | 0.7.6 / 2.5.4 | 0.8.1 / 2.15.2 | Dev-only |

**`google_mlkit_pose_detection` 0.15.0 is the latest** — no upgrade available, but note the underlying native SDK remains **beta with no SLA or deprecation policy** per [Google's docs](https://developers.google.com/ml-kit/vision/pose-detection). The pubspec comment guarding against blind `pub upgrade` sweeps is correct — keep it. Long-term hedge: Google's actively-developed successor is [MediaPipe Pose Landmarker](https://ai.google.dev/edge/mediapipe/solutions/vision/pose_landmarker) (same 33-landmark BlazePose topology, so `ExerciseCounter` logic ports over; the abstraction boundary you already have at `ExerciseCounter`/`AlarmPosePipeline` is exactly the right seam).

**Recommended upgrade order** (each step compiles + tests green before the next):
1. Patch-level catch-ups (`camera`, `firebase_*`) — zero risk.
2. `flutter_map` 8 + drop `flutter_map_cancellable_tile_provider` + `vector_map_tiles`/`vector_tile_renderer`/`latlong2` alignment. Delete the custom cancellation shims if v8's built-ins cover them (`expected_async_cancellation.dart` may shrink).
3. `flutter_local_notifications` 22 + `timezone` 0.11 — re-test the full alarm fire path on a real device (full-screen intent, exact scheduling, payload).
4. `permission_handler` 12, `geolocator` 14, `just_audio` 0.10 (+ A1 audio-session fix).
5. `google_sign_in` 7 — follow the updated [Supabase native-auth doc](https://supabase.com/docs/reference/dart/auth-signinwithidtoken); rewrite `google_auth_service.dart` for `initialize()`/`authenticate()`/`idToken`-only flow.
6. `go_router` 17 (needs newest Flutter SDK).
7. Riverpod 3 last — largest surface (legacy `StateProvider` imports throughout `active_run_providers.dart`, `territory_providers.dart`, etc.). Consider migrating hand-written `StateProvider`s to `Notifier`s incrementally *before* the version bump to shrink the diff.

---

## 2. UI/UX Review

### 2.1 What's working (keep this)
The design system is unusually disciplined for a project at this stage: a single token file (OKLCH-mapped `AppColors`, raw hex genuinely absent from widgets), one typography source with tabular figures on every ticking numeral, consistent 24/16/12 radii, hairline borders, eyebrow labels, and a coherent "neon HUD on pure black" identity across all 11 screens. Perf hygiene is also real: `RepaintBoundary` around every animated painter, `select()`-scoped Riverpod watches isolating the per-second run timer from the map, once-per-minute clock stream, decimated trails, culled polygon glow. Don't redesign the language — refine within it.

### 2.2 Screen-by-screen findings

**Dashboard** ([dashboard_screen.dart](lib/features/dashboard/presentation/screens/dashboard_screen.dart))
- 🟠 Banner stack risk: exact-alarm warning + bailout banner + squad nudge + guest sync prompt can all be visible simultaneously — four stacked alerts above the hero card push the actual alarm below the fold. Prioritize: show at most one "system" banner (exact-alarm wins) and collapse the rest into a badge/inbox.
- 🟠 `_AlarmTile` "N squats" bug (A4) and 12-hour-only time format (A9).
- 🟡 "Good morning" greeting is static — it's wrong 16 hours a day. Derive from `DateTime.now().hour` (morning/afternoon/evening); trivial, and this app is *about* time of day.
- 🟡 The `_MoreToggle` label "TERRITORY, RIVALS & MORE" collapses a whole product surface behind an eyebrow-sized tap target; consider promoting territory status (owned m², decay risk) into a compact always-visible strip since it's the app's second pillar.
- 🟡 Debug `_TestAlarmButton` is `kDebugMode`-gated (good) but occupies layout space in every debug session at the scroll bottom — fine, just noting it's intentional.

**Alarm setup** ([alarm_setup_screen.dart](lib/features/alarm/presentation/screens/alarm_setup_screen.dart))
- Good: staggered `flutter_animate` reveals, tier chips give the rep slider personality, permission flows at arm time (not wake time) is the right call.
- 🟡 `_time = TimeOfDay.now()` defaults the picker to *now* — for an alarm app the median intent is "tomorrow morning". Default to the user's last alarm time, or 07:00.
- 🟡 No feedback about *when* the alarm will fire ("Rings in 9h 32m") — a one-line label under the time tile removes the classic AM/PM mistake. This is a standard pattern in every major alarm clock app.

**Active alarm HUD** ([active_alarm_screen.dart](lib/features/alarm/presentation/screens/active_alarm_screen.dart), [camera_hud_overlay.dart](lib/features/alarm/presentation/widgets/camera_hud_overlay.dart))
- Good: the state-driven instruction bar with per-exercise cues, calibration haptics, shockwave rep counter, tax-reveal stamp — the theatrical framing is distinctive and consistent.
- 🔴 Skeleton misalignment (A2) is the single most trust-damaging visual bug in the app.
- 🟠 Camera-failure vs permission-denied copy (A3).
- 🟡 The L/R knee telemetry labels position at `height * 0.45` — on small screens they collide with the centered rep counter. Anchor them to the border edges instead.
- 🟡 During calibration there's no progress indication (8 frames ≈ 0.5 s, but with poor lighting it can take many seconds of "STAND TALL" with no sense of progress). Show a thin progress arc (frames-held / required) so the user knows holding still is working.

**Success screen** ([success_screen.dart](lib/features/success/presentation/screens/success_screen.dart))
- Good: streak delta, staggered count-ups, accessibility-mode disclosure.
- 🟡 The whole screen blocks on `_isSaving` (spinner replaces the streak badge until session + stats round-trip completes). The save is local-first — show the badge optimistically and reconcile.

**Territory run** ([territory_run_screen.dart](lib/features/territory/presentation/screens/territory_run_screen.dart))
- Good: the status-driven header (7 states), GPS-quality chip, grace-pause dim, loop-closure pulse, guest offline nudge with sign-in action — a lot of hard-won GPS UX correctness here.
- 🟡 No rotation-reset control despite rotation being enabled (A13).
- 🟡 The bottom stack (`RunControls` at 12, safety strip at 72, stats HUD at 110, bounty legend at 76) is tuned by absolute offsets; on small phones with large system nav insets these can collide. Consider a `Column` in a single bottom `SafeArea` rather than sibling `Positioned`s.
- 🟡 "GRACE" full-screen label is powerful but unexplained the first time — a one-time tooltip ("Auto-paused — you stopped moving. Resumes on movement") would prevent "the app froze" interpretations. The paused-banner text ("PAUSED · TRAFFIC GRACE") helps but appears in a different corner than the giant word.

**Leaderboard** ([territory_leaderboard_screen.dart](lib/features/territory/presentation/screens/territory_leaderboard_screen.dart))
- Good: scope/window filters with metric explainer badge, podium/solo states, ±5 neighborhood, climb hint, map-focus on tap.
- 🟡 Location acquisition for "nearby" happens silently in `initState`; if permission was denied, the fallback is invisible — surface a small "showing global — enable location for nearby" chip so mode degradation is legible.

**Auth / Profile / Onboarding** — solid; consistent with the system. Profile's responsive 2×2/1×4 grid and sync-status pill are nice touches. Onboarding's three pages are clear; consider adding the *camera* permission rationale there (it currently arrives at alarm-arm time, which is fine, but priming improves grant rates).

**Bottom nav** ([app_router.dart:240-378](lib/core/router/app_router.dart))
- 🟡 9 px labels are below any legibility guidance; icons are 22 px in a 60 px bar — comfortable, but the labels are decorative at that size. Bump to 10-11 px and let the tracked caps do the styling work.
- 🟡 `GestureDetector`-based items expose no button semantics, no `tooltip` (A6).

### 2.3 Accessibility checklist (concrete, ordered)
1. Add `Semantics(button: true, label: ...)` or replace `GestureDetector` with `InkWell`+`Tooltip` for: nav items, header avatar, add-alarm button, run-screen circle buttons (some already have tooltips — make it all of them), alarm-tile `Switch` (`Semantics(label: 'Alarm ${time} active')`).
2. `MergeSemantics` around stat cards (label + value + unit read as one).
3. Announce rep counts: `SemanticsService.announce('$next of $required')` in `_onRepCompleted` — a blind user *can* do squats; today the HUD is the only feedback channel besides haptics.
4. Verify text scaling to 1.3× (Android font size "Largest") on: dashboard cards (`IntrinsicHeight` rows), alarm HUD, run stats sheet. Clamp where layout genuinely can't flex: `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: hudSubtree)` rather than ignoring the setting.
5. Run `flutter test` with [`meetsGuideline(androidTapTargetGuideline)`](https://docs.flutter.dev/ui/accessibility#testing-accessibility) matchers on the main screens.
6. Contrast: `mutedForeground` `#9E9E9E` on `card` `#282828` ≈ 4.6:1 — passes AA for body text but several 10 px labels use it with reduced alpha (e.g. `withValues(alpha: 0.8)`), dropping below 4.5:1. Audit the alpha-modified label styles.

### 2.4 Redesign recommendations (within the existing language)
- **Adopt Material 3 Expressive selectively.** Flutter's current M3 wave (dynamic color, expanded tonal tokens, new component shapes — [Material 3 for Flutter](https://m3.material.io/develop/flutter), [M3 migration notes](https://docs.flutter.dev/release/breaking-changes/material-3-migration)) mostly *shouldn't* replace the bespoke HUD identity — but the springy motion system and shape-morphing buttons fit the brand. Targets: `RunControls` start/stop morph, tier-chip selection, HUD-theme picker.
- **Pure-black is right for OLED; add one elevation step.** Everything sits on `#000000` with `#282828` cards — consider an intermediate `#141414` surface for grouped sections (THIS WEEK block, alarm list) so scroll depth reads without borders doing all the work.
- **Motion-reduce path.** Scan-line sweep, radar pulse, shockwave rings, typewriter quote — all ignore `MediaQuery.disableAnimations`/`accessibleNavigation`. Gate the purely decorative ones.
- **Design-token debt:** `_MyLocationMarker`'s `#4285F4` blue and success screen's inline styles are the only stragglers outside `AppColors`/typography — fold them in (the blue is intentional Google-style; still tokenize it as `AppColors.locationDot`).
- **Empty states:** leaderboard and overview have them; the dashboard trend card simply vanishes for new users (`repsTrend.any((v) => v > 0)`) — an inline "your first week starts tomorrow morning" placeholder converts dead space into onboarding.

---

## 3. ML Kit Pose Detection Review

### 3.1 Verdict
The pipeline ([alarm_pose_pipeline.dart](lib/features/alarm/presentation/services/alarm_pose_pipeline.dart)) is **substantially aligned with Google's official guidance** ([Detect poses on Android](https://developers.google.com/ml-kit/vision/pose-detection/android)): `PoseDetectionMode.stream` + the base model for live video, explicit model pinning with a rationale comment, a re-entrancy guard + 66 ms throttle so frames never queue behind inference, NV21 preferred with a stride-aware 3-plane YUV_420_888 fallback, correct front/back rotation compensation from device orientation, frame-capture timestamps (not processing-completion) threaded into the counters, per-frame failure tolerance, and full lifecycle teardown/reopen on background. The exercise counters are equally sound: EMA smoothing (α=0.35), per-session standing calibration normalizing thresholds to the user's body/camera distance, likelihood-gated landmarks (≥0.45–0.5), hysteresis in every FSM (100°/150° squat, 90°/150° push-up, 15%/60% high-knees plant), and deterministic time-based (not frame-based) bad-form windows.

### 3.2 Issues & improvements
1. 🔴 **Overlay alignment (A2)** — detection is correct; the *rendering* of it is not. Fix per §1.1 A2.
2. 🟠 **Resolution vs. Google's recommendation.** `ResolutionPreset.medium` yields ~720×480 on Android. Google recommends capturing at ~**1280×720** and, critically, that the subject occupy ≥**256×256 px**. A full body framed head-to-ankles in a 480-tall portrait crop leaves each thigh segment only tens of pixels — this is a plausible contributor to any knee-angle jitter you see at distance. Test `ResolutionPreset.high` (720p) on mid-range hardware; the 15 FPS throttle + `_isDetecting` guard already protects you if inference slows.
3. 🟡 **Z coordinate is unused.** ML Kit provides `z` (depth relative to hip midpoint). For squats it could disambiguate "leaning toward camera" from "squatting" (both shrink the projected hip-knee gap). Not required — the depth-ratio + shoulder-tilt combo covers most cases — but it's free signal for a future form-quality pass.
4. 🟡 **`likelihood` here is presence, not accuracy** — ML Kit's docs note `InFrameLikelihood` reflects being inside the frame, not landmark precision. The 0.5 gate is fine for gating, just don't build "confidence-weighted angles" on it later.
5. 🟡 **Adaptive throttle.** The fixed 66 ms budget assumes inference ≤ ~60 ms. On low-end devices the `_isDetecting` guard silently halves the effective rate (fine), but you could measure rolling inference time and surface a "low frame rate — improve lighting" cue when the effective FPS drops below ~8, since counter hysteresis begins to miss fast reps around there.
6. 🟡 **Single-pose assumption.** `poses.first` — correct (ML Kit detects one person), but if a second person walks behind the user the detector can jump targets between frames. The calibration baselines make jumps *look* like bad form rather than counting for the wrong person — acceptable — but a cheap sanity check (torso center displacement > X% in one frame → skip frame) would suppress the spurious red flashes.
7. 🔵 **Strategic:** keep the `ExerciseCounter`/pipeline seam clean for an eventual [MediaPipe Pose Landmarker](https://ai.google.dev/edge/mediapipe/solutions/vision/pose_landmarker) migration (same 33-landmark topology; adds a segmentation mask and an official maintained roadmap, vs. ML Kit's perpetual beta).

---

## 4. Prioritized Action Plan

**Sprint 1 — correctness & trust (small diffs, big user impact)**
1. A1 alarm audio → alarm stream (+ iOS `.playback` category).
2. A2 overlay cover-fit transform (+ `shouldRepaint` fields).
3. A4 alarm-tile exercise label; A7 `DateTime.tryParse`; A13 `math.pi`.
4. D2–D4 one migration: revoke anon/authenticated EXECUTE (incl. `st_estimatedextent` ×3) + `ALTER DEFAULT PRIVILEGES`; D5 `search_path` pins; D6 auth toggle; D1 revoke writes on `spatial_ref_sys`.

**Sprint 2 — UX & a11y**
5. A3 camera-failure state + retry; calibration progress arc.
6. A5 emergency-escape → bailout path (product decision required first).
7. A6/§2.3 semantics pass + rep announcements + text-scale audit.
8. A8 undo snackbar; A9 intl + 24h time; dashboard banner prioritization; greeting by hour; "rings in Xh" label.

**Sprint 3 — platform & debt**
9. Package upgrade ladder (§1.4 order), flutter_map 8 first (removes a discontinued dep), Riverpod 3 last.
10. P1/P2 RLS-initplan + policy-consolidation migration.
11. B3 drop `polybool`; A10 avatar caching; A14 CLAUDE.md refresh.
12. Evaluate `ResolutionPreset.high` for the pose camera on target hardware (§3.2.2).

---

## Sources

- [ML Kit Pose Detection — Android guide](https://developers.google.com/ml-kit/vision/pose-detection/android) · [Pose detection overview (beta status)](https://developers.google.com/ml-kit/vision/pose-detection) · [MediaPipe Pose Landmarker](https://ai.google.dev/edge/mediapipe/solutions/vision/pose_landmarker) · [google_mlkit_pose_detection on pub.dev](https://pub.dev/packages/google_mlkit_pose_detection)
- [flutter_map — What's new in v8](https://docs.fleaflet.dev/getting-started/new-in-v8) · [flutter_map changelog](https://pub.dev/packages/flutter_map/changelog) · [flutter_map_cancellable_tile_provider (discontinued)](https://github.com/fleaflet/flutter_map_cancellable_tile_provider)
- [Riverpod 3.0 migration guide](https://riverpod.dev/docs/3.0_migration) · [What's new in Riverpod 3.0](https://riverpod.dev/docs/whats_new)
- [google_sign_in v7 migration guide](https://isaacadariku.medium.com/google-sign-in-flutter-migration-guide-pre-7-0-versions-to-v7-version-cdc9efd7f182) · [Supabase — Login with Google (updated for v7)](https://supabase.com/docs/guides/auth/social-login/auth-google) · [Supabase signInWithIdToken](https://supabase.com/docs/reference/dart/auth-signinwithidtoken) · [supabase/supabase#36775](https://github.com/supabase/supabase/issues/36775)
- [go_router changelog](https://pub.dev/packages/go_router/changelog)
- [Android — full-screen intent limits](https://source.android.com/docs/core/permissions/fsi-limits) · [Play Console FSI declaration requirements](https://support.google.com/googleplay/android-developer/answer/13392821?hl=en) · [FSI in Android 14/15 — what changed (droidcon)](https://www.droidcon.com/2025/09/02/%F0%9F%9A%A8-full-screen-intent-fsi-notifications-in-android-14-15-what-changed-why-its-breaking-and-how-to-fix-it/) · [Android 14 behavior changes](https://developer.android.com/about/versions/14/behavior-changes-14)
- [Android audio output handling (audio streams)](https://developer.android.com/media/platform/output) · [AudioManager reference](https://developer.android.com/reference/android/media/AudioManager)
- [Flutter accessibility docs](https://docs.flutter.dev/ui/accessibility) · [Practical accessibility in Flutter (DCM)](https://dcm.dev/blog/2025/06/30/accessibility-flutter-practical-tips-tools-code-youll-actually-use/) · [Mastering Semantics deep dive](https://somniosoftware.com/blog/mastering-accessibility-in-flutter-a-deep-dive-into-semantics)
- [Material 3 for Flutter](https://m3.material.io/develop/flutter) · [Flutter M3 migration](https://docs.flutter.dev/release/breaking-changes/material-3-migration) · [Material 3 — get started](https://m3.material.io/get-started)
- [Supabase database linter docs](https://supabase.com/docs/guides/database/database-linter) · [RLS performance — call functions with select](https://supabase.com/docs/guides/database/postgres/row-level-security#call-functions-with-select) · [Leaked-password protection](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection)
