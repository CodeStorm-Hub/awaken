import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android 14+ (API 34) full-screen-intent permission checks and settings
/// deep-link. `USE_FULL_SCREEN_INTENT` in the manifest is no longer enough on
/// its own — without this granted, ActiveAlarmScreen's `fullScreenIntent`
/// notification (`alarm_notification_service.dart`) plays its sound/vibration
/// but never launches over the lock screen. OEM skins (Samsung One UI in
/// particular) enforce the same restriction even on Android 13.
abstract final class FullScreenIntentPermissionService {
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Requests the permission, prompting via system Settings if not already
  /// granted. Also usable as a read-only check: if already granted (or on an
  /// OS version that doesn't gate this), the plugin completes immediately
  /// without showing any UI.
  static Future<bool> request() async {
    if (!isAndroid) return true;

    final androidPlugin = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    return await androidPlugin?.requestFullScreenIntentPermission() ?? true;
  }
}
