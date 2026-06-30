# Awaken — Full Project Memory Document

> **Purpose:** Complete handoff document. Any AI or developer picking this up cold can understand every decision, the current state, and what's next without reading the codebase.

---

## 1. Product Summary

**Name:** Awaken (codename was RISE in earlier specs)
**Tagline:** Pay your "Wake Up Tax" to conquer the morning.
**Core concept:** A camera-verified fitness alarm. The alarm cannot be dismissed until the user completes a set number of real, form-checked squats verified by on-device ML Kit pose detection. No shake-to-dismiss, no math problems — physical movement only.

**Platform:** Flutter (Android primary, iOS secondary). Cross-platform codebase.

---

## 2. Tech Stack & Versions

| Layer | Package | Version in pubspec |
|---|---|---|
| UI framework | Flutter | SDK constraint `^3.12.2` |
| State management | flutter_riverpod | `^2.5.1` |
| State management codegen | riverpod_annotation + riverpod_generator | `^2.3.5` / `^2.4.3` |
| Backend | supabase_flutter | `^2.5.0` |
| Computer vision | google_mlkit_pose_detection | `^0.12.0` |
| Navigation | go_router | `^13.2.0` |
| Animations | flutter_animate | `^4.5.0` |
| Fonts | google_fonts | `^6.2.1` |
| Linting | custom_lint + riverpod_lint | `^0.7.6` / `^2.3.10` |
| Code gen | build_runner | `^2.4.9` |
| Alarm scheduling | flutter_local_notifications | `^17.2.1` |
| Timezone support | timezone + flutter_timezone | `^0.9.4` / `^1.0.8` |
| In-app alarm audio | just_audio | `^0.9.36` |
| Screen wakelock | wakelock_plus | `^1.2.0` |
| Runtime permissions | permission_handler | `^11.3.1` |
| Local persistence | shared_preferences | `^2.3.2` |

**Critical font note:** Geist and Geist Mono (the design spec fonts) are **NOT on Google Fonts CDN** as of implementation. The codebase uses **Space Grotesk** (body) and **Space Mono** (HUD numerics) as visual equivalents via `google_fonts`. When Geist becomes available on Google Fonts, swap `GoogleFonts.spaceGrotesk` → `GoogleFonts.geist` and `GoogleFonts.spaceMono` → `GoogleFonts.geistMono` throughout `app_typography.dart` only.

---

## 3. Architecture

**Pattern:** Feature-First Clean Architecture. Dependencies flow inward (UI → Domain ← Data). The ML Kit isolate pipeline is explicitly NOT part of Phase 1–3 scope.

```
lib/
├── core/
│   ├── constants/app_constants.dart     ← All magic numbers live here
│   ├── router/
│   │   ├── app_router.dart              ← GoRouter + AppRoutes + initialLocationProvider
│   │   └── navigator_key.dart           ← GlobalKey<NavigatorState> (extracted to avoid circular import)
│   ├── services/
│   │   ├── alarm_notification_service.dart  ← flutter_local_notifications wrapper
│   │   ├── alarm_audio_service.dart         ← just_audio (system ringtone fallback on Android)
│   │   └── wake_lock_service.dart           ← wakelock_plus wrapper
│   └── theme/
│       ├── app_colors.dart              ← All Color constants (OKLCH→hex mapped)
│       ├── app_typography.dart          ← TextTheme + AwakenTypography extension
│       └── app_theme.dart               ← ThemeData.dark (ONLY theme, no light)
├── features/
│   ├── alarm/
│   │   ├── data/
│   │   │   ├── datasources/alarm_local_datasource.dart  ← SharedPreferences persistence
│   │   │   ├── models/alarm_model.dart
│   │   │   └── repositories/alarm_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/alarm_entity.dart
│   │   │   └── repositories/alarm_repository.dart       ← abstract interface
│   │   └── presentation/
│   │       ├── providers/
│   │       │   ├── alarm_providers.dart                 ← session state (repCount, feedback)
│   │       │   └── alarm_schedule_providers.dart        ← alarm list, CRUD, next alarm
│   │       ├── screens/
│   │       │   ├── active_alarm_screen.dart             ← NOW: ConsumerStatefulWidget with audio+wakelock
│   │       │   └── alarm_setup_screen.dart              ← NEW: time picker + rep count + ARM button
│   │       └── widgets/
│   │           ├── camera_hud_overlay.dart
│   │           ├── rep_counter_display.dart
│   │           ├── scan_line_animation.dart
│   │           └── skeleton_wireframe.dart
│   ├── dashboard/
│   │   ├── data/models/dashboard_stats_model.dart
│   │   ├── domain/entities/dashboard_stats_entity.dart
│   │   └── presentation/
│   │       ├── providers/dashboard_providers.dart
│   │       ├── screens/dashboard_screen.dart
│   │       └── widgets/
│   │           ├── armed_alarm_card.dart
│   │           ├── digital_clock.dart
│   │           ├── stat_card.dart
│   │           └── streak_ring.dart
│   └── success/
│       └── presentation/
│           ├── screens/success_screen.dart
│           └── widgets/
│               ├── stat_reveal_item.dart
│               └── streak_badge.dart
├── app.dart     ← MaterialApp.router, ThemeMode.dark forced, AwakenTypography injected
└── main.dart    ← ProviderScope, edge-to-edge SystemUI, portrait lock
```

