import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the screen awake during an active alarm session.
abstract final class WakeLockService {
  static Future<void> enable() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('[WakeLock] enable failed: $e');
    }
  }

  static Future<void> disable() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {
      debugPrint('[WakeLock] disable failed: $e');
    }
  }
}
