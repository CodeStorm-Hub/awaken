import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:awaken/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Plays and stops the in-app alarm sound during an active alarm session.
///
/// The audio session is configured with `AndroidAudioUsage.alarm` so the
/// sound plays on Android's dedicated ALARM stream — independent of the
/// media volume slider, which users routinely leave at zero overnight.
/// On iOS the `.playback` category lets the alarm sound through the
/// ring/silent switch.
///
/// On Android, falls back to the system alarm ringtone when the bundled asset
/// is absent. On iOS, silence occurs if `assets/audio/alarm.mp3` is missing —
/// see the README in that directory.
abstract final class AlarmAudioService {
  static AudioPlayer? _player;
  static double _baseVolume = 1.0;
  static double _currentVolume = 1.0;

  /// Monotonic token so a `stop()` that races an in-flight `start()` wins:
  /// the stale `start()` notices the generation moved on and disposes its
  /// own player instead of publishing it.
  static int _generation = 0;
  static bool _sessionConfigured = false;

  static Future<void> _configureSession() async {
    if (_sessionConfigured) return;
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        androidAudioAttributes: AndroidAudioAttributes(
          usage: AndroidAudioUsage.alarm,
          contentType: AndroidAudioContentType.sonification,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gainTransient,
        androidWillPauseWhenDucked: false,
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
      ),
    );
    _sessionConfigured = true;
  }

  static Future<void> start() async {
    final generation = ++_generation;
    try {
      await _configureSession();
      if (generation != _generation) return;

      // Build on a local instance; only publish once fully set up so a
      // concurrent stop() can't dispose a half-initialized player.
      final player = AudioPlayer();
      try {
        await player.setLoopMode(LoopMode.all);
        _baseVolume = 1.0;
        _currentVolume = _baseVolume;
        await player.setVolume(_currentVolume);

        if (Platform.isAndroid) {
          // Try bundled asset first; fall back to system alarm URI
          try {
            await player.setAudioSource(
              AudioSource.asset('assets/audio/alarm.mp3'),
            );
          } catch (_) {
            await player.setAudioSource(
              AudioSource.uri(
                Uri.parse('content://settings/system/alarm_alert'),
              ),
            );
          }
        } else {
          // iOS / macOS — requires assets/audio/alarm.mp3 to be bundled
          await player.setAudioSource(
            AudioSource.asset('assets/audio/alarm.mp3'),
          );
        }

        if (generation != _generation) {
          // stop() ran while we were setting up — discard quietly.
          await player.dispose();
          return;
        }

        _player = player;
        await player.play();
      } catch (e) {
        await player.dispose();
        rethrow;
      }
    } catch (e) {
      debugPrint('[AlarmAudio] Failed to start: $e');
    }
  }

  static Future<void> stop() async {
    _generation++;
    final player = _player;
    _player = null;
    _currentVolume = _baseVolume;
    if (player == null) return;
    try {
      await player.stop();
      await player.dispose();
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