---

## 4. Design System

### 4.1 Color Tokens (OKLCH → Flutter hex)

| Token | OKLCH | Hex | Usage |
|---|---|---|---|
| `AppColors.background` | `oklch(0 0 0)` | `#000000` | Scaffold background, absolute black |
| `AppColors.card` | `oklch(0.16 0 0)` | `#282828` | Cards, raised surfaces |
| `AppColors.secondary` | `oklch(0.22 0 0)` | `#383838` | Chips, inactive tabs, ring track |
| `AppColors.muted` | `oklch(0.20 0 0)` | `#333333` | Subtle fills |
| `AppColors.foreground` | `oklch(0.985 0 0)` | `#FAFAFA` | Primary text |
| `AppColors.mutedForeground` | `oklch(0.62 0 0)` | `#9E9E9E` | Labels, eyebrows, secondary text |
| `AppColors.primary` | `oklch(0.68 0.18 247)` | `#4A9EFF` | Electric blue — core brand accent |
| `AppColors.accent` | `oklch(0.62 0.22 295)` | `#A259FF` | Electric purple — gamified HUD markers |
| `AppColors.success` | `oklch(0.72 0.20 150)` | `#34D399` | Perfect rep / streak-up green |
| `AppColors.destructive` | `oklch(0.62 0.24 25)` | `#F87171` | Bad form / failure red |
| `AppColors.border` | `oklch(1 0 0 / 10%)` | `#1AFFFFFF` | Hairline separators |
| `AppColors.primaryGlow` | — | `#664A9EFF` | 40% alpha primary for glow effects |
| `AppColors.accentGlow` | — | `#66A259FF` | 40% alpha accent for glow |
| `AppColors.successGlow` | — | `#6634D399` | 40% alpha success for glow |
| `AppColors.destructiveGlow` | — | `#66F87171` | 40% alpha destructive for glow |

### 4.2 Typography

Two font families. Both accessed through **two mechanisms**:
1. `Theme.of(context).textTheme` — Material TextTheme (bodyMedium, titleLarge, etc.)
2. `Theme.of(context).extension<AwakenTypography>()!` — HUD-specific styles

| AwakenTypography field | Font | Size | Weight | Usage |
|---|---|---|---|---|
| `hudClock` | Space Mono | 80px | W700 | Dashboard digital clock |
| `hudRepCounter` | Space Mono | 72px | W700 | Rep count number on alarm screen |
| `hudRepFraction` | Space Mono | 36px | W400 | The "/ 10" denominator, muted |
| `eyebrow` | Space Grotesk | 11px | W600 | ALL-CAPS section labels, 3px tracking |
| `statValue` | Space Mono | 28px | W700 | Stat numbers on cards |
| `statLabel` | Space Grotesk | 11px | W500 | Unit label under stat value |

**Key rules:**
- `FontFeature.tabularFigures()` is applied to ALL monospace styles so digit widths are fixed (no layout shift when clock ticks).
- `letterSpacing: -2` on `hudClock` for tight digital-readout feel.
- `eyebrow` style uses `letterSpacing: 3` and `height: 1` — always rendered UPPERCASE.

### 4.3 Motion

| Animation | Where | Implementation |
|---|---|---|
| Scan line sweep | Active alarm screen | `flutter_animate` `.moveY()` with `onPlay: repeat` |
| Rep count number change | Active alarm counter | `AnimatedSwitcher` with scale transition |
| Border glow on rep | Active alarm border | `AnimatedContainer` color switch, 150ms |
| Streak badge pop-in | Success screen | `flutter_animate` `.scale()` with `Curves.easeOutBack` |
| Stats float-up | Success screen | `flutter_animate` `.slideY().fadeIn()` with staggered delays |
| Clock tick | Dashboard | `StreamProvider<DateTime>` → `distinct()` display string |

