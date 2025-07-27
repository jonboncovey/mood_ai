# Quick Setup Checklist

## ✅ What's Already Done
- [x] CodeMagic configuration file (`codemagic.yaml`) created
- [x] Firebase dependencies added to `pubspec.yaml`
- [x] Basic Firebase setup (firebase_core, firebase_auth)
- [x] **iOS bundle ID updated** from `com.example.moodAi` to `com.mood-ai.moviesapp`
- [x] **macOS bundle ID updated** to match iOS
- [x] **Platform-specific bundle IDs**: iOS uses hyphens, Android uses underscores
- [x] **Test Lab ready**: Configuration works for both physical devices and Test Lab

## 📋 What You Need To Do

### 1. Firebase Console Setup
- [ ] Go to [Firebase Console](https://console.firebase.google.com/)
- [ ] Create/select your project
- [ ] **REMOVE** existing iOS app with bundle ID: `com.example.moodAi`
- [ ] **RE-ADD** iOS app with bundle ID: `com.mood-ai.moviesapp` (note: hyphens for iOS)
- [ ] Download new `GoogleService-Info.plist` → **replace** the old one in `ios/Runner/`
- [ ] Verify Android app with package name: `com.mood_ai.moviesapp` (underscores - should already exist)
- [ ] **Enable Test Lab** (for iOS virtual device testing)
- [ ] Enable **App Distribution** feature (optional - for future physical device testing)
- [ ] Create tester group called `testers` (if using App Distribution)

### 2. Firebase CLI Setup
**Option A - NPM (Recommended):**
- [ ] Install: `npm install -g firebase-tools`
- [ ] Login: `firebase login:ci`
- [ ] Save the generated token for CodeMagic

**Option B - Without Installing:**
- [ ] Run: `npx firebase-tools login:ci`
- [ ] Save the generated token for CodeMagic

**Option C - Direct Download:**
- [ ] Download from [Firebase CLI releases](https://github.com/firebase/firebase-tools/releases)
- [ ] Add to PATH, then run: `firebase login:ci`

### 3. Apple Developer Account (Optional for Test Lab)
- [ ] Sign up for Apple Developer (free account works for development signing)
- [ ] **Note**: Physical device registration not needed for Firebase Test Lab
- [ ] **Alternative**: Can test using Firebase Test Lab virtual devices

### 4. CodeMagic Account Setup
- [ ] Sign up at [CodeMagic](https://codemagic.io/)
- [ ] Connect your GitHub repository
- [ ] Select this Flutter project

### 5. CodeMagic Environment Variables
Add these encrypted variables in CodeMagic dashboard:
- [ ] `FIREBASE_TOKEN` (from step 2)
- [ ] `FIREBASE_APP_ID_IOS` (from Firebase Console)
- [ ] `FIREBASE_APP_ID_ANDROID` (from Firebase Console)
- [ ] Set up iOS code signing (automatic or manual)
  - [ ] **Note**: For Test Lab only, basic development signing is sufficient

### 6. Update Dependencies
- [ ] Run: `flutter pub get`
- [ ] Commit and push all changes

### 7. Test the Setup
- [ ] Push to `main` branch
- [ ] Check CodeMagic dashboard for build status
- [ ] Wait for build completion
- [ ] **Option A - Firebase Test Lab**:
  - [ ] Go to Firebase Console → Test Lab
  - [ ] Upload the generated IPA from CodeMagic artifacts
  - [ ] Run tests on virtual iOS devices
- [ ] **Option B - Firebase App Distribution** (if you get a physical device later):
  - [ ] Check email for Firebase App Distribution link
  - [ ] Install app on your physical iOS device

## 🔧 Quick Commands

```bash
# Update dependencies
flutter pub get

# Test local build (optional)
flutter build ios --release --no-codesign

# Commit changes
git add .
git commit -m "Add CodeMagic CI/CD setup with Firebase App Distribution"
git push origin main
```

## 🚨 Common Issues

1. **Bundle ID Mismatch**: iOS uses `com.mood-ai.moviesapp`, Android uses `com.mood_ai.moviesapp`
2. **Firebase Files Missing**: Both plist and json files must be in correct locations
3. **Code Signing Issues**: For Test Lab, basic development signing is sufficient
4. **CodeMagic Build Minutes**: Free tier has limited build minutes
5. **Test Lab Limits**: Firebase has daily Test Lab usage limits on free tier

## ⏰ Expected Timeline

- Firebase setup: 10-15 minutes
- Apple Developer setup: 5 minutes (basic account only)
- CodeMagic setup: 10-15 minutes
- First successful build: 15-20 minutes
- Test Lab testing: 5-10 minutes per test run

Total setup time: ~40-50 minutes

## 🧪 Firebase Test Lab Usage

After your CodeMagic build completes:

1. **Download IPA from CodeMagic**:
   - Go to CodeMagic dashboard → Your build
   - Download the `.ipa` file from artifacts

2. **Upload to Test Lab**:
   - Firebase Console → Test Lab → "Run a test"
   - Upload your IPA file
   - Select iOS devices to test on
   - Choose test type (Robo test for basic UI testing)

3. **View Results**:
   - Test results show screenshots, logs, and any crashes
   - Perfect for validating your app works on iOS

## 📞 Need Help?

1. Check the detailed `CODEMAGIC_SETUP.md` guide
2. Firebase console logs and CodeMagic build logs
3. [Firebase Test Lab documentation](https://firebase.google.com/docs/test-lab) 