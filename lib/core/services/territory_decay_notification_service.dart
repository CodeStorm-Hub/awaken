import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Surfaces territory decay warnings as local notifications, reusing
/// flutter_local_notifications (already wired for alarms) rather than
/// building a separate push-notification path — per Product Decision #4
/// in the implementation plan.
abstract final class TerritoryDecayNotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'awaken_territory_decay';
  static const _channelName = 'Territory Decay Warnings';
  static const _notificationId = 9001;

  static Future<void> initialize() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Warns when your territory is about to start decaying',
            importance: Importance.defaultImportance,
          ),
        );
  }

  /// Shows a single grouped notification listing every territory the
  /// current user owns that's within the decay grace period. Re-showing on
  /// every app open with the same [_notificationId] simply replaces the
  /// prior notification rather than stacking duplicates.
  static bool _hasNotifiedThisSession = false;

  static Future<void> notifyIfDecaying({required int territoryCount}) async {
    if (territoryCount <= 0 || _hasNotifiedThisSession) return;
    _hasNotifiedThisSession = true;

    final body = territoryCount == 1
        ? 'One of your territories is decaying — run there soon to defend it.'
        : '$territoryCount of your territories are decaying — run there soon to defend them.';

    await _plugin.show(
      id: _notificationId,
      title: 'Territory at risk',
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription:
              'Warns when your territory is about to start decaying',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          color: Color(0xFFA259FF),
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true),
      ),
    );
  }
}
