# Supabase Auth Setup — New Project (`nankdbntvvopnfvvvaoo`)

One-time dashboard configuration required before Google sign-in and email auth work in the app.

**Dashboard:** https://supabase.com/dashboard/project/nankdbntvvopnfvvvaoo/auth/providers

## Google OAuth (required for Android)

The app uses **native Google Sign-In** (`google_sign_in`) + Supabase `signInWithIdToken`.
It does **not** open a browser or use the Supabase OAuth callback URL.

1. Open **Authentication → Providers → Google**
2. **Enable** the provider
3. **Client ID:** `230513820686-ku2co5m68332qjv7t0cgbe5vk8nlvrea.apps.googleusercontent.com`
   (Web / `client_type: 3` — `GOOGLE_OAUTH_CLIENT_ID` in `.env`, used as `serverClientId`)
4. **Skip nonce checks:** ON (required for Android `signInWithIdToken`)
5. **Authorized Client IDs** (if shown): add `230513820686-ua1prkedtbtceb4d39e2kqg5m23q7te8.apps.googleusercontent.com`
   (Android / `client_type: 1` — `GOOGLE_ANDROID_CLIENT_ID`)
6. **Client secret:** optional for native ID-token sign-in; paste from the Web client JSON only if Supabase requires it

### Callback URL — not used by this app

Supabase shows:

`https://nankdbntvvopnfvvvaoo.supabase.co/auth/v1/callback`

That URL is only for **Supabase-hosted web OAuth** (redirect flow). This Android app
never hits it — tokens go directly from native Google Sign-In to `signInWithIdToken`.
You do **not** need to add this URL to Google Cloud redirect URIs for mobile sign-in.

## Google Cloud / Firebase (Android OAuth client)

Native sign-in requires the **Android** OAuth client to have:

- Package name: `com.example.awaken`
- SHA-1 fingerprint of your debug/release keystore

Configured in [Google Cloud Credentials](https://console.cloud.google.com/apis/credentials?project=awaken-27f39)
or Firebase Console → Project settings → Your apps → Android.

Current SHA-1 in `google-services.json`: `14:41:a3:de:e9:bf:d8:f9:26:41:4d:62:68:55:d7:c9:bd:32:39:b1`

If sign-in returns “no ID token”, re-run `cd android && ./gradlew signingReport` and
register the SHA-1 shown for your build variant.

## Email / Password (optional)

1. Open **Authentication → Providers → Email**
2. **Enable** email provider if using email sign-in on the auth screen
3. Configure email confirmation preference (disable for dev, enable for production)

## Recommended security settings

1. **Authentication → Policies → Leaked password protection:** enable
2. Confirm **Site URL** is set (mobile ID-token flow does not need redirect URLs)

## Verify after setup

```bash
flutter run --dart-define-from-file=.env -d android
```

1. Tap **Continue with Google** → native account picker (no `firebaseapp.com` browser page)
2. Sign in → `profiles` row created in Supabase
3. Create alarm while signed in → row appears in `alarms` table
