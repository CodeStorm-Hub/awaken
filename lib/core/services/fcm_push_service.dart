import 'dart:async';
import 'dart:io';

import 'package:awaken/core/constants/firebase_options.dart';
import 'package:awaken/core/router/app_router.dart';
import 'package:awaken/core/services/push_token_service.dart';
import 'package:awaken/core/services/turf_hit_notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Background FCM handler — must be a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on Object catch (_) {
    // Already initialized or unavailable.
  }
}

/// Initializes Firebase + FCM, registers the device token, and routes turf-hit
/// taps to `/territory`. Degrades gracefully when Firebase isn't configured
/// (e.g. iOS without plist, or widget tests).
abstract final class FcmPushService {
  static bool _ready = false;

  static bool get isReady => _ready;

  static Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);

      if (Platform.isIOS) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);
      final initial = await messaging.getInitialMessage();
      if (initial != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigateFromMessage(initial);
        });
      }

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await PushTokenService.registerToken(token);
      }
      messaging.onTokenRefresh.listen(PushTokenService.registerToken);

      _ready = true;
    } on Object catch (e) {
      debugPrint('[FcmPushService] init skipped: $e');
      _ready = false;
    }
  }

  static void _onForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final type = data['type'] as String?;
    if (type == 'turf_hit') {
      final area = double.tryParse('${data['area_sqm'] ?? ''}') ?? 0;
      unawaited(TurfHitNotificationService.showTurfHit(areaSqm: area));
      return;
    }
    final title = message.notification?.title;
    if (title != null && title.toUpperCase().contains('TURF')) {
      unawaited(TurfHitNotificationService.showTurfHit(areaSqm: 0));
    }
  }

  static void _onOpened(RemoteMessage message) => _navigateFromMessage(message);

  static void _navigateFromMessage(RemoteMessage message) {
    final route = message.data['route'] as String? ?? AppRoutes.territory;
    _go(route);
  }

  /// Handles local-notification payload taps (e.g. `/territory`).
  static void handleLocalPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    if (payload == AppRoutes.territory || payload.startsWith('/territory')) {
      _go(AppRoutes.territory);
    }
  }

  static void _go(String route) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    GoRouter.of(ctx).go(route);
  }
}
