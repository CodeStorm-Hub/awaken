import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Acquires a usable GPS fix for map centering without requiring a run.
///
/// `getCurrentPosition` with a short medium-accuracy timeout often fails
/// indoors, on emulators, or when the OS is still warming the GNSS chip.
/// This helper tries last-known → coarse network → medium → stream first
/// event → Android LocationManager fallback, and returns the best result.
abstract final class LocationFixService {
  /// Returns a position suitable for centering the territory map, or `null`
  /// if nothing could be obtained within the overall budget.
  ///
  /// [onInterim] is invoked as soon as a last-known or early fix is available
  /// so the UI can hide the locating overlay while a fresher fix continues.
  static Future<Position?> acquireForMapCentering({
    void Function(Position position)? onInterim,
  }) async {
    final lastKnown = await Geolocator.getLastKnownPosition();
    if (lastKnown != null) {
      onInterim?.call(lastKnown);
    }

    final coarse = await _tryCurrentPosition(
      accuracy: LocationAccuracy.low,
      timeout: const Duration(seconds: 12),
    );
    if (coarse != null) return coarse;

    final medium = await _tryCurrentPosition(
      accuracy: LocationAccuracy.medium,
      timeout: const Duration(seconds: 12),
    );
    if (medium != null) return medium;

    // Emulators and some Android devices resolve faster through the
    // platform LocationManager than through the Fused provider.
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        return await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.low,
            forceLocationManager: true,
            timeLimit: const Duration(seconds: 10),
          ),
        );
      } catch (_) {
        // Exhausted strategies.
      }
    }

    return lastKnown;
  }

  static Future<Position?> _tryCurrentPosition({
    required LocationAccuracy accuracy,
    required Duration timeout,
  }) async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings(accuracy, timeLimit: timeout),
      ).timeout(timeout);
    } catch (_) {
      return null;
    }
  }

  static LocationSettings _locationSettings(
    LocationAccuracy accuracy, {
    Duration? timeLimit,
  }) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(accuracy: accuracy, timeLimit: timeLimit);
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(accuracy: accuracy, timeLimit: timeLimit);
    }
    return LocationSettings(accuracy: accuracy, timeLimit: timeLimit);
  }
}
