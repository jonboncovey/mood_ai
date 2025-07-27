# CodeMagic Setup Guide for iOS Builds

This guide will help you set up CodeMagic to build your Flutter app for iOS and distribute it using Firebase App Distribution.

## Prerequisites

1. **Apple Developer Account** (free account sufficient for development)
2. **Firebase Project** with Test Lab and/or App Distribution enabled
3. **CodeMagic Account** (free tier available)
4. **Testing Options**:
   - **Option A**: Firebase Test Lab (virtual iOS devices - no physical device needed)
   - **Option B**: Physical iOS device registered in your Apple Developer account

## Step 1: Firebase Setup

### 1.1 Create Firebase Apps
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project or create a new one
3. Add iOS app:
   - iOS bundle ID: `com.mood-ai.moviesapp` (note: hyphens for iOS)
   - Download `GoogleService-Info.plist`
4. Add Android app:
   - Android package name: `com.mood_ai.moviesapp` (note: underscores for Android)
   - Download `google-services.json`

### 1.2 Enable App Distribution
1. In Firebase Console, go to **App Distribution**
2. Click **Get Started**
3. Create a tester group called `testers`
4. Add your email to the group

### 1.3 Generate Firebase Token
Run this command on any machine with Firebase CLI:
```bash
npm install -g firebase-tools
firebase login:ci
```
Save the generated token - you'll need it for CodeMagic.

## Step 2: Add Firebase Files to Project

### 2.1 iOS Configuration
1. Place `GoogleService-Info.plist` in `ios/Runner/`
2. Open `ios/Runner.xcworkspace` in Xcode
3. Add `GoogleService-Info.plist` to the Runner target

### 2.2 Android Configuration
1. Place `google-services.json` in `android/app/`

## Step 3: Update Dependencies

Add Firebase App Distribution to your `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^3.15.1
  # ... your existing dependencies

dev_dependencies:
  firebase_app_distribution: ^1.1.1
  # ... your existing dev dependencies
```

## Step 4: CodeMagic Setup

### 4.1 Connect Repository
1. Go to [CodeMagic](https://codemagic.io/)
2. Sign up and connect your GitHub repository
3. Select your Flutter project

### 4.2 Configure Environment Variables
In CodeMagic dashboard, add these encrypted variables:

**Firebase Variables:**
- `FIREBASE_TOKEN`: Your Firebase CI token
- `FIREBASE_APP_ID_IOS`: iOS app ID from Firebase Console
- `FIREBASE_APP_ID_ANDROID`: Android app ID from Firebase Console

**Apple Developer Variables:**
- `APP_STORE_CONNECT_ISSUER_ID`: From App Store Connect API
- `APP_STORE_CONNECT_KEY_IDENTIFIER`: From App Store Connect API  
- `APP_STORE_CONNECT_PRIVATE_KEY`: From App Store Connect API

### 4.3 iOS Code Signing
1. In CodeMagic, go to **Code Signing**
2. Choose **Automatic code signing**
3. Upload your Apple Developer certificates
4. Or use **App Store Connect API** (recommended)

### 4.4 Android Signing (Optional)
1. Generate or upload your Android keystore
2. Add keystore details to environment variables

## Step 5: Update Bundle Identifier

Make sure your bundle identifiers are correctly configured for each platform:

### iOS (`ios/Runner/Info.plist`):
```xml
<key>CFBundleIdentifier</key>
<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
<!-- This resolves to: com.mood-ai.moviesapp -->
```

### Android (`android/app/build.gradle.kts`):
```kotlin
android {
    defaultConfig {
        applicationId = "com.mood_ai.moviesapp"
        // ...
    }
}
```

**Note**: iOS uses hyphens (`com.mood-ai.moviesapp`) while Android uses underscores (`com.mood_ai.moviesapp`). This is perfectly normal and follows platform conventions.

## Step 6: Test the Setup

1. Push changes to your `main` branch
2. CodeMagic will automatically trigger builds
3. Check build logs in CodeMagic dashboard
4. Once successful, you'll receive app links via email
5. Install on your iOS device using the provided link

## Step 7: Testing Your App

### Option A: Firebase Test Lab (No Physical Device Needed)
1. **Download IPA**: Get the `.ipa` file from CodeMagic build artifacts
2. **Go to Firebase Test Lab**: Firebase Console → Test Lab → "Run a test"
3. **Upload IPA**: Select your `.ipa` file
4. **Choose Devices**: Select iOS device models to test on
5. **Run Test**: Choose "Robo test" for automated UI testing
6. **View Results**: Screenshots, logs, and crash reports

### Option B: Physical Device Installation
#### For iOS:
1. Click the Firebase App Distribution link in your email
2. Install the Firebase App Distribution app on your iOS device
3. Open the link on your device to install your app

#### For Android:
1. Click the Firebase App Distribution link
2. Download and install the APK directly

## Troubleshooting

### Common Issues:

1. **Code Signing Errors**:
   - Ensure your Apple Developer certificates are valid
   - Check bundle identifier matches exactly
   - Verify device is registered in Apple Developer account

2. **Firebase Distribution Fails**:
   - Verify Firebase token is correct
   - Check app IDs match Firebase Console
   - Ensure tester group exists

3. **Build Failures**:
   - Check Flutter version compatibility
   - Verify all dependencies are compatible
   - Review build logs in CodeMagic

### Useful Commands:

```bash
# Test Firebase setup locally
firebase appdistribution:distribute app-release.apk \
  --app YOUR_FIREBASE_APP_ID \
  --groups "testers" \
  --token YOUR_FIREBASE_TOKEN

# Check iOS bundle identifier
grep -r "PRODUCT_BUNDLE_IDENTIFIER" ios/
```

## Next Steps

1. Set up notifications for successful builds
2. Add more tester groups for different environments
3. Consider upgrading to CodeMagic Pro for more build minutes
4. Implement automated testing in your CI/CD pipeline

## Support

- [CodeMagic Documentation](https://docs.codemagic.io/)
- [Firebase App Distribution Docs](https://firebase.google.com/docs/app-distribution)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios) 