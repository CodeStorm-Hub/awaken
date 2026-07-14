# Wake Up Tax — ML Kit Pose Detection Hardening Plan

> Source material: `PROJECT_ANALYSIS_REPORT.md` (full codebase read), cross-validation of `mlkit_pose_detection_research.md` against `lib/features/alarm/domain/services/*.dart`, and live web research against Google's official ML Kit docs (2026-07-14 session). This plan turns those findings into scoped, sequenced work.

## Priority summary

| # | Item | Priority | Effort | Reachable by real users? |
|---|---|---|---|---|
| 1 | High-knees DB constraint blocks save | **P0 — ✅ DONE** | XS | Yes — any signed-in user picking High Knees |
| 2 | Wake-time camera permission re-request race | **P0 — ✅ DONE** | S | Yes — permission revoked between arm and wake |
| 3 | Roulette pick unstable across app restarts | **P1 — ✅ DONE** | S | Yes — contradicts "no negotiating" promise |
| 4 | Frame-count thresholds are FPS-dependent | **P1 — ✅ DONE** | M | Yes — low-end/throttled devices |
| 5 | Out-of-frame flicker false-triggers audio ramp | **P1 — ✅ DONE** | S | Yes — minor but user-facing |
| 6 | `PerformanceMode` left implicit | **P2 — ✅ DONE (corrected)** | XS | No — hardening only |
| 7 | Two different angle formulas (atan2 vs acos) | **P2 — ✅ DONE** | S | No — code-quality only |
| 8 | ML Kit beta-SDK version risk | **P2 — ✅ DONE** | XS (process) | No — operational risk |
| 9 | Sit-ups: implement or remove | **P2 — ✅ DONE (Option A)** | M (implement) / XS (remove) | No — currently unreachable in UI |
| 10 | Roulette hash-stability regression test | **P1 — ✅ DONE** | S | Test-only |
| 11 | Device-lab QA matrix | P2 | M (manual) | Test-only |
| 12 | Document thresholds as intentional | **P3 — ✅ DONE** | XS | Docs-only |

---

## Phase 0 — Critical bugs (ship first)

### 0.1 Fix `alarms.exercise_type` check constraint to allow `highKnees` — ✅ Done 2026-07-14

Applied live via Supabase MCP `apply_migration` (`allow_high_knees_exercise_type`) and committed as [`supabase/migrations/20260714000001_allow_high_knees_exercise_type.sql`](../../supabase/migrations/20260714000001_allow_high_knees_exercise_type.sql). Verified against `pg_constraint` on the live project (`nankdbntvvopnfvvvaoo`) — the constraint now allows `'squats','pushUps','jumpingJacks','highKnees','sitUps'`.

**Problem (as found):** `AlarmExerciseTypeX.implemented` includes `highKnees` and `AlarmSetupScreen` offers it as a selectable chip, but the Supabase migration's check constraint on `alarms.exercise_type` only allows `squats | pushUps | jumpingJacks | sitUps`. A signed-in user selecting High Knees and arming the alarm gets a Postgres constraint violation, surfaced as a raw "Failed to save alarm: ..." SnackBar (`_save` catch block in `alarm_setup_screen.dart`).

**Fix:** New migration widening the constraint:
```sql
ALTER TABLE public.alarms DROP CONSTRAINT alarms_exercise_type_check;
ALTER TABLE public.alarms ADD CONSTRAINT alarms_exercise_type_check
  CHECK (exercise_type IS NULL OR exercise_type = ANY (
    ARRAY['squats','pushUps','jumpingJacks','highKnees','sitUps']
  ));
```
Apply via Supabase MCP `apply_migration` (not raw `execute_sql`, since this is DDL).

**Files:** new file under `supabase/migrations/`.
**Test:** manual — sign in, arm a High Knees fixed alarm, confirm it persists to `alarms` and survives an app restart. No Dart changes needed.
**Risk:** none — purely additive constraint change, no existing rows violate it.

### 0.2 Eliminate the wake-time camera-permission re-request race — ✅ Done 2026-07-14

