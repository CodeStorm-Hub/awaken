import 'package:flutter_test/flutter_test.dart';

/// Mirrors AuthScreen._submit sign-up branch navigation rules.
///
/// When email confirmation is required, [currentUser] stays null and the UI
/// shows a confirm-email message. When signup creates an immediate session,
/// the app must clear loading and navigate to the dashboard.
({bool showConfirmEmail, bool navigateToDashboard}) signupOutcome({
  required bool hasSession,
}) {
  if (!hasSession) {
    return (showConfirmEmail: true, navigateToDashboard: false);
  }
  return (showConfirmEmail: false, navigateToDashboard: true);
}

void main() {
  test('signup with immediate session navigates to dashboard', () {
    final outcome = signupOutcome(hasSession: true);
    expect(outcome.navigateToDashboard, isTrue);
    expect(outcome.showConfirmEmail, isFalse);
  });

  test('signup requiring email confirmation stays on auth', () {
    final outcome = signupOutcome(hasSession: false);
    expect(outcome.navigateToDashboard, isFalse);
    expect(outcome.showConfirmEmail, isTrue);
  });
}