### 4.4 Layout Rules (from design spec)
- `--radius: 1rem` → `BorderRadius.circular(24)` on cards, `circular(16)` on chips
- Mobile-first portrait only. `SystemChrome.setPreferredOrientations([portraitUp, portraitDown])`
- Edge-to-edge: `SystemUiMode.edgeToEdge`, transparent status/nav bars
- No floats, no absolute positioning except camera HUD overlay (uses `Stack` + `Positioned.fill`)
- `RepaintBoundary` wraps all animation sites

---

## 5. Routing

**Package:** `go_router ^13.2.0`
**Provider:** `appRouterProvider` — `Provider<GoRouter>` (never disposed, `keepAlive` implicit via `Provider` not `AutoDispose`)

| Route | Path | Screen |
|---|---|---|
| Dashboard | `/` | `DashboardScreen` |
| Alarm Setup | `/alarm/setup` | `AlarmSetupScreen` |
| Active Alarm | `/alarm/active` | `ActiveAlarmScreen` |
| Success | `/alarm/success` | `SuccessScreen` |

Navigate with `context.go(AppRoutes.success)` or `context.push(AppRoutes.alarmSetup)`.

**Initial route override (notification launch):** `main.dart` calls `AlarmNotificationService.getInitialRoute()` before `runApp`. If the app was tapped from an alarm notification, it returns `'/alarm/active'` and this is passed via `ProviderScope.overrides([initialLocationProvider.overrideWithValue(...)])` so GoRouter starts at the alarm screen.

---

## 6. State (Riverpod Providers)

All providers in Phase 1–3 are **manual** (not `@riverpod` codegen). Phase 4+ will migrate to `riverpod_annotation` + `build_runner`.

### Dashboard providers (`dashboard_providers.dart`)
| Provider | Type | Description |
|---|---|---|
| `clockProvider` | `StreamProvider<DateTime>` | Ticks every second |
| `clockDisplayProvider` | `StreamProvider<String>` | Formatted "HH:MM", only emits on minute change |
| `dashboardStatsProvider` | `Provider<DashboardStatsEntity>` | Stub with hardcoded mock data; replace with Supabase repo |

### Alarm session providers (`alarm_providers.dart`)
| Provider | Type | Description |
|---|---|---|
| `repCountProvider` | `StateProvider<int>` | Current rep count this session |
| `repFeedbackProvider` | `StateProvider<RepFeedback>` | `neutral`/`success`/`failure` — drives border glow |
| `requiredRepsProvider` | `StateProvider<int>` | Target rep count (default 10, overridden on alarm start) |
| `outOfFrameProvider` | `StateProvider<bool>` | True when user is out of camera frame |

`RepFeedback` is an enum: `neutral`, `success`, `failure`.

### Alarm scheduling providers (`alarm_schedule_providers.dart`) — Phase 4a NEW
| Provider | Type | Description |
|---|---|---|
| `alarmRepositoryProvider` | `Provider<AlarmRepository>` | Provides `AlarmRepositoryImpl(AlarmLocalDatasource())` |
| `alarmListProvider` | `AsyncNotifierProvider<AlarmListNotifier, List<AlarmEntity>>` | Full alarm list; add/remove/toggle methods |
| `nextAlarmProvider` | `Provider<AlarmEntity?>` | Next upcoming active alarm (derived from `alarmListProvider`) |

`AlarmListNotifier.addAlarm()` → saves to SharedPreferences + schedules notification.
`AlarmListNotifier.removeAlarm()` → deletes from SharedPreferences + cancels notification.
`AlarmListNotifier.toggleAlarm()` → flips `isActive`, reschedules or cancels accordingly.

---

## 7. Screens — Implementation Notes

### Dashboard Screen
- `clockDisplayProvider` → `DigitalClock` widget (80px mono clock)
- `dashboardStatsProvider` → `ArmedAlarmCard` + `StreakRing` + `StatCard` × 2
- `StreakRing` uses `CustomPainter` with two arcs: grey track + blue progress + glow `BlurMaskFilter`
- Clock uses `AnimatedSwitcher` per digit for a smooth tick effect (Phase 3)

