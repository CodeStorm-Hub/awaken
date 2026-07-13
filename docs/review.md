High-value Fable 5 tasks for Awaken (ranked)
Tier 1 — Best ROI (complex, multi-file, verifiable)
1. Fix the vector map tile cancellation storm

The log floods with TileLoader._renderTile → Cancelled errors. This likely involves TerritoryRunScreen, territoryMapStyleProvider, territoryListProvider, and how FlutterMap rebuilds/disposes during navigation.

Fable 5 prompt shape:
"Investigate and fix CancellationException flood from vector_map_tiles in territory run screen. Reproduce from flutter-run-logs.md, identify rebuild/dispose race, fix without breaking offline map. Run flutter analyze and existing territory tests."

This is exactly the kind of cross-layer debugging Fable 5 handles well.

2. Complete the half-built squat UX

Several constants and UI paths exist but logic was never wired:

squatDepthThreshold (0.6) — declared, unused
outOfFramePenaltySeconds (15) + volumeRampStep — no penalty/volume ramp
RepFeedback.failure — UI shows "BAD FORM" but nothing ever sets it
Fable 5 task: Implement depth validation, bad-form detection, and out-of-frame penalty in SquatCounterService, active_alarm_screen.dart, and AlarmAudioService, then add unit tests for the pure counter logic.

3. Fix alarm cold-launch reconstruction bugs

When opened from a notification tap, the router rebuilds AlarmEntity with scheduledTime: DateTime.now() instead of the real schedule time. Notification ID collision risk exists when two alarms are within 1 second.

Fable 5 task: End-to-end fix across alarm_notification_service.dart, app_router.dart, and scheduling providers — with tests for ID generation and cold-start route payload.

4. Offline session sync queue

CompositeSessionRepository writes locally but silently drops remote failures — offline sessions never sync later.

Fable 5 task: Add a retry/queue layer (SharedPreferences-backed pending sessions), wire into sign-in and app resume, test offline→online flow.

Tier 2 — Strong fit (domain-heavy, many files)
5. Unit test suite for pure domain services

Untested but trivially testable:

SquatCounterService
RunValidationService
GpsKalmanFilter
RdpSimplifier
GeoUtils
Fable 5 task: Generate comprehensive unit tests + edge cases (partial poses, speed-cap violations, loop closure boundaries). Your existing E2E tests give it a verification harness.

6. Harden local territory geometry

TerritoryLocalRepositoryImpl has ~280 lines of hand-rolled polygon clip/steal logic that approximates PostGIS. Concave polygons and partial cuts can be wrong offline.

Fable 5 task: Audit geometry against server RPC behavior, fix edge cases, add property-based or fixture tests with known polygons.

7. Provider lifecycle cleanup

Global alarm state (repCountProvider, etc.) persists between sessions. Territory providers are non-autoDispose and keep network streams alive even when the tab isn’t visited (Geolocator starts at boot per your logs).

Fable 5 task: Refactor provider scoping, reset alarm session state on active-alarm entry, lazy-init GPS/map providers — run existing tests after each change.

8. Android 14+ exact alarm UX

Code calls requestExactAlarmsPermission() but has no guided flow when the user denies it — alarms may silently fail.

Fable 5 task: Add permission check, settings deep-link, and dashboard warning card.

Tier 3 — Good for a long autonomous session
9. iOS alarm parity

Darwin notifications use InterruptionLevel.timeSensitive, not critical. No UNNotificationCategory for alarm actions. iOS Do Not Disturb bypass is incomplete.

10. Startup jank reduction

main.dart does Supabase + timezone + notifications before runApp — logs show 33–114 skipped frames. Defer non-critical init, lazy-load territory map.

11. Riverpod codegen migration

riverpod_annotation is in pubspec.yaml but every provider is hand-written. Fable 5 can migrate providers file-by-file with build_runner verification.

12. Docs + CLAUDE.md sync

Router was refactored to StatefulShellRoute (/dashboard, /territory, /leaderboard) but CLAUDE.md still describes the old flat routes. Add root README.

13. Gradle/KGP plugin warnings

camera_android_camerax, flutter_timezone, wakelock_plus will break on future Flutter — upgrade deps and verify build.

What not to use Fable 5 for on Awaken
Use Sonnet/Composer instead	Why
Tweaking colors/typography
Simple, single-file
Adding a new alarm label string
No cross-file reasoning needed
One-off Supabase column tweak
Small scope
Reading docs / answering questions
Ask mode is enough
Reserve Fable 5 for tasks that touch 3+ files, need test verification, or require sustained debugging (camera pipeline, map tiles, polygon math, sync queues).

Suggested first Fable 5 session (copy-paste ready)
If you want one bounded work block to try it:

Goal: Fix vector_map_tiles CancellationException flood and add regression coverage.
Context: See flutter-run-logs.md lines 69+. Territory feature uses flutter_map + vector_map_tiles in lib/features/territory/presentation/screens/territory_run_screen.dart.
Done when: Hot restart and navigating to/from territory tab produce zero unhandled Cancelled exceptions; flutter analyze lib/ clean; existing test/territory/territory_e2e_test.dart still pass.

That’s a concrete, verifiable task where Fable 5’s multi-step debugging and self-checking should outperform faster/cheaper models.

Practical Cursor setup
Select Claude Fable 5 (High thinking for hardest tasks)
Accept data retention in Cursor Dashboard if prompted
Enable Max Mode if you’re on a legacy request-based plan
Give it the full task + done criteria — Fable 5 shines with bounded work blocks, not vague “improve the app”
If you tell me which area you want to tackle first (map bug, squat UX, tests, or sync), I can draft a tighter Fable 5 agent prompt scoped to that feature.

