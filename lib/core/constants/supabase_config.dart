/// Supabase + Google OAuth credentials (via Firebase Configuration).
///
/// **Firebase Google Sign-In Setup Guide**:
/// 1. Go to the Firebase Console (https://console.firebase.google.com/) and create a new project.
/// 2. Add an Android app (providing your package name & SHA-1 fingerprint). Download `google-services.json` and place it in `android/app/`.
/// 3. Add an iOS app (providing your bundle ID). Download `GoogleService-Info.plist` and place it in `ios/Runner/`.
/// 4. Go to Firebase Authentication -> Sign-in method and enable Google.
/// 5. In the Google provider settings, open the "Web SDK configuration" dropdown. Note down the **Web client ID** and **Web client secret**.
/// 6. Go to Supabase Dashboard (https://supabase.com/dashboard) -> Authentication -> Providers -> Google.
/// 7. Enable Google, and paste the Web Client ID and Web Client Secret from Firebase.
/// 8. Place the Web Client ID into your `.env` file as `GOOGLE_WEB_CLIENT_ID`.
/// 
/// Note: The Android/iOS client IDs are automatically read from the downloaded config files.
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

}
