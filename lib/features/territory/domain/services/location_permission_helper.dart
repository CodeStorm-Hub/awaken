import 'package:geolocator/geolocator.dart';

/// Why [LocationPermissionHelper.ensureLocationAccess] failed — drives
/// whether the UI should offer "Open settings" vs only "Retry".
enum LocationAccessKind {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

/// Thrown by [LocationPermissionHelper.ensureLocationAccess] with a
/// user-facing message when location can't be used yet.
class LocationAccessException implements Exception {
  const LocationAccessException(
    this.message, {
    this.kind = LocationAccessKind.permissionDenied,
  });

  final String message;
  final LocationAccessKind kind;

  bool get canOpenSettings =>
      kind == LocationAccessKind.serviceDisabled ||
      kind == LocationAccessKind.permissionDeniedForever;

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
      throw LocationAccessException(
        serviceDisabledMessage,
        kind: LocationAccessKind.serviceDisabled,
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationAccessException(
        permissionDeniedMessage,
        kind: LocationAccessKind.permissionDeniedForever,
      );
    }
    if (permission == LocationPermission.denied) {
      throw LocationAccessException(
        permissionDeniedMessage,
        kind: LocationAccessKind.permissionDenied,
      );
    }
  }

  /// Opens the OS screen that can resolve [kind] (location services or
  /// app permission settings).
  static Future<bool> openSettingsFor(LocationAccessKind kind) {
    return switch (kind) {
      LocationAccessKind.serviceDisabled => Geolocator.openLocationSettings(),
      LocationAccessKind.permissionDeniedForever ||
      LocationAccessKind.permissionDenied => Geolocator.openAppSettings(),
    };
  }
}
