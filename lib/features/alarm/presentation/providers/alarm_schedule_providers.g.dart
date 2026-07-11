// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_schedule_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$alarmRepositoryHash() => r'756dd5b08e17c38446c8efcd308783dd77826743';

/// Picks the correct repository based on auth state:
///   - Signed in  → Supabase (cloud-synced)
///   - Signed out → SharedPreferences (local-only)
///
/// Copied from [alarmRepository].
@ProviderFor(alarmRepository)
final alarmRepositoryProvider = Provider<AlarmRepository>.internal(
  alarmRepository,
  name: r'alarmRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$alarmRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AlarmRepositoryRef = ProviderRef<AlarmRepository>;
String _$nextAlarmHash() => r'75dbd72eafb27879a79d08968b23cbb9c3e22e64';

/// See also [nextAlarm].
@ProviderFor(nextAlarm)
final nextAlarmProvider = Provider<AlarmEntity?>.internal(
  nextAlarm,
  name: r'nextAlarmProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$nextAlarmHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NextAlarmRef = ProviderRef<AlarmEntity?>;
String _$alarmListHash() => r'dcbfe23a1c74c2450c1654db1b1b9632cfa9fa09';

/// See also [AlarmList].
@ProviderFor(AlarmList)
final alarmListProvider =
    AsyncNotifierProvider<AlarmList, List<AlarmEntity>>.internal(
      AlarmList.new,
      name: r'alarmListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$alarmListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AlarmList = AsyncNotifier<List<AlarmEntity>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
