import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Android 12+ exact-alarm permission checks and settings deep-links.
///
/// Uses [AndroidFlutterLocalNotificationsPlugin.canScheduleExactNotifications]
/// as the primary signal (matches what [AlarmNotificationService] needs for
/// `AndroidScheduleMode.exactAllowWhileIdle`), with [Permission.scheduleExactAlarm]
/// as a fallback via permission_handler.
abstract final class ExactAlarmPermissionService {
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Whether exact alarms can be scheduled. Always `true` on iOS / desktop.
  static Future<bool> isGranted() async {
    if (!isAndroid) return true;

    final androidPlugin = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final canSchedule = await androidPlugin?.canScheduleExactNotifications();
    if (canSchedule != null) return canSchedule;

    return Permission.scheduleExactAlarm.isGranted;
  }

  /// Opens the per-app "Alarms & reminders" settings screen on Android 12+.
  static Future<void> openSettings() async {
    if (!isAndroid) return;

    final androidPlugin = FlutterLocalNotificationsPlugin()
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestExactAlarmsPermission();
  }

  /// Prompts the user via the platform settings UI, then re-checks status.
  static Future<bool> request() async {
    if (!isAndroid) return true;

    await openSettings();
    return isGranted();
  }
}
