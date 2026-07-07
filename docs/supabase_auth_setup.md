# Supabase Auth Setup — New Project (`nankdbntvvopnfvvvaoo`)

One-time dashboard configuration required before Google sign-in and email auth work in the app.

**Dashboard:** https://supabase.com/dashboard/project/nankdbntvvopnfvvvaoo/auth/providers

## Google OAuth (required for Android)

1. Open **Authentication → Providers → Google**
2. **Enable** the provider
3. **Client ID:** `230513820686-ku2co5m68332qjv7t0cgbe5vk8nlvrea.apps.googleusercontent.com`
   (client_type 3 from `android/app/google-services.json` — `GOOGLE_OAUTH_CLIENT_ID` in `.env`)
4. **Skip nonce checks:** ON (required for Android `signInWithIdToken`)
5. **Authorized Client IDs** (if shown): add `230513820686-ua1prkedtbtceb4d39e2kqg5m23q7te8.apps.googleusercontent.com`
   (`GOOGLE_ANDROID_CLIENT_ID`)
6. **Client secret:** leave blank if allowed; add from [Google Cloud Credentials](https://console.cloud.google.com/apis/credentials?project=awaken-27f39) only if sign-in fails

## Email / Password (optional)

1. Open **Authentication → Providers → Email**
2. **Enable** email provider if using email sign-in on the auth screen
3. Configure email confirmation preference (disable for dev, enable for production)

## Recommended security settings

1. **Authentication → Policies → Leaked password protection:** enable (HaveIBeenPwned check)
2. Confirm **Site URL** is set (mobile ID-token flow does not need redirect URLs)

## Verify after setup

```bash
flutter run --dart-define-from-file=.env -d android
```

1. Sign in with Google → `profiles` row created for user
2. Create alarm while signed in → row appears in `alarms` table
3. Complete workout → `sessions` + `streaks` updated