### Active Alarm Screen
- Full-screen `Stack`: camera placeholder → skeleton wireframe → scan line → rep counter
- `AnimatedContainer` border switches color based on `repFeedbackProvider`
- `GestureDetector` on entire screen simulates a rep tap (Phase 3 replaces with ML Kit)
- On reaching `requiredReps`, auto-navigates to `/alarm/success` after 300ms delay
- **Out-of-frame penalty** not implemented yet — stub `outOfFrameProvider` is ready

### Success Screen
- Receives no route parameters in Phase 3 (stats are read from `dashboardStatsProvider`)
- Streak badge animates with `Curves.easeOutBack` for natural overshoot feel
- Three `StatRevealItem` widgets with 120ms stagger between them
- "Start My Day" CTA resets `repCountProvider` and `repFeedbackProvider` then navigates to `/`

### Skeleton Wireframe
- 14 normalized joint positions (0.0–1.0 coordinates, mapped to actual `Size`)
- Connections drawn twice: first pass with `BlurMaskFilter` (glow), second pass sharp line on top
- Hardcoded squatting pose — Phase 4 replaces with live ML Kit `PoseLandmark` data

---

## 8. What Is Implemented vs Pending

### ✅ Phase 1 — DONE
- Project structure (Feature-First Clean Architecture)
- All dependencies in `pubspec.yaml`
- `analysis_options.yaml` with strict lints
- `core/theme/` — AppColors, AppTypography, AppTheme (dark only)
- `core/constants/app_constants.dart`
- `core/router/app_router.dart`
- Domain entities: `AlarmEntity`, `DashboardStatsEntity`
- Data models: `AlarmModel`, `DashboardStatsModel`
- All Riverpod providers (stub data)
- `main.dart` — ProviderScope, edge-to-edge, portrait lock
- `app.dart` — MaterialApp.router, forced dark, AwakenTypography injection

### ✅ Phase 2 — DONE (part of Phase 1)
- `AppColors` — all OKLCH tokens mapped
- `AppTypography` — TextTheme + AwakenTypography ThemeExtension
- `AppTheme.dark` — complete ThemeData (no light mode anywhere)
- Page transitions: PredictiveBackPageTransitionsBuilder (Android 14+), CupertinoPageTransitionsBuilder (iOS)

### ✅ Phase 3 — DONE
- `DigitalClock` — ticking, select-optimized, RichText with dimmed colon
- `ArmedAlarmCard` — alarm time + Wake Up Tax chip
- `StreakRing` — CustomPainter with glow arc
- `StatCard` — reusable stat tile
- `CameraHudOverlay` — black placeholder stack
- `SkeletonWireframe` — CustomPainter with 14 joints + glow
- `ScanLineAnimation` — looping gradient sweep via flutter_animate
- `RepCounterDisplay` — AnimatedSwitcher per digit
- `StreakBadge` — scale pop-in with easeOutBack
- `StatRevealItem` — staggered slideY + fadeIn
- `DashboardScreen` — full layout
- `ActiveAlarmScreen` — full layout with tap-to-rep interaction
- `SuccessScreen` — full layout with animations

### ✅ Phase 4a — DONE (Alarm Scheduling Engine)
- `flutter_local_notifications` exact alarm scheduling with full-screen intent
- `AlarmNotificationService` — schedule, cancel, request permissions, detect notification launch
- `AlarmAudioService` — `just_audio` with system ringtone fallback on Android
- `WakeLockService` — `wakelock_plus` keep screen on during alarm
- `AlarmLocalDatasource` — SharedPreferences CRUD (pre-Supabase)
- `AlarmRepository` + `AlarmRepositoryImpl` — domain/data split
- `AlarmListNotifier` + `alarmListProvider` + `nextAlarmProvider` — real alarm state
- `AlarmSetupScreen` — time picker + rep count selector + ARM button
- `ActiveAlarmScreen` → `ConsumerStatefulWidget` (initState: audio+wakelock, dispose: cleanup)
- Dashboard: real alarm from `nextAlarmProvider`, tappable no-alarm card, alarm list with swipe-delete, toggle switch
- AndroidManifest: WAKE_LOCK, SCHEDULE_EXACT_ALARM, USE_EXACT_ALARM, RECEIVE_BOOT_COMPLETED, POST_NOTIFICATIONS, USE_FULL_SCREEN_INTENT, FOREGROUND_SERVICE
- Info.plist: NSUserNotificationUsageDescription, NSCameraUsageDescription, UIBackgroundModes audio+fetch
- `navigatorKey` extracted to `navigator_key.dart` to prevent circular import between router and notification service
- Timezone initialization in `main.dart` (flutter_timezone + timezone packages)

