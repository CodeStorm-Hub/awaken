// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_schedule_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Picks the correct repository based on auth state:
///   - Signed in  → Supabase (cloud-synced)
///   - Signed out → SharedPreferences (local-only)

@ProviderFor(alarmRepository)
final alarmRepositoryProvider = AlarmRepositoryProvider._();

/// Picks the correct repository based on auth state:
///   - Signed in  → Supabase (cloud-synced)
///   - Signed out → SharedPreferences (local-only)

final class AlarmRepositoryProvider
    extends
        $FunctionalProvider<AlarmRepository, AlarmRepository, AlarmRepository>
    with $Provider<AlarmRepository> {
  /// Picks the correct repository based on auth state:
  ///   - Signed in  → Supabase (cloud-synced)
  ///   - Signed out → SharedPreferences (local-only)
  AlarmRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alarmRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alarmRepositoryHash();

  @$internal
  @override
  $ProviderElement<AlarmRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AlarmRepository create(Ref ref) {
    return alarmRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlarmRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlarmRepository>(value),
    );
  }
}

String _$alarmRepositoryHash() => r'900590b51be3a229156bb28ab07f5a6685655473';

@ProviderFor(AlarmList)
final alarmListProvider = AlarmListProvider._();

final class AlarmListProvider
    extends $AsyncNotifierProvider<AlarmList, List<AlarmEntity>> {
  AlarmListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alarmListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alarmListHash();

  @$internal
  @override
  AlarmList create() => AlarmList();
}

String _$alarmListHash() => r'a68cc919f9f8f0963e1962127c4fc25cc8ae41fa';

abstract class _$AlarmList extends $AsyncNotifier<List<AlarmEntity>> {
  FutureOr<List<AlarmEntity>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<AlarmEntity>>, List<AlarmEntity>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<AlarmEntity>>, List<AlarmEntity>>,
              AsyncValue<List<AlarmEntity>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(nextAlarm)
final nextAlarmProvider = NextAlarmProvider._();

final class NextAlarmProvider
    extends $FunctionalProvider<AlarmEntity?, AlarmEntity?, AlarmEntity?>
    with $Provider<AlarmEntity?> {
  NextAlarmProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nextAlarmProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nextAlarmHash();

  @$internal
  @override
  $ProviderElement<AlarmEntity?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AlarmEntity? create(Ref ref) {
    return nextAlarm(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlarmEntity? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlarmEntity?>(value),
    );
  }
}

String _$nextAlarmHash() => r'580f25c319d6c1ff22efd76d7b0607a4a1aef804';
