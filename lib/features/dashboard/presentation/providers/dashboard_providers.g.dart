// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Android exact-alarm permission state.
///
/// `null` when not applicable (iOS / desktop). `false` when Android and the
/// user has denied "Alarms & reminders" — alarms may not fire on time.

@ProviderFor(exactAlarmPermission)
final exactAlarmPermissionProvider = ExactAlarmPermissionProvider._();

/// Android exact-alarm permission state.
///
/// `null` when not applicable (iOS / desktop). `false` when Android and the
/// user has denied "Alarms & reminders" — alarms may not fire on time.

final class ExactAlarmPermissionProvider
    extends $FunctionalProvider<AsyncValue<bool?>, bool?, FutureOr<bool?>>
    with $FutureModifier<bool?>, $FutureProvider<bool?> {
  /// Android exact-alarm permission state.
  ///
  /// `null` when not applicable (iOS / desktop). `false` when Android and the
  /// user has denied "Alarms & reminders" — alarms may not fire on time.
  ExactAlarmPermissionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exactAlarmPermissionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exactAlarmPermissionHash();

  @$internal
  @override
  $FutureProviderElement<bool?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool?> create(Ref ref) {
    return exactAlarmPermission(ref);
  }
}

String _$exactAlarmPermissionHash() =>
    r'20137c1f310188110d4efd7f50e95ae6f06cfe68';

/// Android battery-optimization exemption state.
///
/// `null` when not applicable (iOS / desktop). `false` when Android and the
/// app is still subject to battery optimization — OEM background killers
/// (MIUI/EMUI/ColorOS/One UI) may terminate the app before a scheduled alarm
/// fires even with exact-alarm permission granted.

@ProviderFor(batteryOptimizationExempt)
final batteryOptimizationExemptProvider = BatteryOptimizationExemptProvider._();

/// Android battery-optimization exemption state.
///
/// `null` when not applicable (iOS / desktop). `false` when Android and the
/// app is still subject to battery optimization — OEM background killers
/// (MIUI/EMUI/ColorOS/One UI) may terminate the app before a scheduled alarm
/// fires even with exact-alarm permission granted.

final class BatteryOptimizationExemptProvider
    extends $FunctionalProvider<AsyncValue<bool?>, bool?, FutureOr<bool?>>
    with $FutureModifier<bool?>, $FutureProvider<bool?> {
  /// Android battery-optimization exemption state.
  ///
  /// `null` when not applicable (iOS / desktop). `false` when Android and the
  /// app is still subject to battery optimization — OEM background killers
  /// (MIUI/EMUI/ColorOS/One UI) may terminate the app before a scheduled alarm
  /// fires even with exact-alarm permission granted.
  BatteryOptimizationExemptProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'batteryOptimizationExemptProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$batteryOptimizationExemptHash();

  @$internal
  @override
  $FutureProviderElement<bool?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool?> create(Ref ref) {
    return batteryOptimizationExempt(ref);
  }
}

String _$batteryOptimizationExemptHash() =>
    r'7ba819e31547056b891d507074e90f20b5c73f53';

/// Ticking clock — emits a new DateTime every second.

@ProviderFor(clock)
final clockProvider = ClockProvider._();

/// Ticking clock — emits a new DateTime every second.

final class ClockProvider
    extends
        $FunctionalProvider<AsyncValue<DateTime>, DateTime, Stream<DateTime>>
    with $FutureModifier<DateTime>, $StreamProvider<DateTime> {
  /// Ticking clock — emits a new DateTime every second.
  ClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockHash();

  @$internal
  @override
  $StreamProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<DateTime> create(Ref ref) {
    return clock(ref);
  }
}

String _$clockHash() => r'99d892c98e0eb6b5c760bc23e73ff09184cfd465';

/// Formatted clock string — only emits when the displayed HH:MM value changes
/// (once per minute). Downstream widgets that render the clock should watch
/// this, not [clockProvider], to avoid rebuilding every second.

@ProviderFor(clockDisplay)
final clockDisplayProvider = ClockDisplayProvider._();

/// Formatted clock string — only emits when the displayed HH:MM value changes
/// (once per minute). Downstream widgets that render the clock should watch
/// this, not [clockProvider], to avoid rebuilding every second.

final class ClockDisplayProvider
    extends $FunctionalProvider<AsyncValue<String>, String, Stream<String>>
    with $FutureModifier<String>, $StreamProvider<String> {
  /// Formatted clock string — only emits when the displayed HH:MM value changes
  /// (once per minute). Downstream widgets that render the clock should watch
  /// this, not [clockProvider], to avoid rebuilding every second.
  ClockDisplayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clockDisplayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clockDisplayHash();

  @$internal
  @override
  $StreamProviderElement<String> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String> create(Ref ref) {
    return clockDisplay(ref);
  }
}

String _$clockDisplayHash() => r'606af519aed70225f9d5483ac9a7ed3f01cac92d';

/// Dashboard stats — cloud when signed in, local SharedPreferences when guest.

@ProviderFor(dashboardStats)
final dashboardStatsProvider = DashboardStatsProvider._();

/// Dashboard stats — cloud when signed in, local SharedPreferences when guest.

final class DashboardStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<DashboardStatsEntity>,
          DashboardStatsEntity,
          FutureOr<DashboardStatsEntity>
        >
    with
        $FutureModifier<DashboardStatsEntity>,
        $FutureProvider<DashboardStatsEntity> {
  /// Dashboard stats — cloud when signed in, local SharedPreferences when guest.
  DashboardStatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dashboardStatsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dashboardStatsHash();

  @$internal
  @override
  $FutureProviderElement<DashboardStatsEntity> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DashboardStatsEntity> create(Ref ref) {
    return dashboardStats(ref);
  }
}

String _$dashboardStatsHash() => r'6fb0be61b48102a819754e74cc43af94fecf13e1';
