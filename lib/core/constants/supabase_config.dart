/// Supabase credentials + Firebase Google OAuth (Android-only).
///
/// **Architecture**: Supabase owns the session. Google sign-in on Android runs
/// through Firebase Auth, then `signInWithIdToken` — no Flutter web app needed.
///
/// **Android app** (already configured):
/// - Firebase project `awaken-27f39`, package `com.example.awaken`
/// - `android/app/google-services.json` with Android + bundled OAuth clients
/// - Debug SHA-1 registered in Firebase Console
///
/// **One-time Supabase Dashboard** (Authentication → Providers → Google):
/// 1. Enable Google
/// 2. **Client ID**: [googleOAuthClientIdForSupabase] — this is the `client_type: 3`
///    entry inside `google-services.json`. Google/Firebase attach it to every
///    Android app so ID tokens can be verified server-side; you are *not* shipping
///    a web app.
/// 3. **Skip nonce checks**: ON (required for Android `signInWithIdToken`)
/// 4. **Client secret**: optional for Android-only ID-token sign-in. Leave blank
///    if the dashboard allows it. If sign-in fails with an OAuth error, add the
///    secret from [Google Cloud Credentials](https://console.cloud.google.com/apis/credentials?project=awaken-27f39)
///    → Web client (auto created by Google Service) → Reset secret.
/// 5. **Authorized Client IDs** (if shown): add [googleAndroidClientId]
abstract final class SupabaseConfig {
  // ── Supabase ──────────────────────────────────────────────────────────────
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://nankdbntvvopnfvvvaoo.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5hbmtkYm50dnZvcG5mdnZ2YW9vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM0NDM4NDEsImV4cCI6MjA5OTAxOTg0MX0.jAV0yktnr_N7JKaXEBvtI9iVXbUy48StGoSFyz9qDN0',
  );

  // ── Google OAuth (from android/app/google-services.json) ──────────────────

  /// Android OAuth client (`client_type: 1`). Used for SHA-1 / package binding.
  static const String googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue:
        '230513820686-ua1prkedtbtceb4d39e2kqg5m23q7te8.apps.googleusercontent.com',
  );

  /// OAuth client for Supabase Google provider (`client_type: 3` in
  /// google-services.json). Not a web app — bundled with the Android Firebase app.
  static const String googleOAuthClientIdForSupabase = String.fromEnvironment(
    'GOOGLE_OAUTH_CLIENT_ID',
    defaultValue:
        '230513820686-ku2co5m68332qjv7t0cgbe5vk8nlvrea.apps.googleusercontent.com',
  );

  /// @deprecated Use [googleOAuthClientIdForSupabase]. Kept for dart-define compat.
  static const String googleWebClientId = googleOAuthClientIdForSupabase;
}
