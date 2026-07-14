import 'package:awaken/core/constants/supabase_config.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Native Google Sign-In — obtains Google ID tokens for Supabase
/// [OAuthProvider.google] / [SupabaseClient.auth.signInWithIdToken].
///
/// Uses the platform account picker (no Firebase / browser redirect).
/// [SupabaseConfig.googleOAuthClientIdForSupabase] is the Web client ID
/// (`client_type: 3`) so Google issues an ID token Supabase can verify.
///
/// google_sign_in 7 replaced the per-instance `GoogleSignIn(...)` constructor
/// with a process-wide [GoogleSignIn.instance] singleton that must be
/// [GoogleSignIn.initialize]d exactly once before any other call — done
/// lazily here on first use so callers don't need their own init step.
abstract final class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static Future<void>? _initFuture;

  static Future<void> _ensureInitialized() {
    return _initFuture ??= _googleSignIn.initialize(
      serverClientId: SupabaseConfig.googleOAuthClientIdForSupabase,
    );
  }

  static Future<({String idToken, String? accessToken})>
  signInAndGetGoogleTokens() async {
    await _ensureInitialized();

    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleSignInCanceledException();
      }
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception(
        'Google sign-in returned no ID token. '
        'Verify the Android OAuth client SHA-1 and package name '
        '(com.example.awaken) in Google Cloud Console.',
      );
    }

    // accessToken is optional for Supabase's signInWithIdToken — request it
    // non-interactively first (silent, no extra prompt); only fall back to
    // an interactive authorization if the basic email/profile scopes weren't
    // already granted as part of authenticate() above.
    String? accessToken;
    try {
      final authorization =
          await account.authorizationClient.authorizationForScopes([
            'email',
            'profile',
          ]) ??
          await account.authorizationClient.authorizeScopes([
            'email',
            'profile',
          ]);
      accessToken = authorization.accessToken;
    } on GoogleSignInException {
      // Non-fatal — Supabase can verify identity from the ID token alone.
      accessToken = null;
    }

    return (idToken: idToken, accessToken: accessToken);
  }

  /// Clears the ephemeral Google session after Supabase has the tokens.
  static Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.signOut();
  }
}

/// Thrown when the user dismisses the native Google account picker.
final class GoogleSignInCanceledException implements Exception {
  const GoogleSignInCanceledException();

  @override
  String toString() => 'Google sign-in cancelled';
}
