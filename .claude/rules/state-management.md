---
globs:
  - "lib/features/**/presentation/providers/**/*.dart"
  - "lib/features/**/presentation/screens/**/*.dart"
---

# State Management Guidelines
- Use Riverpod (`flutter_riverpod`) for state management.
- Utilize `@riverpod` codegen for modern providers (e.g. `alarm_providers.dart`, `auth_providers.dart`, `dashboard_providers.dart`).
- When changing annotated files, run codegen:
  `dart run build_runner build --delete-conflicting-outputs`
- Swapping repositories between local (SharedPreferences) and cloud (Supabase) must occur reactively based on auth state (`isSignedInProvider`).
- Sync pending offline queue using `PendingSessionQueue` and `SessionSyncService`.
