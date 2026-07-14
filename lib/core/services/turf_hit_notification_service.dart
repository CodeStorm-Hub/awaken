import 'package:awaken/core/router/app_router.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

/// Shows a local notification when the current user's territory is hit by
/// a rival. Mirrors [TerritoryDecayNotificationService] in style.
abstract final class TurfHitNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'awaken_turf_hit';
  static const _channelName = 'Turf Defense';
  static const _notificationId = 9002;

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Alerts when a rival captures your territory',
            importance: Importance.high,
          ),
        );
  }

  static void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    if (payload == AppRoutes.territory || payload.startsWith('/territory')) {
      final ctx = navigatorKey.currentContext;
      if (ctx != null) GoRouter.of(ctx).go(AppRoutes.territory);
    }
  }

  /// Shows a turf-hit notification.
  /// [areaSqm] is the area of the captured zone in m² (informational).
  static Future<void> showTurfHit({required double areaSqm}) async {
    final body = areaSqm > 0
        ? 'You lost ${areaSqm.toStringAsFixed(0)} m² — reclaim within 24 h.'
        : 'Reclaim within 24 h.';

    await _plugin.show(
      id: _notificationId,
      title: 'TURF HIT',
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Alerts when a rival captures your territory',
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFFA259FF),
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true),
      ),
      payload: AppRoutes.territory,
    );
  }
}
