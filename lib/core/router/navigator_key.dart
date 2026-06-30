import 'package:flutter/material.dart';

/// Global navigator key shared by [appRouterProvider] and
/// [AlarmNotificationService] so notification callbacks can navigate outside
/// the widget tree without a circular import.
final navigatorKey = GlobalKey<NavigatorState>();