**Audio file:** Place `assets/audio/alarm.mp3` in the assets directory. Android falls back to `content://settings/system/alarm_alert` if absent; iOS will be silent without it.

### ✅ Phase 4b — DONE (Camera + ML Kit Pose Detection)
- `camera: ^0.11.0` added to pubspec; CAMERA permission in AndroidManifest + Info.plist NSCameraUsageDescription
- `SquatCounterService` — two-state machine (standing ↔ squatting) using knee joint angle from ML Kit landmarks. Thresholds: squat ≤ 100°, stand ≥ 150°. Averages left + right knee when both are confident (likelihood ≥ 0.5).
- `PoseOverlayPainter` — CustomPainter that maps ML Kit image-space landmarks to screen-space, with correct rotation transformation for all 4 `InputImageRotation` values. Front camera mirror handled. Color shifts to `AppColors.success` when in squat phase.
- `CameraHudOverlay` updated — now accepts `CameraController?`, `Pose?`, `imageSize`, `rotation`, `isFrontCamera`, `isSquatting`. Shows live `CameraPreview` (cover-fill via `FittedBox`); falls back to static `SkeletonWireframe` while initializing or if no pose detected.
- `ActiveAlarmScreen` converted to `ConsumerStatefulWidget` with full camera lifecycle:
  - `_initCamera()` — requests permission, finds front camera, `CameraController(ResolutionPreset.medium, nv21/bgra8888)`, then `startImageStream`
  - `_onCameraImage()` — throttled to ~15 FPS (`66ms` skip), non-blocking (`_isDetecting` flag)
  - `_processImage()` — converts `CameraImage` → `InputImage` (NV21 multi-plane concatenation on Android, single plane on iOS) → `PoseDetector.processImage()` → `SquatCounterService.processPose()` → auto-counts rep
  - `dispose()` — `stopImageStream()`, `controller.dispose()`, `poseDetector.close()`, audio stop, wakelock disable
  - `_router` captured in `initState` to avoid BuildContext-across-async-gap lint
  - Tap fallback active when camera is loading or permission denied

**Instruction bar states (Phase 4b):**
- `CAMERA STARTING...` — controller not yet initialized
- `CAMERA DENIED — TAP TO SIMULATE` — permission denied
- `GET IN FRAME` — camera active but no pose detected
- `DO A SQUAT` — pose detected, user is standing
- `HOLD... COME BACK UP` — knee angle below squat threshold (rep in progress)
- `PERFECT REP ✓` — rep just completed (150ms green flash)

### ❌ Phase 4c — NOT STARTED
- Out-of-frame penalty (sound ramp-up when `outOfFrameProvider` is true)
- Bad form detection (shoulder/hip alignment check)
- Accelerometer fallback for low-end devices without camera

### ✅ Phase 5 — DONE (Supabase Auth + Cloud Sync)

**Supabase project:** `fsdfqcnjcjtdmdjshrvu` (ap-northeast-1, awaken)
**Project URL:** `https://fsdfqcnjcjtdmdjshrvu.supabase.co`
**Anon key:** stored in `lib/core/constants/supabase_config.dart`

**Auth:**
- `google_sign_in: ^6.2.1` added to pubspec
- `SupabaseAuthRepository` — `GoogleSignIn(serverClientId: webClientId)` → `signInWithIdToken(OAuthProvider.google)`
- Auth providers: `authStateProvider` (StreamProvider), `isSignedInProvider`, `currentUserProvider`
- `AuthScreen` — dark design with Google icon button + "Continue without account" skip link
- `/auth` route added to GoRouter

**Database (all tables have RLS, users own their own rows):**
- `alarms` — `id text pk`, `user_id uuid`, `scheduled_time`, `required_reps`, `is_active`, `label`
- `sessions` — `id uuid pk (gen_random_uuid())`, `user_id`, `alarm_id`, `completed_at`, `reps_completed`, `duration_seconds`, `calories_burned`
- `streaks` — `user_id uuid pk`, `current_streak`, `best_streak`, `last_completed_date date`, `updated_at`

**Repository switching:**
- `alarmRepositoryProvider` watches `isSignedInProvider` — switches between `AlarmSupabaseRepositoryImpl` and `AlarmRepositoryImpl` (SharedPreferences) automatically
- `AlarmListNotifier.build()` re-runs when auth state flips (local ↔ cloud)

