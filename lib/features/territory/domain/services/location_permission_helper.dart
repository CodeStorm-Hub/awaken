import 'package:geolocator/geolocator.dart';

/// Thrown by [LocationPermissionHelper.ensureLocationAccess] with a
/// user-facing message when location can't be used yet.
class LocationAccessException implements Exception {
  const LocationAccessException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Centralizes the "is location usable right now" check that every screen
/// touching GPS needs to do *before* calling `Geolocator.getCurrentPosition`
/// / `getPositionStream`.
///
/// This matters because `Geolocator.getCurrentPosition()` does **not** itself
/// trigger the native OS permission dialog on Android — it just throws
/// `PermissionDeniedException` if permission hasn't already been granted.
/// Only an explicit `checkPermission()` → `requestPermission()` call shows
/// the prompt. Call sites that skip this (and only wrap the position call in
/// a bare `catch`) silently never ask the user for permission at all — which
/// is exactly what [ensureLocationAccess] exists to prevent.
abstract final class LocationPermissionHelper {
  /// Ensures location services are on and permission is granted, requesting
  /// permission (native OS dialog) if it hasn't been decided yet. Throws
  /// [LocationAccessException] with a message safe to show directly to the
  /// user if location isn't available for any reason.
  static Future<void> ensureLocationAccess({
    String serviceDisabledMessage = 'Turn on location services to continue.',
    String permissionDeniedMessage = 'Allow location access to continue.',
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationAccessException(serviceDisabledMessage);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw LocationAccessException(permissionDeniedMessage);
    }
  }
}
