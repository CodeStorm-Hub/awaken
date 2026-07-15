import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

/// Continuous device vibration while the alarm rings.
///
/// Independent of the notification's one-shot [vibrationPattern] (which only
/// fires once, when the notification is first posted) — this repeats for as
/// long as [ActiveAlarmScreen] is on screen, matching [AlarmAudioService]'s
/// start/stop lifecycle so the phone keeps buzzing alongside the alarm tone.
abstract final class AlarmVibrationService {
  static const _pattern = [0, 500, 200, 500, 200];

  static Future<void> start() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) {
        await Vibration.vibrate(pattern: _pattern, repeat: 0);
      }
    } catch (e) {
      debugPrint('[AlarmVibration] Failed to start: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      debugPrint('[AlarmVibration] Failed to stop: $e');
    }
  }
}
