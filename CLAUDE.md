# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

**Awaken** — a camera-verified fitness alarm (Flutter, Android primary / iOS secondary). The alarm cannot be dismissed until the user performs a set number of real squats, verified on-device via ML Kit pose detection (knee-angle state machine). No shake-to-dismiss, no math problems — physical movement only.

Also includes a **territory capture** mode: GPS-tracked runs on a dark-themed map where users loop closed paths to claim map polygons, compete on a leaderboard, and receive decay warnings when territory is at risk.

## Commands

```bash
flutter pub get                                              # install deps
flutter run -d android                                       # run on Android
flutter run -d ios                                           # run on iOS
flutter analyze lib/                                         # static analysis (strict-casts/inference/raw-types enabled, see analysis_options.yaml)
flutter test                                                 # run all tests
flutter test test/territory/                                 # territory tests only
flutter test test/alarm/ test/sessions/ test/core/          # other feature tests
dart run build_runner build --delete-conflicting-outputs      # codegen (riverpod_annotation, when @riverpod is used)
dart run build_runner watch --delete-conflicting-outputs      # codegen watch mode
```

`analysis_options.yaml` extends `flutter_lints` plus `strict-casts`, `strict-inference`, `strict-raw-types`, and treats `missing_required_param`/`missing_return` as errors — keep new code compliant.

## Architecture

Feature-First Clean Architecture, dependencies flow inward: `presentation → domain ← data`.

```
lib/
├── core/
│   ├── constants/        # app_constants.dart (all magic numbers), supabase_config.dart (keys/IDs)
│   ├── router/           # app_router.dart (GoRouter + StatefulShellRoute), navigator_key.dart
│   ├── services/         # alarm_notification_service.dart, alarm_audio_service.dart, wake_lock_service.dart,
│   │                     # exact_alarm_permission_service.dart, territory_decay_notification_service.dart
│   └── theme/            # app_colors.dart, app_typography.dart, app_theme.dart — dark-only, no light theme
└── features/
    ├── alarm/            # setup, scheduling, active-alarm camera/ML Kit flow
    ├── auth/             # Google Sign-In via Supabase, repository switching local↔cloud
    ├── dashboard/        # clock, next alarm, streak ring, stats
    ├── sessions/         # completed-workout logging, offline sync queue
    ├── success/          # post-alarm celebration screen
    └── territory/        # GPS run tracking, map capture, leaderboard, decay warnings
```

Each feature follows `data/{datasources,models,repositories}`, `domain/{entities,repositories,services}`, `presentation/{providers,screens,widgets}`.

### State management

Riverpod (`flutter_riverpod`) with **partial `@riverpod` codegen** — `alarm_providers.dart`, `auth_providers.dart`, and `dashboard_providers.dart` use `riverpod_annotation`/`riverpod_generator`; remaining providers are hand-written. After editing annotated files, run `build_runner` per the command above.

Key providers worth knowing before touching the alarm flow:
- `repCountProvider`, `repFeedbackProvider` (`neutral`/`success`/`failure`), `requiredRepsProvider`, `outOfFrameProvider` — session-local squat state (`alarm_providers.dart`)
- `alarmListProvider` (`AsyncNotifierProvider`) — CRUD for scheduled alarms; `alarmRepositoryProvider` watches `isSignedInProvider` and swaps between the SharedPreferences-backed repo and the Supabase-backed repo automatically (local ↔ cloud)
- `nextAlarmProvider` — derived next upcoming active alarm
- `clockDisplayProvider` — `StreamProvider<String>` using `.distinct()` (from `rxdart`, a transitive dep of `supabase_flutter`) so it only emits on minute change, not every tick

Territory run state lives in `activeRunProvider` and map readiness in `territoryMapReadyProvider` (`active_run_providers.dart`, `territory_providers.dart`). Tab switches away from an active run prompt discard confirmation via `_ShellScaffold` in `app_router.dart`.

### Local vs cloud repository switching

Every alarm/session/territory repository has a SharedPreferences or local implementation (offline) and a Supabase implementation (cloud-synced). The active implementation is chosen reactively based on sign-in state — don't assume one or the other is active; code against the abstract `domain/repositories` interface.

### Sessions offline sync queue

When signed in, `CompositeSessionRepository` always writes locally first, then attempts Supabase. On remote failure, the session is enqueued in `PendingSessionQueue` (SharedPreferences-backed). `SessionSyncService.flushPendingSessions()` retries the queue; it is triggered on sign-in via `sessionSyncOnSignInProvider` in `session_providers.dart`. Never drop a completed workout — local save is the source of truth until remote succeeds.

### Squat detection pipeline (active alarm screen)

