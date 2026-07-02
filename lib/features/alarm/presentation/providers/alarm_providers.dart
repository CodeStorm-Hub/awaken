import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'alarm_providers.g.dart';

/// Feedback state for the active alarm's glowing border.
enum RepFeedback { neutral, success, failure }

/// Resets session-scoped alarm state when entering [ActiveAlarmScreen].
///
/// Intentionally does not touch [activeRunProvider] — a territory run may
/// still be in progress under the shell when an alarm overlay opens.
void resetAlarmSession(WidgetRef ref) {
  ref.read(repCountProvider.notifier).setCount(0);
  ref.read(repFeedbackProvider.notifier).setFeedback(RepFeedback.neutral);
  ref.read(outOfFrameProvider.notifier).setOutOfFrame(false);
  ref.read(sessionStartTimeProvider.notifier).setStartTime(DateTime.now());
}

/// Current rep count during an active alarm session.
@riverpod
class RepCount extends _$RepCount {
  @override
  int build() => 0;

  void setCount(int value) => state = value;
}

/// Visual feedback state — drives the border glow colour on the camera HUD.
/// Resets to neutral after a short delay (handled in the screen widget).
///
/// Class is [RepFeedbackNotifier] because enum [RepFeedback] blocks the usual
/// `repFeedbackProvider` codegen name; alias below preserves the public API.
@riverpod
class RepFeedbackNotifier extends _$RepFeedbackNotifier {
  @override
  RepFeedback build() => RepFeedback.neutral;

  void setFeedback(RepFeedback value) => state = value;
}

/// Legacy public name — see [RepFeedbackNotifier].
final repFeedbackProvider = repFeedbackNotifierProvider;

/// Total reps required for the current alarm (injected at alarm trigger time).
/// Kept alive across the alarm → success flow (not session-local like rep count).
@Riverpod(keepAlive: true)
class RequiredReps extends _$RequiredReps {
  @override
  int build() => 10;

  void setRequired(int value) => state = value;
}

/// Whether the out-of-frame penalty is currently active.
@riverpod
class OutOfFrame extends _$OutOfFrame {
  @override
  bool build() => false;

  void setOutOfFrame(bool value) => state = value;
}

/// When the current alarm session started — set in ActiveAlarmScreen.initState.
/// Used to compute duration_seconds when recording the session to Supabase.
@riverpod
class SessionStartTime extends _$SessionStartTime {
  @override
  DateTime? build() => null;

  void setStartTime(DateTime? value) => state = value;
}
