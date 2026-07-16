# CLAUDE.md

Guidelines for Claude Code in the **Awaken** repository.

## Project Overview
**Awaken** is a camera-verified fitness alarm (Flutter, Android primary / iOS secondary). Alarms require performing a set number of real squats, verified on-device via ML Kit pose detection (knee-angle state machine). Includes a GPS-tracked territory capture mode.

## Critical Guidelines
- **Target Platform**: Currently **Android-only** (iOS launch is deferred). Focus all native configurations, permissions, and dependencies on Android.
- **Strict Linting**: Treat all analyzer warnings/hints as errors (strict-casts, strict-inference, strict-raw-types enabled). See [analysis_options.yaml](file:///J:/GitHub/awaken/analysis_options.yaml).
- **Dark Theme Only**: The app forces Dark Mode (`ThemeMode.dark`). Never introduce light theme components or hardcoded colors; use [AppColors](file:///J:/GitHub/awaken/lib/core/theme/app_colors.dart).
- **Detailed Rules**: See modular rules in `.claude/rules/` for architecture, state management, pose pipeline, territory map, and database details.

## Commands
```bash
flutter pub get                                              # Install dependencies
flutter run -d android                                       # Run on Android emulator/device
flutter run -d ios                                           # Run on iOS (future support)
flutter analyze lib/                                         # Strict static analysis
flutter test                                                 # Run all tests
flutter test test/territory/                                 # Territory tests only
flutter test test/alarm/ test/sessions/ test/core/           # Other feature tests
dart run build_runner build --delete-conflicting-outputs     # Build Riverpod codegen
dart run build_runner watch --delete-conflicting-outputs     # Watch Riverpod codegen
```
