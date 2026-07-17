import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Battery-optimization exemption checks and request for Android.
///
/// AlarmManager's `exactAllowWhileIdle` (used by [AlarmNotificationService])
/// covers Doze-mode deferral at the OS level, but aggressive OEM background
/// killers (MIUI, EMUI, ColorOS, One UI) can still terminate the app process
/// before a scheduled alarm fires regardless of AlarmManager settings. The
/// `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission lets the user exempt the
/// app from that battery optimization — this is a real-world reliability
/// requirement, not covered by any of the exact-alarm/full-screen-intent
/// permissions, and cannot be granted programmatically without user action.
abstract final class BatteryOptimizationService {
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Whether the app is already exempt from battery optimization.
  /// Always `true` on iOS / desktop.
  static Future<bool> isExempt() async {
    if (!isAndroid) return true;
    return Permission.ignoreBatteryOptimizations.isGranted;
  }

  /// Shows the system's "Allow app to ignore battery optimizations" dialog
  /// directly (unlike exact-alarm/full-screen-intent, Android surfaces this
  /// as an in-context confirmation dialog rather than a Settings deep-link).
  static Future<bool> request() async {
    if (!isAndroid) return true;
    final status = await Permission.ignoreBatteryOptimizations.request();
    return status.isGranted;
  }
}
