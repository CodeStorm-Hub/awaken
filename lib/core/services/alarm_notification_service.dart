import 'package:awaken/core/router/navigator_key.dart';
import 'package:awaken/features/alarm/domain/entities/alarm_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;

/// Fields parsed from an alarm notification payload (`id|reps|scheduledTime`).
@immutable
class AlarmNotificationPayload {
  const AlarmNotificationPayload({
    required this.id,
    required this.reps,
    required this.scheduledTime,
  });

  final String id;
  final int reps;
  final DateTime scheduledTime;
}

/// Manages alarm scheduling via flutter_local_notifications.
///
/// Must call [initialize] in main() before runApp().
/// Must call [requestPermissions] before scheduling the first alarm.
abstract final class AlarmNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'awaken_alarm';
  static const _channelName = 'Alarm';

  // ── Init ──────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onForegroundTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
    );

    // Android: create the alarm notification channel once
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Awaken wake-up alarm',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            ledColor: Color(0xFF4A9EFF),
          ),
        );
  }

  // ── Permissions ───────────────────────────────────────────────────

  static Future<void> requestPermissions() async {
    // iOS: request notification + critical alert
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
          critical: true,
        );

    // Android 13+: POST_NOTIFICATIONS runtime permission
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Android 12+: SCHEDULE_EXACT_ALARM
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  // ── Schedule / Cancel ─────────────────────────────────────────────

  static Future<void> scheduleAlarm(AlarmEntity alarm) async {
    final scheduledTz = tz.TZDateTime.from(alarm.scheduledTime, tz.local);
    final payload = buildPayload(alarm);

    await _plugin.zonedSchedule(
      _notifId(alarm),
      'Wake Up Tax Due!',
      'Complete ${alarm.requiredReps} squats to dismiss your alarm.',
      scheduledTz,
      _buildDetails(alarm.requiredReps),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('[Alarm] Scheduled id=${_notifId(alarm)} at ${alarm.scheduledTime}');
  }

  static Future<void> cancelAlarm(AlarmEntity alarm) async {
    await _plugin.cancel(_notifId(alarm));
    debugPrint('[Alarm] Cancelled id=${_notifId(alarm)}');
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // ── Launch-from-notification check ───────────────────────────────

  /// Call in main() to detect if the app was opened by tapping an alarm.
  /// Returns the route string to use as GoRouter's initialLocation.
  static Future<String> getInitialRoute() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      final payload = details?.notificationResponse?.payload;
      return _buildActiveRoute(payload);
    }
    return '/';
  }

  static String buildActiveRouteFromPayload(String? payload) {
    final parsed = parsePayload(payload);
    if (parsed == null) return '/alarm/active';

    final scheduled =
        Uri.encodeComponent(parsed.scheduledTime.toIso8601String());
    return '/alarm/active?id=${parsed.id}&reps=${parsed.reps}&scheduled=$scheduled';
  }

  /// Builds the notification payload: `id|reps|scheduledTime` (ISO8601).
  static String buildPayload(AlarmEntity alarm) =>
      '${alarm.id}|${alarm.requiredReps}|${alarm.scheduledTime.toIso8601String()}';

  /// Parses a notification payload. Returns null for missing or malformed input.
  static AlarmNotificationPayload? parsePayload(String? payload) {
    if (payload == null || !payload.contains('|')) return null;

    final parts = payload.split('|');
    if (parts.length < 2 || parts[0].isEmpty) return null;

    final reps = int.tryParse(parts[1]) ?? 10;
    final scheduledTime = parts.length >= 3 && parts[2].isNotEmpty
        ? DateTime.parse(parts[2])
        : DateTime.now();

    return AlarmNotificationPayload(
      id: parts[0],
      reps: reps,
      scheduledTime: scheduledTime,
    );
  }

  /// Stable notification ID derived from [AlarmEntity.id] (fits int32).
  @visibleForTesting
  static int notificationIdFor(AlarmEntity alarm) => _notifId(alarm);

  // ── Internal helpers ──────────────────────────────────────────────

  static int _notifId(AlarmEntity alarm) => alarm.id.hashCode & 0x7FFFFFFF;

  static String _buildActiveRoute(String? payload) =>
      buildActiveRouteFromPayload(payload);

  static NotificationDetails _buildDetails(int reps) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Awaken wake-up alarm',
        importance: Importance.max,
        priority: Priority.max,
        // Full-screen intent wakes the screen even from lock screen
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
        // Ongoing: can't be swiped away until reps are done
        ongoing: true,
        autoCancel: false,
        color: const Color(0xFF4A9EFF),
        ledColor: const Color(0xFF4A9EFF),
        ledOnMs: 500,
        ledOffMs: 500,
        actions: [
          const AndroidNotificationAction(
            'open',
            'Complete Squats',
            showsUserInterface: true,
          ),
        ],
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
        categoryIdentifier: 'ALARM_CATEGORY',
      ),
    );
  }

  static void _onForegroundTap(NotificationResponse response) {
    final ctx = navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      GoRouter.of(ctx).go(_buildActiveRoute(response.payload));
    }
  }
}

/// Top-level — required by flutter_local_notifications for background notification
/// tap callbacks that run in a separate Dart isolate. Navigation is not possible
/// here; the correct route is resolved via [AlarmNotificationService.getInitialRoute]
/// on the next cold start.
@pragma('vm:entry-point')
void _onBackgroundTap(NotificationResponse response) {
  debugPrint('[Alarm] Background tap: ${response.id}');
}
