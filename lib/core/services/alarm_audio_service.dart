import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Plays and stops the in-app alarm sound during an active alarm session.
///
/// On Android, falls back to the system alarm ringtone when the bundled asset
/// is absent. On iOS, silence occurs if `assets/audio/alarm.mp3` is missing —
/// see the README in that directory.
abstract final class AlarmAudioService {
  static AudioPlayer? _player;

  static Future<void> start() async {
    try {
      _player = AudioPlayer();
      await _player!.setLoopMode(LoopMode.all);
      await _player!.setVolume(1.0);

      if (Platform.isAndroid) {
        // Try bundled asset first; fall back to system alarm URI
        try {
          await _player!.setAudioSource(
            AudioSource.asset('assets/audio/alarm.mp3'),
          );
        } catch (_) {
          await _player!.setAudioSource(
            AudioSource.uri(Uri.parse('content://settings/system/alarm_alert')),
          );
        }
      } else {
        // iOS / macOS — requires assets/audio/alarm.mp3 to be bundled
        await _player!.setAudioSource(
          AudioSource.asset('assets/audio/alarm.mp3'),
        );
      }

      await _player!.play();
    } catch (e) {
      debugPrint('[AlarmAudio] Failed to start: $e');
    }
  }

  static Future<void> stop() async {
    try {
      await _player?.stop();
      _player?.dispose();
      _player = null;
    } catch (e) {
      debugPrint('[AlarmAudio] Failed to stop: $e');
    }
  }

  static bool get isPlaying => _player?.playing ?? false;
}
