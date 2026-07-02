// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$repCountHash() => r'206b1e6fdc0a5f6ef127b6433ca4e42d75686d4c';

/// Current rep count during an active alarm session.
///
/// Copied from [RepCount].
@ProviderFor(RepCount)
final repCountProvider = AutoDisposeNotifierProvider<RepCount, int>.internal(
  RepCount.new,
  name: r'repCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$repCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RepCount = AutoDisposeNotifier<int>;
String _$repFeedbackNotifierHash() =>
    r'996fa8cff1f16acc2c1de51da0f358edb919f4cf';

/// Visual feedback state — drives the border glow colour on the camera HUD.
/// Resets to neutral after a short delay (handled in the screen widget).
///
/// Copied from [RepFeedbackNotifier].
@ProviderFor(RepFeedbackNotifier)
final repFeedbackNotifierProvider =
    AutoDisposeNotifierProvider<RepFeedbackNotifier, RepFeedback>.internal(
      RepFeedbackNotifier.new,
      name: r'repFeedbackNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$repFeedbackNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$RepFeedbackNotifier = AutoDisposeNotifier<RepFeedback>;
String _$requiredRepsHash() => r'47158413c3b52bc738857db896b8ff8167fe4bee';

/// Total reps required for the current alarm (injected at alarm trigger time).
/// Kept alive across the alarm → success flow (not session-local like rep count).
///
/// Copied from [RequiredReps].
@ProviderFor(RequiredReps)
final requiredRepsProvider = NotifierProvider<RequiredReps, int>.internal(
  RequiredReps.new,
  name: r'requiredRepsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$requiredRepsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$RequiredReps = Notifier<int>;
String _$outOfFrameHash() => r'06e7a6707289192eaf30c76c4635a4d5fefeb060';

/// Whether the out-of-frame penalty is currently active.
///
/// Copied from [OutOfFrame].
@ProviderFor(OutOfFrame)
final outOfFrameProvider =
    AutoDisposeNotifierProvider<OutOfFrame, bool>.internal(
      OutOfFrame.new,
      name: r'outOfFrameProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$outOfFrameHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$OutOfFrame = AutoDisposeNotifier<bool>;
String _$sessionStartTimeHash() => r'9e819b5b272dea7eb151b80e69d2b449fb6ed288';

/// When the current alarm session started — set in ActiveAlarmScreen.initState.
/// Used to compute duration_seconds when recording the session to Supabase.
///
/// Copied from [SessionStartTime].
@ProviderFor(SessionStartTime)
final sessionStartTimeProvider =
    AutoDisposeNotifierProvider<SessionStartTime, DateTime?>.internal(
      SessionStartTime.new,
      name: r'sessionStartTimeProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$sessionStartTimeHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SessionStartTime = AutoDisposeNotifier<DateTime?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
