import 'package:awaken/core/constants/supabase_config.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Native Google Sign-In — obtains Google ID tokens for Supabase
/// [OAuthProvider.google] / [SupabaseClient.auth.signInWithIdToken].
///
/// Uses the platform account picker (no Firebase / browser redirect).
/// [SupabaseConfig.googleOAuthClientIdForSupabase] is the Web client ID
/// (`client_type: 3`) so Google issues an ID token Supabase can verify.
abstract final class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: SupabaseConfig.googleOAuthClientIdForSupabase,
  );

  static Future<({String idToken, String? accessToken})>
      signInAndGetGoogleTokens() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw const GoogleSignInCanceledException();
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception(
        'Google sign-in returned no ID token. '
        'Verify the Android OAuth client SHA-1 and package name '
        '(com.example.awaken) in Google Cloud Console.',
      );
    }

    return (idToken: idToken, accessToken: auth.accessToken);
  }

  /// Clears the ephemeral Google session after Supabase has the tokens.
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}

/// Thrown when the user dismisses the native Google account picker.
final class GoogleSignInCanceledException implements Exception {
  const GoogleSignInCanceledException();

  @override
  String toString() => 'Google sign-in cancelled';
}
