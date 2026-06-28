import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Feedback state for the active alarm's glowing border.
enum RepFeedback { neutral, success, failure }

/// Current rep count during an active alarm session.
final repCountProvider = StateProvider<int>((ref) => 0);

/// Visual feedback state — drives the border glow colour on the camera HUD.
/// Resets to neutral after a short delay (handled in the screen widget).
final repFeedbackProvider = StateProvider<RepFeedback>((ref) => RepFeedback.neutral);

/// Total reps required for the current alarm (injected at alarm trigger time).
final requiredRepsProvider = StateProvider<int>((ref) => 10);

/// Whether the out-of-frame penalty is currently active.
final outOfFrameProvider = StateProvider<bool>((ref) => false);
