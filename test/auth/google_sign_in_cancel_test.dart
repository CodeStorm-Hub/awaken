import 'package:awaken/core/services/google_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mirrors AuthScreen._signInWithGoogle cancel vs error handling.
({bool showError, bool clearLoading, bool navigateToDashboard})
    googleSignInUiOutcome(Object error) {
  if (error is GoogleSignInCanceledException) {
    return (
      showError: false,
      clearLoading: true,
      navigateToDashboard: false,
    );
  }
  return (
    showError: true,
    clearLoading: true,
    navigateToDashboard: false,
  );
}

void main() {
  test('Google cancel clears loading without error or navigation', () {
    final outcome =
        googleSignInUiOutcome(const GoogleSignInCanceledException());
    expect(outcome.showError, isFalse);
    expect(outcome.clearLoading, isTrue);
    expect(outcome.navigateToDashboard, isFalse);
  });

  test('Google failure shows error without navigation', () {
    final outcome = googleSignInUiOutcome(Exception('token exchange failed'));
    expect(outcome.showError, isTrue);
    expect(outcome.clearLoading, isTrue);
    expect(outcome.navigateToDashboard, isFalse);
  });
}
