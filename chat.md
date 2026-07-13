I'll work through this in phases: map the codebase, review packages and the Supabase database, deep-dive the alarm + ML Kit pipeline, research current best practices, then implement fixes and run analysis/tests.

While analysis runs, let me research current ML Kit + camera best practices.

Now wire lifecycle handling into the active alarm screen:

Now the push-up counter — replace per-frame bad-form spam with a per-attempt shallow-rep check:

High knees — scale-invariant threshold from calibrated standing thigh length, with hysteresis:

Now the overlay painter mirroring for the remaining rotation cases:

Adding regression tests for the changed counter behaviors:

All done — full review completed and fixes implemented. Analyzer is clean and all **221 tests pass** (218 baseline + 3 new regression tests).

## Fixes implemented (alarm workout + ML Kit)

**Pose pipeline** ([alarm_pose_pipeline.dart](lib/features/alarm/presentation/services/alarm_pose_pipeline.dart))
- Wrapped ML Kit `processImage` in a try/catch — previously a single failed frame (detector closing mid-frame, malformed buffer) surfaced as an unhandled async error during the alarm.
- Fixed the multi-plane fallback: it concatenated YUV_420_888 planes and labeled the result NV21, which is wrong (that produces I420 plane order and ignores row/pixel strides). It now does a proper stride-aware YUV420→NV21 interleave.
- Added `pauseForLifecycle()`/`resumeAfterLifecycle()` and wired a `WidgetsBindingObserver` into `ActiveAlarmScreen` — per camera-plugin guidance, holding the camera while backgrounded breaks it on many Android devices; the alarm camera now releases and re-opens cleanly.
- Guarded dispose/permission races during async startup.

**Exercise counters**
- **Push-ups**: the counter flagged `badForm` on *every frame* of a normal descent (elbow between 90° and 130°), so the screen flashed red failure feedback on every rep. It now only flags once per shallow attempt — a dip that returns to extension without reaching 90° depth.
- **Jumping jacks**: arms and feet naturally desynchronize mid-jump, and the counter flagged that transient state as bad form on every rep. It now requires the mismatch to be sustained ~0.7 s before flagging.
- **High knees**: the lift threshold was `(leftHip.y − rightHip.y).abs() + 40` × 0.12 — the vertical delta between the two hips is ~0, so this was effectively a constant ~4.8 px regardless of body size, distance, or resolution. It's now normalized to the standing thigh length captured at calibration (lift = knee within 15% of hip height), with plant hysteresis (60%) so jitter can't double-count.
- **Overlay painter**: front-camera mirroring was only applied in the 270°/0° rotation branches; devices whose front sensor reports 90° (or 180°) drew the skeleton un-mirrored. All four branches now mirror consistently.
- **Squats**: reviewed against current guidance (100°/150° thresholds, EMA smoothing, depth gate, calibration) — matches published heuristics; left as-is.

**Package**: upgraded `google_mlkit_pose_detection` 0.12.1 → **0.15.0** (newer ML Kit SDKs; API-compatible, resolved cleanly).

## Supabase review — action needed on your side

⚠️ **`public.spatial_ref_sys` has RLS disabled** — it's a PostGIS system table exposed to the anon key. I did not change it because enabling RLS without policies can break PostGIS lookups; the cleaner fix is moving the `postgis` extension out of `public` (also flagged by the linter). If you want the quick mitigation: `ALTER TABLE public.spatial_ref_sys ENABLE ROW LEVEL SECURITY;` — [docs](https://supabase.com/docs/guides/database/postgres/row-level-security).

Other advisories worth queuing (I made no DB changes): `hsl_to_hex` and `profiles_lock_territory_color` have mutable `search_path`; several `SECURITY DEFINER` RPCs (`allocate_territory_color`, `capture_territory`, `touch_territory_defense`, etc.) are executable by `anon`/`authenticated` — review whether each is intentional ([linter guide](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable)); and leaked-password protection is off in Auth. All 19 app tables have RLS enabled — schema itself looks healthy.

## Packages I deliberately did *not* upgrade

`go_router` 13→17, `flutter_riverpod` 2→3, `flutter_local_notifications` 17→22, `geolocator` 13→14, `google_sign_in` 6→7 all have breaking API changes and touch alarm scheduling/auth — each deserves its own migration pass rather than a bundled bump. Also note `flutter_map_cancellable_tile_provider` is now **discontinued**; worth planning a replacement when you next touch the territory map.

Sources: [ML Kit pose detection (Android)](https://developers.google.com/ml-kit/vision/pose-detection/android) · [ML Kit pose classification options](https://developers.google.com/ml-kit/vision/pose-detection/classifying-poses) · [google_mlkit_pose_detection](https://pub.dev/packages/google_mlkit_pose_detection) · [camerax YUV_420_888 issue #626](https://github.com/flutter-ml/google_ml_kit_flutter/issues/626) · [ML Kit fitness blog](https://developers.googleblog.com/ml-kit-pose-detection-makes-staying-active-at-home-easier/) · [AI fitness form-correction writeup](https://dev.to/godlymane11/how-i-built-real-time-ai-form-correction-into-a-mobile-fitness-app-3k09)