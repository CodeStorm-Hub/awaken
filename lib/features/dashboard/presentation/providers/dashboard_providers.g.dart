// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$exactAlarmPermissionHash() =>
    r'3d0d9390fb66d7ba0d36ac85a57308992af80bd1';

/// Android exact-alarm permission state.
///
/// `null` when not applicable (iOS / desktop). `false` when Android and the
/// user has denied "Alarms & reminders" — alarms may not fire on time.
///
/// Copied from [exactAlarmPermission].
@ProviderFor(exactAlarmPermission)
final exactAlarmPermissionProvider = FutureProvider<bool?>.internal(
  exactAlarmPermission,
  name: r'exactAlarmPermissionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$exactAlarmPermissionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExactAlarmPermissionRef = FutureProviderRef<bool?>;
String _$clockHash() => r'37cd9243c72070a24dec2c81c9280f6c40c9a2ca';

/// Ticking clock — emits a new DateTime every second.
///
/// Copied from [clock].
@ProviderFor(clock)
final clockProvider = StreamProvider<DateTime>.internal(
  clock,
  name: r'clockProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$clockHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ClockRef = StreamProviderRef<DateTime>;
String _$clockDisplayHash() => r'febf263dbf56b94534a548c349bd1b69e4c50f9e';

/// Formatted clock string — only emits when the displayed HH:MM value changes
/// (once per minute). Downstream widgets that render the clock should watch
/// this, not [clockProvider], to avoid rebuilding every second.
///
/// Copied from [clockDisplay].
@ProviderFor(clockDisplay)
final clockDisplayProvider = StreamProvider<String>.internal(
  clockDisplay,
  name: r'clockDisplayProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$clockDisplayHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ClockDisplayRef = StreamProviderRef<String>;
String _$dashboardStatsHash() => r'dc456fb67b9a01bc7f00b915dcc419a8e3913fdb';

/// Dashboard stats — cloud when signed in, local SharedPreferences when guest.
///
/// Copied from [dashboardStats].
@ProviderFor(dashboardStats)
final dashboardStatsProvider = FutureProvider<DashboardStatsEntity>.internal(
  dashboardStats,
  name: r'dashboardStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$dashboardStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DashboardStatsRef = FutureProviderRef<DashboardStatsEntity>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
