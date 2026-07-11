import 'package:awaken/features/alarm/domain/entities/alarm_exercise_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'alarm_providers.g.dart';

/// Feedback state for the active alarm's glowing border.
enum RepFeedback { neutral, success, failure }

/// Resets session-scoped alarm state when entering [ActiveAlarmScreen].
void resetAlarmSession(WidgetRef ref) {
  ref.read(repCountProvider.notifier).setCount(0);
  ref.read(repFeedbackProvider.notifier).setFeedback(RepFeedback.neutral);
  ref.read(outOfFrameProvider.notifier).setOutOfFrame(false);
  ref.read(squatDepthRatioProvider.notifier).setRatio(0);
  ref.read(accessibilitySessionProvider.notifier).setUsed(false);
  ref.read(exerciseCueProvider.notifier).setCue(null);
  ref.read(sessionStartTimeProvider.notifier).setStartTime(DateTime.now());
}

@riverpod
class RepCount extends _$RepCount {
  @override
  int build() => 0;

  void setCount(int value) => state = value;
}

@riverpod
class RepFeedbackNotifier extends _$RepFeedbackNotifier {
  @override
  RepFeedback build() => RepFeedback.neutral;

  void setFeedback(RepFeedback value) => state = value;
}

final repFeedbackProvider = repFeedbackNotifierProvider;

@Riverpod(keepAlive: true)
class RequiredReps extends _$RequiredReps {
  @override
  int build() => 10;

  void setRequired(int value) => state = value;
}

@Riverpod(keepAlive: true)
class ActiveExerciseType extends _$ActiveExerciseType {
  @override
  AlarmExerciseType build() => AlarmExerciseType.squats;

  void setType(AlarmExerciseType value) => state = value;
}

@Riverpod(keepAlive: true)
class ActivePenaltyMultiplier extends _$ActivePenaltyMultiplier {
  @override
  int build() => 1;

  void setMultiplier(int value) => state = value;
}

@riverpod
class OutOfFrame extends _$OutOfFrame {
  @override
  bool build() => false;

  void setOutOfFrame(bool value) => state = value;
}

@riverpod
class SessionStartTime extends _$SessionStartTime {
  @override
  DateTime? build() => null;

  void setStartTime(DateTime? value) => state = value;
}

@riverpod
class SquatDepthRatio extends _$SquatDepthRatio {
  @override
  double build() => 0;

  void setRatio(double value) => state = value;
}

@riverpod
class ExerciseCue extends _$ExerciseCue {
  @override
  String? build() => null;

  void setCue(String? value) => state = value;
}

@Riverpod(keepAlive: true)
class AccessibilitySession extends _$AccessibilitySession {
  @override
  bool build() => false;

  void setUsed(bool value) => state = value;
}

final bailoutBannerDismissedProvider = StateProvider<bool>((ref) => false);
