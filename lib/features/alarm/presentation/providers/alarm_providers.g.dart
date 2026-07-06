// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$repCountHash() => r'59c323f61012ff71aa0b202e0f5f131c377d5255';

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
    r'91d16e1f8f1f21d1133b4e825c775089e1ed7d05';

/// Visual feedback state — drives the border glow colour on the camera HUD.
/// Resets to neutral after a short delay (handled in the screen widget).
///
/// Class is [RepFeedbackNotifier] because enum [RepFeedback] blocks the usual
/// `repFeedbackProvider` codegen name; alias below preserves the public API.
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
String _$requiredRepsHash() => r'0e28a7abc40d84dbe4a4d8151f58e01c9a3de5e0';

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
String _$outOfFrameHash() => r'2b1c7263fa50d0e105d3bd4d3007ac4a42574c1d';

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
String _$sessionStartTimeHash() => r'a629a6c6e6a2633bc13306ecb1ab88b60dbdb8df';

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