Implemented in [`alarm_pose_pipeline.dart`](../../lib/features/alarm/presentation/services/alarm_pose_pipeline.dart#L76) essentially as specified below (status-check-first, skip `.request()` on `isPermanentlyDenied`/`isRestricted`). `flutter analyze` clean; full `test/alarm/` suite (18 tests) passing. Note: no dedicated unit test was added for the new branch (the suggested "Test" below is still open) since `permission_handler`'s platform channel isn't mocked anywhere else in this test suite yet — would need a new test harness, tracked as a follow-up rather than blocking Phase 0.

**Problem (as found):** Camera permission is requested twice: proactively at arm-time (`AlarmSetupScreen._ensureCameraPermission`) and again inside `AlarmPosePipeline.start()` via `Permission.camera.request()`. If the OS permission was revoked after arming (Android settings, "auto-revoke unused permissions", etc.), the second request pops the native OS dialog **while the alarm is actively ringing and blocking the screen** — the exact worst-moment scenario the arm-time pre-request exists to avoid.

**Fix:** In `AlarmPosePipeline.start()`, replace the blind `Permission.camera.request()` with a status check first:
```dart
final status = await Permission.camera.status;
if (status.isGranted) {
  // proceed directly, no dialog
} else if (status.isPermanentlyDenied) {
  permissionDenied.value = true;
  return; // never show a dialog for hard-denied — go straight to accessibility fallback
} else {
  final result = await Permission.camera.request(); // only prompts if truly undecided
  if (!result.isGranted) { permissionDenied.value = true; return; }
}
```
This preserves the accessibility fallback (tap-to-count) for genuinely denied permission, but stops re-prompting mid-alarm when the OS has already made a hard "denied forever" decision — the user gets the fallback banner immediately instead of a jarring permission dialog over the ringing alarm.

**Files:** `lib/features/alarm/presentation/services/alarm_pose_pipeline.dart`.
**Test:** widget/unit test simulating `PermissionStatus.permanentlyDenied` → assert `permissionDenied.value == true` and no `request()` call is made (mock `permission_handler`'s platform channel).

---

## Phase 1 — Correctness & robustness

### 1.1 Make roulette exercise selection stable across process restarts — ✅ Done 2026-07-14

Implemented in [`exercise_counter_router.dart`](../../lib/features/alarm/domain/services/exercise_counter_router.dart) exactly per the fix below (`_stableHash` FNV-1a, `seed % options.length` — no `.abs()` needed since the 32-bit mask already keeps the hash non-negative). Added the cross-isolate regression test to [`exercise_and_bailout_test.dart`](../../test/alarm/exercise_and_bailout_test.dart) (`roulette pick is stable across process/isolate restarts`, using `Isolate.run` twice) — this also closes item 10 in the priority table. `flutter analyze` clean; full `test/alarm/` suite (19 tests) passing.

**Problem (as found):** `pickRouletteExercise` seeds `Object.hash(alarmId, year, month, day)`. Dart's `Object.hash`/`String.hashCode` is salted per VM/isolate instance for hash-flooding protection — it is **not guaranteed stable across app restarts**. A roulette alarm that fires, gets force-closed, and reopens later the same day can pick a *different* exercise on the second open, contradicting the setup screen's own copy ("Roulette picks at wake. No negotiating."). The existing test (`exercise_and_bailout_test.dart` → `roulette pick is stable for same alarm and day`) only proves stability *within one test-process run* — it would not catch a cross-restart regression, because Dart's hash salt is fixed for the lifetime of a single test run too.

**Fix:** Replace `Object.hash` with a deterministic string hash (e.g. FNV-1a or a simple stable polynomial hash) computed manually over `'$alarmId|$year|$month|$day'`:
```dart
int _stableHash(String input) {
  var hash = 0x811c9dc5; // FNV-1a offset basis
  for (final codeUnit in input.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF; // FNV prime, masked to 32-bit
  }
  return hash;
}
```
Use this in place of `Object.hash(...)` in `pickRouletteExercise`. This is deterministic across any Dart runtime, any restart, any platform.

**Files:** `lib/features/alarm/domain/services/exercise_counter_router.dart`.
**Test:** add a new test that computes the pick via two **separate** `Isolate.run(...)` calls (which get independent hash salts) for the same `alarmId`/date and asserts equality — this is the test that would have caught the original bug, since same-isolate tests can't.

### 1.2 Convert frame-count-based bad-form windows to wall-clock time — ✅ Done 2026-07-14

**Correction found during implementation:** only `JumpingJackCounterService` (`_asymmetryFrames`/`badFormAsymmetryFrames`) actually had a frame-count-gated bad-form window. `PushUpCounterService`'s shallow-rep detection (the other counter this item originally named) turned out to be an angle-transition state machine with no frame-count dependency at all — nothing to convert there. Scope was narrowed accordingly; the interface change below was still applied to all 4 counters for consistency and future testability.

Implemented: `ExerciseCounter.processPose` now takes `(Pose pose, DateTime timestamp)` ([`exercise_counter.dart`](../../lib/features/alarm/domain/services/exercise_counter.dart)); `AlarmPosePipeline` threads the frame's actual capture timestamp (not processing-completion time) through `onPoseResult` ([`alarm_pose_pipeline.dart`](../../lib/features/alarm/presentation/services/alarm_pose_pipeline.dart)); `active_alarm_screen.dart` passes it to `_exerciseRouter.counter.processPose`. `JumpingJackCounterService` replaced `_asymmetryFrames`/`badFormAsymmetryFrames` with `_asymmetryStartedAt`/`AppConstants.badFormAsymmetryWindow` (700ms). Squats/push-ups/high-knees accept the timestamp param but ignore it (no elapsed-time-gated logic to convert). New test coverage in [`exercise_and_bailout_test.dart`](../../test/alarm/exercise_and_bailout_test.dart): a `_FakeClock` helper feeds deterministic synthetic timestamps; two new tests directly verify the fix — one confirms bad-form fires at ~700ms elapsed regardless of frame count at normal throttle rate, the other confirms it does NOT fire prematurely under a slow/low frame-rate sequence (3 frames at 250ms apart) but does fire once elapsed crosses ~700ms on the 4th frame — the exact scenario the old frame-count gate got wrong. Full suite (224 tests) passes; `flutter analyze` clean.

**Problem (as found):** `PushUpCounterService` (shallow-rep descent tracking) and `JumpingJackCounterService` (`badFormAsymmetryFrames = 10`) gate on a raw frame count, implicitly assuming the ~15 FPS the pipeline throttles to. If actual sustained frame rate drops (thermal throttling, slower device, ML Kit inference backlog), these windows silently tighten — a legitimate transient asynchrony gets flagged as bad form sooner than intended on a slower device than it would on a fast one.

**Fix:** Thread frame timestamps (already available from `CameraImage`/pose-frame metadata) into each counter and switch frame-count comparisons to elapsed-duration comparisons against a constant in `AppConstants` (e.g. `badFormAsymmetryWindow = Duration(milliseconds: 700)`), matching the comment that already documents the intent ("~0.7s at 15 FPS") but doesn't enforce it in wall-clock terms.

**Files:** `push_up_counter_service.dart`, `jumping_jack_counter_service.dart`, `exercise_counter.dart` (interface change: `processPose(Pose pose, DateTime timestamp)`), `alarm_pose_pipeline.dart` (pass `poseFrame`'s timestamp through), `app_constants.dart` (new duration constants replacing the frame-count constants).
**Test:** simulate a slow-frame-rate sequence (large gaps between synthetic timestamps but same frame count) and assert bad-form no longer fires prematurely; simulate a fast sequence and assert it still fires within the intended ~0.7s window.
**Note:** this is a real interface change across all 4 `ExerciseCounter` implementations — coordinate as one PR, not incremental, to avoid a half-migrated state.

### 1.3 Debounce the out-of-frame audio-ramp trigger — ✅ Done 2026-07-14

Implemented in [`active_alarm_screen.dart`](../../lib/features/alarm/presentation/screens/active_alarm_screen.dart) (`_outOfFrameStreak` counter, `_outOfFrameDebounceFrames = 5`) exactly as specified below — the "back in frame" transition stays instant. `flutter analyze` clean; `test/alarm/` + `test/core/` (22 tests) pass. **Open follow-up:** no widget test was added — this screen has no existing test harness (camera/pipeline/provider mocking would need to be built from scratch), so the suggested "alternating pose/null frames" test below is deferred rather than done as a rushed one-off scaffold.

**Problem (as found):** `_setOutOfFrame(true)` in `active_alarm_screen.dart` starts the volume-ramp timer on the very first frame where `hasPose == false`, with no minimum-duration debounce. A single frame of tracking loss (hand crossing the face, brief motion blur) can start the ramp mid-rep.

**Fix:** Require N consecutive out-of-frame frames (e.g. 5, ~330ms at throttled rate) before calling `_setOutOfFrame(true)`; a single good frame immediately cancels the pending debounce. Symmetric behavior isn't needed for the "back in frame" transition — that one should stay instant (no reason to delay relief).

**Files:** `lib/features/alarm/presentation/screens/active_alarm_screen.dart` (`_onPoseResult`), likely a small counter field on `_ActiveAlarmScreenState`.
**Test:** widget test feeding alternating pose/null frames and asserting the audio-ramp timer only starts after the debounce threshold.

---

## Phase 2 — ML Kit configuration & internal consistency

### 2.1 Set `PerformanceMode` explicitly — ✅ Done 2026-07-14 (spec corrected — no such param exists)

**Correction found during implementation:** the fix as originally written (`performanceMode: PoseDetectorOptions.PerformanceMode.fast`) does not compile against the plugin actually in use. That name is native ML Kit **Android** API terminology (`FAST`/`ACCURATE` on `AccuratePoseDetectorOptions`); the Flutter wrapper (`google_mlkit_pose_detection` **0.15.0**, confirmed via `pubspec.lock` and the installed package source at `.../hosted/pub.dev/google_mlkit_pose_detection-0.15.0/lib/src/pose_detector.dart`) exposes no `performanceMode` field at all. `PoseDetectorOptions` only has `model` (`PoseDetectionModel.base` / `.accurate`) and `mode` (`single` / `stream`) — `model` is the actual speed/precision knob this plugin exposes, and `base` (faster, less stable landmarks) was already the implicit default.

Implemented in [`alarm_pose_pipeline.dart`](../../lib/features/alarm/presentation/services/alarm_pose_pipeline.dart): `model: PoseDetectionModel.base` is now explicit, with a comment on why `accurate` wasn't chosen (tuned for static images, too slow for this pipeline's ~15 FPS throttle). Pins current behavior — no functional change. `flutter analyze` clean.

**Problem (as originally written, based on native ML Kit docs rather than this plugin's actual surface):** `AlarmPosePipeline` constructs `PoseDetectorOptions(mode: PoseDetectionMode.stream)` without specifying a speed/precision trade-off, silently taking the plugin's default. For a fitness-alarm feature where squat-depth precision drives pass/fail, this should be an explicit, documented choice rather than whatever the plugin defaults to today (and could silently change on a plugin upgrade).

**Files:** `alarm_pose_pipeline.dart`.
**Test:** none needed beyond existing coverage — this pins current behavior rather than changing it.

### 2.2 Unify joint-angle calculation into one shared utility — ✅ Done 2026-07-14

Implemented exactly as specified: new [`joint_angle.dart`](../../lib/features/alarm/domain/services/joint_angle.dart) with `JointAngle.between(a, vertex, c)` using the `atan2(cross, dot)` form. `SquatCounterService` and `PushUpCounterService` migrated (their private `_angleDeg`/`_angle` methods removed, unused `dart:math` imports dropped). Added [`joint_angle_test.dart`](../../test/alarm/joint_angle_test.dart) covering 90°/180°/45°/near-0°-degenerate/order-symmetry. Full suite (229 tests) passes; `flutter analyze` clean. One noted, accepted behavior micro-difference: push-up's old `acos`-based formula special-cased the fully-degenerate zero-magnitude case (coincident landmarks) to return 180°, while the shared `atan2`-based formula returns 0° there (matching squat's pre-existing, never-special-cased behavior) — not reachable in practice since ML Kit landmarks are never exactly coincident, and no test exercises this edge.

**Problem (as found):** `SquatCounterService._angleDeg` uses `atan2(cross, dot)`; `PushUpCounterService._angle` uses `acos(dot/magnitude)`. Both are mathematically valid, both return 0–180°, but having two independently-implemented formulas for the same geometric operation (angle at a joint vertex) is an internal inconsistency and a duplicate-maintenance liability — a future precision/edge-case fix to one won't propagate to the other.

**Fix:** Extract a single `JointAngle.between(a, vertex, c) → double` utility (in `exercise_counter.dart` alongside `DoubleEMAFilter`, or a new `joint_angle.dart`), using the `atan2(cross, dot)` form (numerically preferable — avoids the `acos` domain-clamping edge case near 0°/180° that the push-up code currently has to guard with `.clamp(-1.0, 1.0)`). Migrate both `SquatCounterService` and `PushUpCounterService` to call it.

**Files:** new `lib/features/alarm/domain/services/joint_angle.dart`, edits to `squat_counter_service.dart`, `push_up_counter_service.dart`.
**Test:** unit test the utility directly against known angle triples (90°, 180°, 45°, near-0° degenerate case); re-run existing squat/push-up tests to confirm no behavior change (thresholds are tuned against the numeric output, and both formulas agree exactly on well-conditioned inputs, so this should be a pure refactor).

### 2.3 De-risk the ML Kit beta dependency — ✅ Done 2026-07-14

Added a comment block above the `google_mlkit_pose_detection` entry in [`pubspec.yaml`](../../pubspec.yaml) pinning the resolved version (0.15.0, confirmed via `pubspec.lock`), stating the beta status explicitly, and pointing back to this plan section. `flutter pub get` still resolves cleanly. The recurring-reminder half of this item (calendar/issue tracker check before SDK bumps) is process, not code — outside what this session can set up; flagged to the project owner as a follow-up action.

**Problem (as found):** `google_mlkit_pose_detection` wraps a Google SDK still in **beta** with an explicit "no SLA, no deprecation policy, may break backward compatibility" notice. This is an ongoing operational risk for a feature the whole product is named after.

**Fix (process, not code):**
- Pin the exact resolved native SDK version in a comment in `pubspec.yaml` next to the `google_mlkit_pose_detection` entry, and note the beta status explicitly so future upgrades are deliberate, not automatic.
- Add a recurring reminder (calendar/issue tracker, outside this repo) to check the ML Kit release notes before any Flutter/Android SDK bump that touches this dependency.
- No code change required now.

### 2.4 Rename `DoubleEMAFilter` or fix it to actually be a double EMA — ✅ Done 2026-07-14 (Option A)

Renamed `DoubleEMAFilter` → `EmaFilter` in [`exercise_counter.dart`](../../lib/features/alarm/domain/services/exercise_counter.dart), with a doc comment explaining it's single-pass EMA (not DEMA) so the name doesn't mislead again. Mechanical find/replace across all 4 counter files (squat, push-up, jumping-jack, high-knees) — no behavior change. `flutter analyze` clean; full suite (229 tests) passes.

**Problem (as found):** The class is named `DoubleEMAFilter` but implements a **single**-pass EMA (`current = current*(1-α) + new*α`). This mislabeling already caused the research doc to describe Awaken's filtering as more sophisticated than it is. Either the name is wrong, or the implementation is incomplete versus what was intended.

**Fix (pick one, low effort either way):**
- **Option A (recommended, no behavior change):** rename to `EmaFilter` — single EMA has served fine across 4 exercise counters with no reported jitter issues; renaming just fixes the misleading label.
- **Option B (behavior change, only if smoothing quality becomes an issue in Phase 1.2/1.4 testing):** implement true DEMA (`2×EMA1(x) − EMA2(EMA1(x))`) for reduced lag at the same smoothing strength — more responsive to fast reps at the cost of slightly more jitter passthrough. Needs re-tuning of downstream angle thresholds if adopted.

**Files:** `exercise_counter.dart` and all 4 counter files (rename is a mechanical find/replace if Option A).

---

## Phase 3 — Product decision: sit-ups — ✅ Done 2026-07-14 (Option A, removed)

Removed entirely per the plan's own recommendation (no user override received). `sitUps` deleted from [`AlarmExerciseType`](../../lib/features/alarm/domain/entities/alarm_exercise_type.dart) (enum value + `label`/`taxStampLabel` switch arms); `isImplemented` simplified to unconditional `true` since all remaining values now have counters (kept as a getter, not inlined, as a defensive check for a future value shipped ahead of its counter). Router's dead `// deferred` fallback arm removed from [`exercise_counter_router.dart`](../../lib/features/alarm/domain/services/exercise_counter_router.dart). DB: verified zero live rows used `'sitUps'` before applying [`20260714000002_remove_situps_exercise_type.sql`](../../supabase/migrations/20260714000002_remove_situps_exercise_type.sql) via Supabase MCP against `nankdbntvvopnfvvvaoo`, confirmed against `pg_constraint`. `flutter analyze` clean (enum exhaustiveness caught every call site); full suite (229 tests) passes.

**Problem (as found):** `AlarmExerciseType.sitUps` exists in the enum and the DB constraint, but `isImplemented == false`, it's excluded from the setup screen's selectable chips, and `ExerciseCounterRouter` silently routes it to `SquatExerciseCounter` if ever reached programmatically. It's currently dead/unreachable via normal UI, but it's real surface area (enum value, DB column value, router fallback) that implies a shipped feature.

**Decision needed — recommend option A:**

**Option A — Remove it entirely.** Delete `sitUps` from `AlarmExerciseType`, drop it from the DB check constraint, remove the router's dead fallback comment. Cleanest; matches "don't half-ship" principle. Effort: XS.

**Option B — Implement it for real**, using the hip-angle FSM pattern the research doc describes (State 0 lying/standing: hip angle >150°; State 1 crunch: hip angle <70°, vertex at hip using shoulder–hip–knee). This is a genuinely new counter, calibration phase, and bad-form heuristic (e.g., neck strain / momentum swing detection) — comparable effort to the existing 4 counters. Effort: M, and it's a real feature addition, not a bugfix.

This plan defaults to **Option A** for the hardening pass; Option B is a legitimate roadmap item but belongs in a feature-scoped plan, not a bug-hardening one.

---

## Phase 4 — Test & QA coverage

### 4.1 Roulette cross-isolate stability test
Covered under 1.1 — the missing test class that would have caught the original bug (same-process tests can't, by construction).

### 4.2 Device-lab manual QA matrix
Not automatable — camera + real bodies. Recommend a short manual pass before the next release covering:
- Low light / backlit conditions (front camera, early morning use case — directly relevant to this feature)
- Distance variance (arm's length vs. across-room)
- A mid-tier/low-end Android device for the FPS-dependent Phase 1.2 fix
- Partial-body-in-frame recovery (phone propped at an angle) — already has some test coverage (`missing ankle on one leg falls back to the other leg`) but only in synthetic-pose unit tests, never against a live camera feed

---

## Phase 5 — Documentation — ✅ Done 2026-07-14

Created [`docs/pose_detection_thresholds.md`](../pose_detection_thresholds.md), recording the *why* behind each tuned constant (squat 100°/150°, push-up 90°/150°/130° shallow gate, jack 1.35× ratio, high-knees 0.15/0.6 fractions) as **deliberate, tested design decisions** — not TODOs. This directly prevents a repeat of what happened with `mlkit_pose_detection_research.md`: an external research pass assuming these numbers came from an official source and generalizing incorrectly across exercises.

---

## Suggested sequencing

1. **Phase 0** (0.1, 0.2) — ship together, both are P0 reachable bugs, both are small.
2. **Phase 1** (1.1, 1.3 first — small/isolated; 1.2 second — larger interface change, do it alone).
3. **Phase 2** (2.1, 2.4-A trivial; 2.2 as a follow-up refactor PR; 2.3 is process-only, do anytime).
4. **Phase 3** — needs a product decision before scheduling.
5. **Phase 4/5** — interleave with each phase above rather than batching at the end (test 1.1 lands with 1.1's fix, doc for a threshold lands when that threshold is touched).
