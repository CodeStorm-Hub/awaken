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

**Critical font note:** Geist and Geist Mono (the design spec fonts) are **NOT on Google Fonts CDN** as of implementation. The codebase uses **Space Grotesk** (body) and **Space Mono** (HUD numerics) as visual equivalents via `google_fonts`. When Geist becomes available on Google Fonts, swap `GoogleFonts.spaceGrotesk` → `GoogleFonts.geist` and `GoogleFonts.spaceMono` → `GoogleFonts.geistMono` throughout `app_typography.dart` only.

---

## 3. Architecture

**Pattern:** Feature-First Clean Architecture. Dependencies flow inward (UI → Domain ← Data). The ML Kit isolate pipeline is explicitly NOT part of Phase 1–3 scope.

```
lib/
├── core/
│   ├── constants/app_constants.dart     ← All magic numbers live here
│   ├── router/app_router.dart           ← GoRouter + AppRoutes constants
│   └── theme/
│       ├── app_colors.dart              ← All Color constants (OKLCH→hex mapped)
│       ├── app_typography.dart          ← TextTheme + AwakenTypography extension
│       └── app_theme.dart               ← ThemeData.dark (ONLY theme, no light)
├── features/
│   ├── alarm/
│   │   ├── data/models/alarm_model.dart
│   │   ├── domain/entities/alarm_entity.dart
│   │   └── presentation/
│   │       ├── providers/alarm_providers.dart
│   │       ├── screens/active_alarm_screen.dart
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
| Active Alarm | `/alarm/active` | `ActiveAlarmScreen` |
| Success | `/alarm/success` | `SuccessScreen` |

Navigate with `context.go(AppRoutes.success)` etc.

---

## 6. State (Riverpod Providers)

All providers in Phase 1–3 are **manual** (not `@riverpod` codegen). Phase 4+ will migrate to `riverpod_annotation` + `build_runner`.

### Dashboard providers (`dashboard_providers.dart`)
| Provider | Type | Description |
|---|---|---|
| `clockProvider` | `StreamProvider<DateTime>` | Ticks every second |
| `clockDisplayProvider` | `StreamProvider<String>` | Formatted "HH:MM", only emits on minute change |
| `dashboardStatsProvider` | `Provider<DashboardStatsEntity>` | Stub with hardcoded mock data; replace with Supabase repo |

### Alarm providers (`alarm_providers.dart`)
| Provider | Type | Description |
|---|---|---|
| `repCountProvider` | `StateProvider<int>` | Current rep count this session |
| `repFeedbackProvider` | `StateProvider<RepFeedback>` | `neutral`/`success`/`failure` — drives border glow |
| `requiredRepsProvider` | `StateProvider<int>` | Target rep count (default 10) |
| `outOfFrameProvider` | `StateProvider<bool>` | True when user is out of camera frame |

`RepFeedback` is an enum: `neutral`, `success`, `failure`.

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

### ❌ Phase 4 — NOT STARTED
- ML Kit pose detection integration (`google_mlkit_pose_detection`)
- Live camera feed (`camera` package — NOT yet in pubspec)
- Supabase auth (Google Sign-In)
- Supabase database: alarms, sessions, streaks tables
- Background alarm scheduling (platform-channel or `flutter_local_notifications` + `android_alarm_manager_plus`)
- Out-of-frame volume ramp-up
- Emergency bypass token system
- Accelerometer fallback for low-end devices
- Push notifications for upcoming alarms

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
