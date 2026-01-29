# GitHub OAuth Setup Guide

## Overview
This app uses a **manual OAuth2 Authorization Code Flow** for GitHub authentication with the `app_links` package for deep link handling. This approach is more reliable than `flutter_appauth` because it manages state internally in Dart rather than relying on native AppAuth state persistence.

## Setup Steps

### 1. Create GitHub OAuth App

1. Go to [GitHub Settings → Developer settings → OAuth Apps](https://github.com/settings/developers)
2. Click **"New OAuth App"** or select an existing one
3. Fill in the application details:
   - **Application name**: Vaultscapes (or your app name)
   - **Homepage URL**: Your app's website or `https://vaultscapes.com`
   - **Authorization callback URL**: `com.mantavyam.vaultscapes://oauth-callback` ⚠️ **IMPORTANT**
4. Click **"Register application"**
5. Copy the **Client ID** and generate a **Client Secret**

### 2. Configure Environment Variables

1. Open the `.env` file in the project root (it's already created)
2. Replace the placeholder values with your actual credentials:
   ```env
   GITHUB_CLIENT_ID=your_actual_client_id_here
   GITHUB_CLIENT_SECRET=your_actual_client_secret_here
   ```
3. **NEVER** commit the `.env` file to version control (it's already in `.gitignore`)

### 3. Firebase Console (Optional)

Since we're using a manual OAuth flow, the Firebase GitHub provider settings are **not used** for the actual authentication. However, for consistency:

- In Firebase Console → Authentication → Sign-in method → GitHub
- You can keep the existing Firebase callback URL as is: `https://vaultscapes-mantavyam.firebaseapp.com/__/auth/handler`
- Or update it to match your custom scheme (though it won't be used)

The manual flow works like this:
```
User clicks GitHub login
    ↓
GitHub OAuth page opens in system browser (url_launcher)
    ↓
User authorizes on GitHub
    ↓
GitHub redirects to: com.mantavyam.vaultscapes://oauth-callback
    ↓
app_links receives deep link in Flutter
    ↓
State validated for CSRF protection
    ↓
App exchanges code for access token (http)
    ↓
App creates Firebase credential with token
    ↓
User is signed into Firebase with GitHub account
```

### 4. Deep Link Configuration

**Android Manifest** (`android/app/src/main/AndroidManifest.xml`):
```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:launchMode="singleTask"
    ...>
    <!-- Deep link handler for OAuth callback -->
    <intent-filter android:autoVerify="false">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="com.mantavyam.vaultscapes"
            android:host="oauth-callback" />
    </intent-filter>
</activity>
```

**Key Android Configuration:**
- `launchMode="singleTask"` ensures the same activity instance receives the deep link
- `app_links` package handles the deep link forwarding to Flutter
- INTERNET permission required for OAuth requests
- Browser query in manifest for launching OAuth URLs

**iOS** (`ios/Runner/Info.plist`) - already configured:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.mantavyam.vaultscapes</string>
        </array>
    </dict>
</array>
```

**MainActivity Launch Mode**:
```xml
android:launchMode="singleTask"
```
This ensures the same activity instance handles the OAuth callback.

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.vaultscapes.app</string>
        </array>
    </dict>
</array>
```

### 5. Testing

1. Run the app: `flutter run`
2. Navigate to the login screen
3. Click **"Continue with GitHub"**
4. System browser opens with GitHub authorization
5. Authorize the app
6. You should be redirected back to the app and signed in

## Troubleshooting

### "Missing initial state" or "No stored state" error
- Verify the Authorization callback URL in GitHub OAuth App is exactly: `com.mantavyam.vaultscapes://oauth-callback`
- Ensure AuthRedirectActivity is declared in AndroidManifest.xml with correct intent filter
- Verify redirect URI in code matches exactly (no trailing slashes)
- Make sure the `.env` file has the correct Client ID and Secret
- Uninstall and reinstall the app to clear old deep link registrations
- Restart the app after changing `.env` values

### OAuth stalls on welcome screen after approval
- This indicates redirect reached app but wasn't processed
- Ensure AuthRedirectActivity extends `net.openid.appauth.RedirectUriReceiverActivity`
- Verify intent filter host matches redirect URI host exactly
- Check logcat for "token" or "exchange" messages after redirect

### OAuth opens in webview instead of system browser
- Ensure `preferEphemeralSession: true` is set in the authorization request
- Add browser query intent in AndroidManifest.xml `<queries>` section
- Check that INTERNET permission is declared in AndroidManifest.xml

### Deep link not working
- On Android: Check that the intent filter is in `AndroidManifest.xml`
- On iOS: Check that URL types are in `Info.plist`
- Try uninstalling and reinstalling the app

### Environment variables not loading
- Ensure `.env` file is in the project root
- Verify `.env` is listed in `pubspec.yaml` under assets
- Run `flutter pub get` after adding the file
- Restart the app

## Security Notes

- ✅ `.env` is in `.gitignore` - your credentials are safe
- ✅ `.env.example` is provided for reference
- ✅ PKCE (Proof Key for Code Exchange) is enabled for security
- ⚠️ Never commit your actual credentials to version control
- ⚠️ Rotate your Client Secret if it's accidentally exposed

## Files Modified

- `lib/data/services/github_oauth_service.dart` - OAuth service with `preferEphemeralSession: true`
- `lib/data/services/firebase_auth_service.dart` - Updated to use manual OAuth
- `lib/main.dart` - Loads `.env` on startup
- `pubspec.yaml` - Added `flutter_dotenv` and `flutter_appauth`
- `android/app/build.gradle.kts` - Added manifestPlaceholders for OAuth redirect
- `android/app/src/main/AndroidManifest.xml` - INTERNET permission, browser queries, singleTask launch mode
- `android/gradle.properties` - Java 17 configuration
- `ios/Runner/Info.plist` - URL scheme configuration
- `.gitignore` - Excludes `.env` file
- `.env` - Contains your GitHub OAuth credentials (DO NOT COMMIT)
- `.env.example` - Template for other developers