**Session recording:**
- `sessionStartTimeProvider` (StateProvider<DateTime?>) set in `ActiveAlarmScreen.initState`
- `SuccessScreen` reads `repCountProvider` + `sessionStartTimeProvider`, records `SessionEntity` to Supabase via `SupabaseSessionRepository.recordSession()`
- `_updateStreak()` runs after each session — upserts `streaks` table using date arithmetic (yesterday continuation vs. reset)
- `dashboardStatsProvider` changed from `Provider` → `FutureProvider` — fetches streak + weeklyReps + monthlyCalories from Supabase when signed in

**Dashboard:**
- Header shows account icon (green = signed in, grey = signed out); tap to sign in/out
- Stats show `—` while loading or signed out
- `_StreakCard` shows `CircularProgressIndicator` while stats are fetching

**Google OAuth still needs (user must configure):**
1. Google Cloud Console → create OAuth 2.0 credentials (Web + Android + iOS)
2. Supabase Dashboard → Authentication → Providers → Google → paste Web client ID + secret
3. Fill `googleWebClientId`, `googleAndroidClientId`, `googleIosClientId` in `supabase_config.dart`
4. Android: add `google-services.json` to `android/app/`
5. iOS: add `GIDClientID` to `Info.plist` (the iOS client ID from GCC)

### ❌ Phase 6 — NOT STARTED
- Push notifications for upcoming alarms
- RevenueCat IAP
- Onboarding flow

---

## 9. Known Issues & Decisions

1. **Font substitution:** Space Grotesk + Space Mono used instead of Geist + Geist Mono. See §2 for swap instructions.

2. **Windows developer mode:** Running `flutter pub get` on Windows prints a symlink warning. This only affects Windows desktop builds, not Android/iOS.

3. **`clockDisplayProvider` distinctness:** Uses `.distinct()` (from `rxdart`, a transitive dependency of `supabase_flutter`) to avoid emitting identical strings every second. If rxdart is removed, replace with a `StreamController` + manual dedup.

4. **riverpod_generator not used yet:** `riverpod_annotation` and `riverpod_generator` are in pubspec but no `@riverpod` annotations are written. Phase 4 will migrate all providers to codegen. To run codegen: `dart run build_runner build`.

5. **Supabase not initialized:** `supabase_flutter` is in pubspec but `Supabase.initialize()` is not called in `main.dart`. Add before `runApp()` when keys are available:
   ```dart
   await Supabase.initialize(url: 'YOUR_URL', anonKey: 'YOUR_KEY');
   ```

6. **`context.go` in Future.delayed:** The active alarm screen uses `Future.delayed` then `context.go(...)`. This is safe because `context.mounted` is checked. If lint complains, extract to a separate method.

7. **`SkeletonWireframe` is static:** The skeleton uses hardcoded joint positions in a squatting pose. Phase 4 replaces this with live `PoseLandmark` data from ML Kit.

---

## 10. Supabase Schema (planned, not yet created)

```sql
-- Users handled by Supabase Auth (Google OAuth)

create table alarms (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  scheduled_time timestamptz not null,
  required_reps int not null default 10,
  is_active bool not null default true,
  label text,
  created_at timestamptz default now()
);

create table sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  alarm_id uuid references alarms,
  completed_at timestamptz not null,
  reps_completed int not null,
  duration_seconds int not null,
  calories_burned int not null,
  created_at timestamptz default now()
);

create table streaks (
  user_id uuid primary key references auth.users,
  current_streak int not null default 0,
  best_streak int not null default 0,
  last_completed_date date,
  updated_at timestamptz default now()
);
```

---

## 11. Performance Optimizations Baked In

- `const` constructors on all static widgets
- `RepaintBoundary` wrapping every animated widget site
- `MediaQuery.sizeOf(context)` instead of `MediaQuery.of(context).size`
- `clockDisplayProvider` uses `.distinct()` — only emits when minute changes, not every second
- `StreakRing` CustomPainter has `shouldRepaint` gated on `progress != old.progress`
- `SkeletonWireframe` CustomPainter has `shouldRepaint: false` when joints are static
- `flutter_animate` uses GPU-composited Transform/Opacity — no layout thrashing
- `AnimatedContainer` for border glow — Flutter diffs the decoration, no rebuilds
- `AnimatedSwitcher` in `RepCounterDisplay` — only the changed digit transitions

---

## 12. Commands Reference

```bash
# Get dependencies
flutter pub get

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios

# Static analysis
flutter analyze lib/

# Run code generation (for Phase 4 @riverpod annotations)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for code gen
dart run build_runner watch --delete-conflicting-outputs
```