`ActiveAlarmScreen` is a `ConsumerStatefulWidget` that owns the full camera lifecycle:
1. `_initCamera()` requests permission, opens the front camera (`ResolutionPreset.medium`)
2. `_onCameraImage()` throttles the image stream to ~15 FPS via a `66ms` skip + `_isDetecting` guard (never block the stream callback)
3. `_processImage()` converts `CameraImage` → ML Kit `InputImage` (NV21 multi-plane concat on Android, single plane on iOS) → `PoseDetector` → `SquatCounterService`
4. `SquatCounterService` is a two-state machine on knee-joint angle: squat triggers at ≤100°, rep counts when angle returns to ≥150° (averages left/right knee when both landmarks have likelihood ≥0.5)
5. If camera permission is denied or still loading, tapping anywhere simulates a rep — the user is never trapped without a fallback.
6. `dispose()` must stop the image stream, dispose the controller, close the pose detector, stop alarm audio, and disable wakelock — all four, in that order, to avoid resource leaks.

Coordinate mapping from ML Kit image-space to screen-space (`PoseOverlayPainter`) must account for `InputImageRotation` (all 4 values) and mirror the front camera — see existing rotation math before changing this rather than re-deriving it.

### Territory capture (run screen)

`TerritoryRunScreen` is the shell tab at `/territory`. It combines:
- Branded vector tiles (`TerritoryVectorTileLayer`) and neon polygon overlays (`TerritoryPolygonLayer`)
- GPS tracking with Kalman filtering (`GpsKalmanFilter`), RDP path simplification, and loop-closure validation (`RunValidationService`)
- Capture submission via `TerritoryRepository` (local offline stub or Supabase when signed in)
- Run controls, stats HUD, and capture result sheet; active runs block tab switches until confirmed discard

Leaderboard and territory overview are separate routes: `/leaderboard` (shell tab) and `/territory/overview` (full-screen overlay).

### Routing

`go_router`, `appRouterProvider` is a non-disposed `Provider<GoRouter>`. Route constants live in `AppRoutes` (`app_router.dart`).

**Shell tabs** (`StatefulShellRoute.indexedStack` with bottom nav):
- `/dashboard` — home (default; `/` redirects here)
- `/territory` — GPS run / map capture
- `/leaderboard` — territory rankings

**Overlay routes** (above shell, no bottom nav):
- `/territory/overview` — territory detail
- `/auth` — Google Sign-In
- `/alarm/setup`, `/alarm/active`, `/alarm/success` — alarm flow

When the app is launched from a tapped alarm notification, `main.dart` calls `AlarmNotificationService.getInitialRoute()` before `runApp` and overrides `initialLocationProvider` so GoRouter boots directly into `/alarm/active` — don't rely on normal navigation to reach that screen in that case.

### Design system

Dark theme only (`ThemeData.dark`, forced — no light mode exists anywhere). Colors are OKLCH design tokens hand-mapped to hex in `app_colors.dart`; don't reintroduce raw hex literals in widgets, reference `AppColors`. Two font families via `google_fonts`: **Space Grotesk** (body) and **Space Mono** (HUD numerics, all with `FontFeature.tabularFigures()` to avoid layout shift on ticking digits) — these are stand-ins for Geist/Geist Mono from the original design spec, which aren't on the Google Fonts CDN; swap `GoogleFonts.spaceGrotesk`/`spaceMono` → `GoogleFonts.geist`/`geistMono` in `app_typography.dart` only, if Geist ever becomes available. HUD-specific text styles live on the `AwakenTypography` `ThemeExtension`, accessed via `Theme.of(context).extension<AwakenTypography>()!`, separate from the normal Material `TextTheme`.

### Backend (Supabase)

Project `fsdfqcnjcjtdmdjshrvu` (ap-northeast-1). Tables `alarms`, `sessions`, `streaks`, and territory-related tables all have RLS scoped to `auth.users` — see schema in `docs/awake_full_detail.md` §10 if you need exact columns. Google OAuth requires `googleWebClientId`/`googleAndroidClientId`/`googleIosClientId` to be filled in `lib/core/constants/supabase_config.dart` plus `google-services.json` (Android) / `GIDClientID` in `Info.plist` (iOS) — these are environment-specific and not committed.

### Tests

Test suite under `test/`:
- `test/alarm/` — squat counter state machine
- `test/core/` — alarm notification service
- `test/sessions/` — pending queue and sync service
- `test/territory/` — geo utils, Kalman filter, RDP simplifier, run validation, map cancellation, e2e widget flows

Run `flutter test` before submitting changes that touch these areas.

## Notes

- `assets/audio/alarm.mp3` must exist for in-app alarm audio; Android falls back to the system alarm ringtone if missing, iOS will be silent.
- Portrait-only, edge-to-edge (`SystemUiMode.edgeToEdge`, transparent system bars) — set in `main.dart`.
- `flutter pub get` on Windows prints a symlink warning; harmless, only affects Windows desktop builds.
- Further historical/architectural detail (full phase history, design tokens, user flows) lives in `docs/awake_full_detail.md` and `docs/codebase_review.md` — consult them for context beyond what's summarized here.
