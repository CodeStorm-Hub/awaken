import 'package:firebase_auth/firebase_auth.dart';

/// Google OAuth via Firebase Auth — used only to obtain Google ID tokens.
///
/// Supabase remains the session authority ([SupabaseAuthRepository] calls
/// [signInWithIdToken] then signs out of Firebase). Firebase is not used for
/// app session state, RLS, or persistence.
abstract final class FirebaseGoogleAuthService {
  /// Runs Firebase Google sign-in and returns the **Google** OAuth tokens
  /// Supabase needs for [OAuthProvider.google] verification.
  static Future<({String idToken, String? accessToken})>
      signInAndGetGoogleTokens() async {
    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile');

    final userCredential =
        await FirebaseAuth.instance.signInWithProvider(provider);

    final oauth = userCredential.credential;
    if (oauth is OAuthCredential) {
      final idToken = oauth.idToken;
      if (idToken != null && idToken.isNotEmpty) {
        return (idToken: idToken, accessToken: oauth.accessToken);
      }
    }

    throw FirebaseAuthException(
      code: 'missing-google-id-token',
      message:
          'Firebase Google sign-in succeeded but returned no Google ID token. '
          'Verify google-services.json, debug SHA-1 in Firebase Console, and '
          'that Google is enabled under Authentication → Sign-in method.',
    );
  }

  /// Clears the ephemeral Firebase session after Supabase has the tokens.
  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}
