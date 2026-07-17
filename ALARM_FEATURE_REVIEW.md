# Alarm Feature Review — `alarm.md` Guide vs. Current Codebase

Date: 2026-07-17 (updated same day — fixes applied)

## Status: fixes implemented

The gaps identified below were reviewed against the codebase and acted on:

| Finding | Action taken |
|---|---|
| No battery-optimization exemption flow | **Fixed.** Added `BatteryOptimizationService` (`lib/core/services/battery_optimization_service.dart`), a `batteryOptimizationExemptProvider` (mirrors the existing `exactAlarmPermissionProvider`), a dismissible dashboard warning card (`_BatteryOptimizationWarningCard`), and the `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` manifest permission. |
| `targetSdk`/`compileSdk` readiness for Aug 31, 2026 API-36 deadline | **Verified, no change needed.** The installed Flutter SDK (3.44.4) already defaults `compileSdk`/`targetSdk` to 36 and `minSdk` to 24 (`flutter.gradle`'s `FlutterExtension`). These are intentionally left unpinned in `build.gradle.kts` so they keep tracking Flutter's own recommended values on every Flutter upgrade — pinning them would be a regression, not an improvement. |
| `applicationId` still `com.example.awaken` | **Not changed — flagged only.** This is tied to `google-services.json` (Firebase project `awaken-27f39`, OAuth client cert hashes for Google Sign-In) and changing it requires registering a new Firebase Android app + downloading a new config file + re-registering signing cert hashes. Out of scope for an "alarm permissions" pass and risks breaking Firebase/Google Sign-In if done without the matching Firebase Console changes — flagging for a deliberate, separate task. |
| `alarm.md` describes a different (unused) package | **Not changed** — left as-is per this review; use this document as the actual-implementation reference instead. |

### Separately reported bug: alarm scheduled a day late

While testing, the user reported: setting an alarm ~1 minute in the future scheduled it for **tomorrow** instead of today (log showed `Scheduled id=882456533 at 2026-07-18 06:41:00.000` when set at `2026-07-17 06:40`). Root cause found and fixed:

`alarm_setup_screen.dart`'s save path computed "next occurrence" as `scheduled.isBefore(now.add(Duration(minutes: 1)))` — comparing against `now + 1 minute` instead of `now`. Since `TimeOfDay` has no seconds, `scheduled` always lands on `:00` seconds while `now` carries its own seconds, so `scheduled` was almost always "before" that inflated threshold — pushing the alarm a full day ahead even when the picked time was still clearly in the future. This diverged from the screen's own "Rings in Xh Ym" countdown label, which used the correct `!scheduled.isAfter(now)` check — the UI's countdown was right, but the actual scheduled alarm was wrong.

**Fix:** extracted the correct logic into one shared, tested function, `nextAlarmOccurrence(TimeOfDay, DateTime)` (`lib/features/alarm/domain/services/next_alarm_occurrence.dart`), used by both the countdown label and the save path, so they can no longer drift apart. Added regression tests (`test/alarm/next_alarm_occurrence_test.dart`) covering the exact reported scenario. Confirmed this is not a missing "date picker" feature — the stock Android Clock app also has no date field on its time picker; it schedules the next occurrence of the picked time the same way, which is the correct, expected UX Awaken already had before this bug.

## TL;DR (original findings)

`alarm.md` describes a *generic* approach (the third-party [`alarm`](https://pub.dev/packages/alarm) package). **Awaken does not use it and shouldn't** — the app already has a more capable, purpose-built implementation on top of `flutter_local_notifications: ^22.0.1`, with correct Android 13/14+ exact-alarm and full-screen-intent handling that the `alarm` package doesn't fully cover (e.g. graceful fallback to inexact scheduling, ongoing/non-dismissible alarm notification, cloud/local repository swap). The guide is a reasonable *intro tutorial* but is behind current Android platform requirements in a few places. Below is a point-by-point comparison, a list of real gaps worth fixing, and a summary of current (mid-2026) Android alarm best practices from official docs and package changelogs.

---

## 1. Package choice

| | `alarm.md` guide | Current codebase |
|---|---|---|
| Package | `alarm: ^5.2.1` (third-party, native-code-heavy plugin) | `flutter_local_notifications: ^22.0.1` + `timezone`/`flutter_timezone` + `just_audio`/`audio_session` + `wakelock_plus` + `vibration` (composed manually) |

**Assessment:** the composed approach is the right call for this app. `alarm` bundles audio/vibration/volume into one opaque native plugin — fine for a plain alarm clock, but Awaken needs the ring flow to hand off into a live camera + ML Kit pose-detection screen (`ActiveAlarmScreen` → `AlarmPosePipeline`), which requires full control over navigation-on-tap, notification payload parsing, and independent audio/vibration lifecycles. The current `AlarmNotificationService` (`lib/core/services/alarm_notification_service.dart`) gives you that; the `alarm` package's single `AlarmSettings` model would fight the pose-verification requirement. No action needed here — worth noting in `alarm.md` itself if it's meant to guide future contributors, since as written it would suggest ripping out working, more correct code.

## 2. Permissions

Current `AndroidManifest.xml` (`android/app/src/main/AndroidManifest.xml:12-32`) declares:

```xml
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
```

This is **already broader and more correct** than `alarm.md`'s list (§2), which only has `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `POST_NOTIFICATIONS`. The guide is missing `RECEIVE_BOOT_COMPLETED` (needed to re-arm alarms after reboot) and `USE_FULL_SCREEN_INTENT`, both of which Awaken already has and both of which are **required in practice** for a reliable alarm app.

`showWhenLocked`/`turnScreenOn` (guide §2) are present both at `<application>` and `<activity>` level in Awaken's manifest — correct, matches guide.

### Gap: Android 16 `USE_FULL_SCREEN_INTENT` re-justification
Since **Android 16 (API 36)**, apps must explicitly request/justify `USE_FULL_SCREEN_INTENT` at install — Google restricts it to calling and alarm apps. Awaken already declares the permission and the runtime `requestFullScreenIntentPermission()` call, so functionally it's fine, but note that **Google Play requires all app updates to target API 36 by August 31, 2026** — confirm `flutter.compileSdkVersion`/`targetSdkVersion` (currently inherited from the Flutter SDK's Gradle defaults in `android/app/build.gradle.kts:10,25`, not pinned) will resolve to 36 by then, and re-verify the Play Console's "core permissions declaration" for full-screen intent isn't required as a separate form for this app category.

### Gap: no battery-optimization / Doze exemption flow
Neither the guide nor the codebase requests `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` or points users at manufacturer-specific "autostart"/battery settings (Xiaomi, Huawei, Oppo/Realme, Samsung). `AndroidScheduleMode.exactAllowWhileIdle` (used correctly in `alarm_notification_service.dart:143`) covers Doze mode's alarm-manager exemption, but aggressive OEM task killers on MIUI/EMUI/ColorOS can still kill the process before the alarm fires, especially on Android 16's stricter Doze. Given this is a fitness *alarm* app where a missed wake-up is the core failure mode, consider:
- A one-time onboarding prompt directing users to disable battery optimization for the app (`Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` via `permission_handler`'s `Permission.ignoreBatteryOptimizations` or a small platform channel).
- Optionally, OEM-specific deep links (e.g. via a package like `disable_battery_optimization`) with a "why this matters" explainer, since users conflate this with unrelated permissions.

## 3. Initialization

`alarm.md` §3 calls `Alarm.init()` before `runApp()`. Awaken's `main.dart` equivalent is `AlarmNotificationService.initialize()`, which additionally creates the Android notification channel up front (`_channelId = 'awaken_alarm_v2'`, `Importance.max`, `AudioAttributesUsage.alarm`, custom vibration pattern, LED color) — this is more correct than the guide, which doesn't mention notification channels at all despite channel importance/sound being **locked at first creation** on Android 8+ (a subtlety the code correctly comments on, `alarm_notification_service.dart:31-34`). Good — no changes needed.

## 4. Scheduling

The guide's `AlarmSettings`/`Alarm.set()` (§4) is a one-shot API with no visible fallback if the platform declines exact scheduling. Awaken's `scheduleAlarm()` (`alarm_notification_service.dart:123-163`) explicitly checks `canScheduleExactNotifications()` first and falls back to `AndroidScheduleMode.inexactAllowWhileIdle` rather than letting a `SecurityException` propagate — this matches the *current* official Android guidance (an app must handle the user declining exact-alarm access gracefully, not treat it as fatal). This is better than what the guide shows and should be preserved.

One thing to double check: `AlarmList.addAlarm`/`toggleAlarm` (`alarm_schedule_providers.dart:58-125`) schedule with the OS **before** persisting the alarm as active, and roll back to `isActive: false` on failure — this is the correct order (avoids a "ghost" alarm that's marked active but never registered), and is explicitly called out in the code comments. Keep this pattern for any new alarm-mutation code paths.

## 5. Runtime permissions

The guide's `PermissionService` (§5) only requests `Permission.notification` and conditionally `Permission.scheduleExactAlarm`. Awaken's `requestPermissions()` (`alarm_notification_service.dart:82-119`) additionally requests:
- iOS critical alerts (not relevant today since iOS is deferred, but harmless)
- `requestNotificationsPermission()` (Android 13+)
- `requestExactAlarmsPermission()` (Android 12+)
- `requestFullScreenIntentPermission()` — **this one is missing from the guide entirely**, and is required on Android 14+ / some OEM skins for the full-screen alarm activity to actually launch over the lock screen (without it, the sound/vibration fire but the pose-verification screen never appears — silently defeating the entire "wake up tax" mechanic).

This is a meaningful correctness gap in `alarm.md` relative to what Awaken already does right.

## 6. Camera-verified squat check integration

Not covered by `alarm.md` at all (out of scope for a generic guide), but worth documenting since it's Awaken's differentiator: notification tap → `_onForegroundTap`/`_onBackgroundTap` → GoRouter navigates to `/alarm/active?...` → `ActiveAlarmScreen` (`lib/features/alarm/presentation/screens/active_alarm_screen.dart`) starts the camera + `AlarmPosePipeline` + `ExerciseCounterRouter`, holds `wakelock_plus` and a foreground-service-backed audio loop (`just_audio`/`audio_session` on the ALARM stream), and only lets the user dismiss once the rep target is met (or via the 10-second emergency-hold bailout for accessibility). The notification itself is `ongoing: true` / `autoCancel: false` so it can't be swiped away pre-completion. This matches `.claude/rules/pose-detection.md`'s dispose-order and accessibility-fallback rules.

## 7. Boot persistence

`alarm.md` doesn't mention reboot handling at all. Awaken correctly registers `flutter_local_notifications`' `ScheduledNotificationBootReceiver` for `BOOT_COMPLETED` / `MY_PACKAGE_REPLACED` / `QUICKBOOT_POWERON` (manifest lines 65-74) and re-syncs all active alarms to the OS scheduler on app load (`AlarmList.build()`, `alarm_schedule_providers.dart:36-53`), deactivating any that fail to re-register rather than leaving a phantom "active" alarm. This is a stronger guarantee than the guide provides and is worth keeping as-is.

---

## 8. Current (2026) Android alarm best practices — external research summary

Sources: [Android Developers — exact alarms](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms), [Android Developers — schedule alarms](https://developer.android.com/develop/background-work/services/alarms), [AOSP — full-screen intent limits](https://source.android.com/docs/core/permissions/fsi-limits), [droidcon — FSI changes in Android 14/15](https://www.droidcon.com/2025/09/02/%F0%9F%9A%A8-full-screen-intent-fsi-notifications-in-android-14-15-what-changed-why-its-breaking-and-how-to-fix-it/), [Stora — API 36 deadline](https://stora.sh/blog/2026-04-14-android-api-36-august-deadline-what-to-do-now), [flutter_local_notifications changelog/pub.dev](https://pub.dev/packages/flutter_local_notifications), [alarm package/pub.dev](https://pub.dev/packages/alarm).

- **`SCHEDULE_EXACT_ALARM` is denied by default** on Android 13+ for newly-installed apps; alarm-clock-category apps should additionally declare **`USE_EXACT_ALARM`**, which is auto-granted without a user prompt but is subject to Play Store policy review/auditing for the "alarm clock" app category — Awaken already declares both, which is correct.
- **`setAlarmClock()`-equivalent semantics** (i.e. `exactAllowWhileIdle` + a lock-screen-visible notification) are the most Doze-resistant option available to non-native code; true `AlarmManager.setAlarmClock()` isn't exposed by `flutter_local_notifications`, so the current exact/inexact fallback is the correct approximation from Flutter.
- **Android 16 (API 36) tightens `USE_FULL_SCREEN_INTENT`** further — restricted to calling + alarm apps, and Google Play requires all app submissions/updates target API 36 by **August 31, 2026**. Action item: confirm the Flutter/Gradle-resolved `targetSdk`/`compileSdk` will be 36 well before that date, and test full-screen intent + lock-screen launch specifically on an Android 16 device/emulator, since FSI delivery behavior changed meaningfully between 14 → 15 → 16 (some OEMs now silently downgrade FSI to a heads-up notification if the app was backgrounded too long).
- **Battery optimization / Doze / OEM autostart remains the #1 real-world alarm-reliability killer** in the wild (Xiaomi/Huawei/Oppo especially) — not solved by any Android API alone; the standard mitigation is an in-app education screen prompting users to exempt the app, which Awaken does not yet have.
- **Notification channel settings are immutable after first creation** per channel ID on a given install — Awaken already handles this correctly by having versioned its channel ID (`awaken_alarm_v2`) when tuning sound/vibration, which is the documented workaround.
- Timezone-safe scheduling (`tz.TZDateTime` + the `timezone` package, with `flutter_timezone` for the device's IANA zone) is best practice for avoiding DST off-by-one-hour bugs — already in place (`alarm_notification_service.dart:8,124`).

---

Also worth noting: exact-alarm permission has its own dedicated helper, `lib/core/services/exact_alarm_permission_service.dart` (`ExactAlarmPermissionService`), which checks `canScheduleExactNotifications()` first and falls back to `Permission.scheduleExactAlarm.isGranted` via `permission_handler`, exposing `openSettings()`/`request()` — Android has no direct programmatic grant for this permission, only a deep link to the Alarms & Reminders settings page, which this service correctly surfaces.

## 9. Architecture note: no dedicated native ringing activity

`MainActivity` is the unmodified Flutter template (`FlutterActivity()`, no overrides). Unlike the `alarm` package — which ships its own native full-screen ringing Activity and isolate-safe callback model — Awaken's ringing UI is the same single Flutter `MainActivity`, reached via the full-screen-intent notification launching/foregrounding it and then GoRouter navigating to `/alarm/active`. A background-tap can't navigate directly (separate isolate), so it stashes the target route in `SharedPreferences` and resolves it on the next cold start/resume (`_onBackgroundTap` → `stashPendingRoute` → `getInitialRoute` in `main.dart`). This works today but is more moving parts than a dedicated native alarm Activity would need — worth keeping in mind if full-screen-intent launch reliability ever regresses on a specific OEM skin, since the failure mode is silent (sound/vibration fire, but the pose-verification screen never appears).

## 10. Recommended follow-ups (priority order)

1. **Add a battery-optimization-exemption onboarding step** (biggest real-world reliability gap, no code for it today, on either the current implementation or the `alarm.md`-proposed one).
2. **Pin/verify `targetSdk`/`compileSdk` = 36** ahead of the Aug 31, 2026 Play deadline and re-test full-screen intent behavior on an Android 16 image. Currently both are unpinned (`flutter.compileSdkVersion`/`flutter.targetSdkVersion`, inherited from the installed Flutter SDK's own Gradle defaults) rather than fixed in `android/app/build.gradle.kts`.
3. **Set a real `applicationId`** — it's still the Flutter template default (`com.example.awaken`, matching the Kotlin package `com.example.awaken`) which will block a genuine Play Store release. Unrelated to the alarm mechanism itself, but noticed while auditing the same files.
4. Treat `alarm.md` itself as outdated for this project — either delete it or add a header note pointing to `AlarmNotificationService` as the actual implementation, so it doesn't mislead a future contributor into "migrating" to the `alarm` package and regressing the pose-verification flow, missing full-screen-intent permission request, or losing the exact/inexact fallback.
