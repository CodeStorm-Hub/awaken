/// Supabase + Google OAuth credentials.
///
/// Fill these in from:
///   - Supabase Dashboard → Project Settings → API
///   - Google Cloud Console → OAuth 2.0 Client IDs
///
/// DO NOT commit real keys — put them in .env or flavour-specific config
/// and swap the const values here via dart-define or environment injection.
abstract final class SupabaseConfig {
  // ── Supabase ──────────────────────────────────────────────────────────────
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://fsdfqcnjcjtdmdjshrvu.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZzZGZxY25qY2p0ZG1kanNocnZ1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI2NzIwNTEsImV4cCI6MjA5ODI0ODA1MX0.zr4Sbwr3DyWoALowjWX2boCO9jChLrxfhBmnAGNUbSU',
  );

  // ── Google OAuth ──────────────────────────────────────────────────────────
  // The "Web application" client ID from Google Cloud Console.
  // Used as serverClientId in google_sign_in so Supabase can verify the token.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: 'your-web-client-id.apps.googleusercontent.com',
  );

  // Android client ID (SHA-1 fingerprint registered in GCC)
  static const String googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: 'your-android-client-id.apps.googleusercontent.com',
  );

  // iOS client ID (matches GIDClientID in Info.plist)
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: 'your-ios-client-id.apps.googleusercontent.com',
  );
}
