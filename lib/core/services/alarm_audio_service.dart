import 'dart:io';

import 'package:awaken/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Plays and stops the in-app alarm sound during an active alarm session.
///
/// On Android, falls back to the system alarm ringtone when the bundled asset
/// is absent. On iOS, silence occurs if `assets/audio/alarm.mp3` is missing —
/// see the README in that directory.
abstract final class AlarmAudioService {
  static AudioPlayer? _player;
  static double _baseVolume = 1.0;
  static double _currentVolume = 1.0;

  static Future<void> start() async {
    try {
      _player = AudioPlayer();
      await _player!.setLoopMode(LoopMode.all);
      _baseVolume = 1.0;
      _currentVolume = _baseVolume;
      await _player!.setVolume(_currentVolume);

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
      _currentVolume = _baseVolume;
    } catch (e) {
      debugPrint('[AlarmAudio] Failed to stop: $e');
    }
  }

  static Future<void> setVolume(double volume) async {
    _currentVolume = volume.clamp(0.0, 1.0);
    try {
      await _player?.setVolume(_currentVolume);
    } catch (e) {
      debugPrint('[AlarmAudio] Failed to set volume: $e');
    }
  }

  static Future<void> rampVolumeUp() async {
    await setVolume(_currentVolume + AppConstants.volumeRampStep);
  }

  static Future<void> resetVolume() async {
    await setVolume(_baseVolume);
  }

  static bool get isPlaying => _player?.playing ?? false;
  static double get currentVolume => _currentVolume;
}
