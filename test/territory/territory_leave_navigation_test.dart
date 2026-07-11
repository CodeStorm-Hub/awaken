import 'package:awaken/features/territory/presentation/providers/active_run_providers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors [TerritoryRunScreen._leaveTerritory] / shell-tab back behavior.
///
/// `/territory` is a [StatefulShellRoute] branch root, so [GoRouter.canPop]
/// is often false. Calling [GoRouter.pop] then throws
/// `GoError: There is nothing to pop`.
({bool shouldPop, bool shouldGoDashboard}) leaveShellTab({
  required bool canPop,
}) {
  if (canPop) {
    return (shouldPop: true, shouldGoDashboard: false);
  }
  return (shouldPop: false, shouldGoDashboard: true);
}

/// Leaving the territory UI (tab switch / back) must never discard an active
/// run — only [ActiveRunNotifier.finishRun] / explicit [ActiveRunNotifier.reset]
/// after Stop should clear tracking.
bool shouldResetRunOnNavigateAway(RunSessionStatus status) {
  switch (status) {
    case RunSessionStatus.tracking:
    case RunSessionStatus.paused:
    case RunSessionStatus.finishing:
    case RunSessionStatus.requestingPermission:
    case RunSessionStatus.idle:
    case RunSessionStatus.finished:
    case RunSessionStatus.error:
      return false;
  }
}

void main() {
  test('shell-tab root with empty stack goes to dashboard', () {
    final outcome = leaveShellTab(canPop: false);
    expect(outcome.shouldPop, isFalse);
    expect(outcome.shouldGoDashboard, isTrue);
  });

  test('overlay route with stack pops normally', () {
    final outcome = leaveShellTab(canPop: true);
    expect(outcome.shouldPop, isTrue);
    expect(outcome.shouldGoDashboard, isFalse);
  });

  test('navigation away never resets an active or idle run', () {
    for (final status in RunSessionStatus.values) {
      expect(
        shouldResetRunOnNavigateAway(status),
        isFalse,
        reason: 'status $status must keep session until Stop',
      );
    }
  });
}
