/// Supabase credentials + Google OAuth (Android native sign-in).
///
/// **Architecture**: Supabase owns the session. Google sign-in on Android uses
/// the native `google_sign_in` account picker, then `signInWithIdToken` — no
/// browser redirect and no Firebase Auth web flow.
///
/// **Android app** (already configured):
/// - Package `com.example.awaken`
/// - Android OAuth client (`client_type: 1`) in Google Cloud / Firebase Console
/// - Debug SHA-1 registered for that Android client
///
/// **One-time Supabase Dashboard** (Authentication → Providers → Google):
/// 1. Enable Google
/// 2. **Client ID**: [googleOAuthClientIdForSupabase] — the `client_type: 3`
///    Web client from `google-services.json` / Google Cloud Console. Passed as
///    `serverClientId` to `google_sign_in` so Google issues an ID token Supabase
///    can verify.
/// 3. **Skip nonce checks**: ON (required for Android `signInWithIdToken`)
/// 4. **Client secret**: optional for native ID-token sign-in; add only if
///    Supabase rejects the exchange.
/// 5. **Authorized Client IDs** (if shown): add [googleAndroidClientId]
///
/// **Callback URL** (`https://<ref>.supabase.co/auth/v1/callback`) is for
/// Supabase-hosted web OAuth only — this app does not use it.
abstract final class SupabaseConfig {
  // ── Supabase ──────────────────────────────────────────────────────────────
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://nankdbntvvopnfvvvaoo.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im5hbmtkYm50dnZvcG5mdnZ2YW9vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM0NDM4NDEsImV4cCI6MjA5OTAxOTg0MX0.jAV0yktnr_N7JKaXEBvtI9iVXbUy48StGoSFyz9qDN0',
  );

  // ── Google OAuth (from android/app/google-services.json) ──────────────────

  /// Android OAuth client (`client_type: 1`). Used for SHA-1 / package binding.
  static const String googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue:
        '230513820686-ua1prkedtbtceb4d39e2kqg5m23q7te8.apps.googleusercontent.com',
  );

  /// Web OAuth client for Supabase Google provider (`client_type: 3`). Passed to
  /// `google_sign_in` as [serverClientId] for ID token audience verification.
  static const String googleOAuthClientIdForSupabase = String.fromEnvironment(
    'GOOGLE_OAUTH_CLIENT_ID',
    defaultValue:
        '230513820686-ku2co5m68332qjv7t0cgbe5vk8nlvrea.apps.googleusercontent.com',
  );

  /// @deprecated Use [googleOAuthClientIdForSupabase]. Kept for dart-define compat.
  static const String googleWebClientId = googleOAuthClientIdForSupabase;
}
