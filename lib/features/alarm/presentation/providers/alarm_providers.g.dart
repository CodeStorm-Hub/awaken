// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RepCount)
final repCountProvider = RepCountProvider._();

final class RepCountProvider extends $NotifierProvider<RepCount, int> {
  RepCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'repCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$repCountHash();

  @$internal
  @override
  RepCount create() => RepCount();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$repCountHash() => r'59c323f61012ff71aa0b202e0f5f131c377d5255';

abstract class _$RepCount extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(RepFeedbackNotifier)
final repFeedbackProvider = RepFeedbackNotifierProvider._();

final class RepFeedbackNotifierProvider
    extends $NotifierProvider<RepFeedbackNotifier, RepFeedback> {
  RepFeedbackNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'repFeedbackProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$repFeedbackNotifierHash();

  @$internal
  @override
  RepFeedbackNotifier create() => RepFeedbackNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RepFeedback value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RepFeedback>(value),
    );
  }
}

String _$repFeedbackNotifierHash() =>
    r'91d16e1f8f1f21d1133b4e825c775089e1ed7d05';

abstract class _$RepFeedbackNotifier extends $Notifier<RepFeedback> {
  RepFeedback build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<RepFeedback, RepFeedback>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<RepFeedback, RepFeedback>,
              RepFeedback,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(RequiredReps)
final requiredRepsProvider = RequiredRepsProvider._();

final class RequiredRepsProvider extends $NotifierProvider<RequiredReps, int> {
  RequiredRepsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'requiredRepsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$requiredRepsHash();

  @$internal
  @override
  RequiredReps create() => RequiredReps();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$requiredRepsHash() => r'0e28a7abc40d84dbe4a4d8151f58e01c9a3de5e0';

abstract class _$RequiredReps extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(ActiveExerciseType)
final activeExerciseTypeProvider = ActiveExerciseTypeProvider._();

final class ActiveExerciseTypeProvider
    extends $NotifierProvider<ActiveExerciseType, AlarmExerciseType> {
  ActiveExerciseTypeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeExerciseTypeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activeExerciseTypeHash();

  @$internal
  @override
  ActiveExerciseType create() => ActiveExerciseType();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlarmExerciseType value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlarmExerciseType>(value),
    );
  }
}

String _$activeExerciseTypeHash() =>
    r'b5729d3457cc903e38f278989603a83b2f72ef08';

abstract class _$ActiveExerciseType extends $Notifier<AlarmExerciseType> {
  AlarmExerciseType build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AlarmExerciseType, AlarmExerciseType>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AlarmExerciseType, AlarmExerciseType>,
              AlarmExerciseType,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(ActivePenaltyMultiplier)
final activePenaltyMultiplierProvider = ActivePenaltyMultiplierProvider._();

final class ActivePenaltyMultiplierProvider
    extends $NotifierProvider<ActivePenaltyMultiplier, int> {
  ActivePenaltyMultiplierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activePenaltyMultiplierProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activePenaltyMultiplierHash();

  @$internal
  @override
  ActivePenaltyMultiplier create() => ActivePenaltyMultiplier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$activePenaltyMultiplierHash() =>
    r'a6dfd798ee5b095ac5fa572721354d2d4c025243';

abstract class _$ActivePenaltyMultiplier extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(OutOfFrame)
final outOfFrameProvider = OutOfFrameProvider._();

final class OutOfFrameProvider extends $NotifierProvider<OutOfFrame, bool> {
  OutOfFrameProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'outOfFrameProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$outOfFrameHash();

  @$internal
  @override
  OutOfFrame create() => OutOfFrame();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$outOfFrameHash() => r'2b1c7263fa50d0e105d3bd4d3007ac4a42574c1d';

abstract class _$OutOfFrame extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(SessionStartTime)
final sessionStartTimeProvider = SessionStartTimeProvider._();

final class SessionStartTimeProvider
    extends $NotifierProvider<SessionStartTime, DateTime?> {
  SessionStartTimeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionStartTimeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionStartTimeHash();

  @$internal
  @override
  SessionStartTime create() => SessionStartTime();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$sessionStartTimeHash() => r'a629a6c6e6a2633bc13306ecb1ab88b60dbdb8df';

abstract class _$SessionStartTime extends $Notifier<DateTime?> {
  DateTime? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime?, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime?, DateTime?>,
              DateTime?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(SquatDepthRatio)
final squatDepthRatioProvider = SquatDepthRatioProvider._();

final class SquatDepthRatioProvider
    extends $NotifierProvider<SquatDepthRatio, double> {
  SquatDepthRatioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'squatDepthRatioProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$squatDepthRatioHash();

  @$internal
  @override
  SquatDepthRatio create() => SquatDepthRatio();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$squatDepthRatioHash() => r'd965e7c18496a5434d22b1c2e20fa0d25a745fe9';

abstract class _$SquatDepthRatio extends $Notifier<double> {
  double build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<double, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<double, double>,
              double,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(ExerciseCue)
final exerciseCueProvider = ExerciseCueProvider._();

final class ExerciseCueProvider
    extends $NotifierProvider<ExerciseCue, String?> {
  ExerciseCueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exerciseCueProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exerciseCueHash();

  @$internal
  @override
  ExerciseCue create() => ExerciseCue();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$exerciseCueHash() => r'4a561099560d41ce64fee0ac3c00c3598e7715bc';

abstract class _$ExerciseCue extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(AccessibilitySession)
final accessibilitySessionProvider = AccessibilitySessionProvider._();

final class AccessibilitySessionProvider
    extends $NotifierProvider<AccessibilitySession, bool> {
  AccessibilitySessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accessibilitySessionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accessibilitySessionHash();

  @$internal
  @override
  AccessibilitySession create() => AccessibilitySession();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$accessibilitySessionHash() =>
    r'867b569668eaae7fc387ee3314779e168041116a';

abstract class _$AccessibilitySession extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
