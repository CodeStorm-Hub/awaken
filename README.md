# Awaken

A camera-verified fitness alarm and territory capture app built with Flutter. Alarms cannot be dismissed until you complete real squats verified on-device via ML Kit pose detection. Territory mode lets you GPS-track runs, close loops on a map to capture polygons, and compete on leaderboards.

**Platforms:** Android (primary), iOS (secondary)

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- Android Studio / Xcode for device emulators and platform tooling
- For cloud sync: Supabase credentials in `lib/core/constants/supabase_config.dart` and platform OAuth config (`google-services.json` on Android, `GIDClientID` in `Info.plist` on iOS)

## Getting started

```bash
flutter pub get                                              # install deps
flutter run -d android                                       # run on Android
flutter run -d ios                                           # run on iOS
flutter analyze lib/                                         # static analysis
flutter test                                                 # run all tests
dart run build_runner build --delete-conflicting-outputs      # codegen (if using @riverpod)
```

See [CLAUDE.md](CLAUDE.md) for full command reference, architecture notes, and coding conventions.

## Features

| Feature | Description |
|---------|-------------|
| **Alarm** | Schedule alarms; dismiss only after camera-verified squats (ML Kit pose detection) |
| **Dashboard** | Clock, next alarm, streak ring, workout stats |
| **Territory** | GPS run tracking, vector map, polygon capture, decay warnings |
| **Leaderboard** | Territory rankings |
| **Sessions** | Workout logging with offline queue and Supabase sync on reconnect |
| **Auth** | Optional Google Sign-In for cloud backup and sync |

## Documentation

Additional design specs, schema details, and architecture history:

- [docs/awake_full_detail.md](docs/awake_full_detail.md)
- [docs/codebase_review.md](docs/codebase_review.md)
- [docs/territory_backend_verification_checklist.md](docs/territory_backend_verification_checklist.md)
