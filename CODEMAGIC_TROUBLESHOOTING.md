# CodeMagic Troubleshooting Guide

## 🚨 **Common Build Failures**

### **Android Build Failures**

#### **Firebase App Distribution Dependency Error**
```
BUILD FAILED: firebase_app_distribution variant mismatch
```

**✅ Solution**: 
- **Removed**: `firebase_app_distribution` from `pubspec.yaml` (already fixed)
- **Reason**: CodeMagic handles Firebase distribution natively, plugin not needed
- **Status**: ✅ **FIXED**

#### **Speech-to-Text Plugin Registrar Error**
```
Swift Compiler Error: Cannot find 'registrar' in scope
SwiftSpeechToTextPlugin.swift:204:23
```

**✅ Solution**: 
- **Fixed**: iOS registrar scope issue in forked speech_to_text plugin
- **Changes**: Added registrar as instance variable, updated constructor
- **Status**: ✅ **FIXED** (similar to Android registrar fix)

#### **Speech-to-Text Plugin Instance Property Error**
```
Semantic Issue (Xcode): Property 'instance' not found on object of type 'SpeechToTextPlugin *'
SpeechToTextPlugin.m:16:10
```

**✅ Solution**: 
- **Fixed**: Removed unnecessary `handleMethodCall` method from Objective-C wrapper
- **Reason**: Swift class handles method calls directly after registration
- **Status**: ✅ **FIXED**

#### **Gradle Build Issues**
```
Gradle task 'bundleDebug' failed with exit code 1
```

**🔧 Solutions**:
1. **Clean build**: CodeMagic → Settings → "Clear cache and build"
2. **Check dependencies**: Ensure all packages are compatible
3. **Android Gradle Plugin**: May need version updates

#### **Missing Firebase Files**
```
google-services.json not found
```

**🔧 Solutions**:
1. **Verify file location**: `android/app/google-services.json`
2. **Check bundle ID**: Must match Firebase console (`com.mood_ai.moviesapp`)
3. **Re-download**: Get fresh file from Firebase console

### **iOS Build Failures**

#### **Build Shows '0' Logs**
This indicates the build failed before generating any output.

**🔧 Common Causes & Solutions**:

1. **Missing Apple Developer Setup**:
   - Ensure Apple Developer account is connected
   - Add App Store Connect API keys to CodeMagic

2. **Code Signing Issues**:
   - Use "Automatic code signing" in CodeMagic
   - Or manually upload certificates

3. **Bundle ID Mismatch**:
   - iOS: `com.mood-ai.moviesapp` (hyphens)
   - Check Firebase iOS app uses same bundle ID

4. **Missing iOS GoogleService-Info.plist**:
   - File must be in `ios/Runner/GoogleService-Info.plist`
   - Bundle ID in plist must match project

#### **Provisioning Profile Errors**
```
No provisioning profile found
```

**🔧 Solutions**:
1. **Enable automatic signing**: CodeMagic → iOS code signing → Automatic
2. **Register bundle ID**: In Apple Developer portal
3. **Use development certificates**: For Test Lab, production certs not needed

#### **Xcode Version Issues**
```
Unsupported Xcode version
```

**🔧 Solutions**:
1. **Update CodeMagic configuration**:
   ```yaml
   environment:
     xcode: latest # or specific version like 15.0
   ```

### **General Build Issues**

#### **Environment Variables Not Set**
```
Variable FIREBASE_TOKEN not found
```

**🔧 Solutions**:
1. **Set in CodeMagic dashboard**: Settings → Environment variables
2. **Mark as encrypted**: For sensitive values
3. **Verify names match**: Exactly as used in `codemagic.yaml`

#### **Build Timeout**
```
Build exceeded maximum duration
```

**🔧 Solutions**:
1. **Increase timeout**: In `codemagic.yaml`:
   ```yaml
   max_build_duration: 90 # minutes
   ```
2. **Enable caching**: Speed up builds
3. **Remove unused dependencies**: Reduce build time

## 🛠️ **Step-by-Step Debugging**

### **1. Check Local Build First**
Before debugging CodeMagic, ensure your app builds locally:

```bash
# Android
flutter build apk --debug

# iOS (if on macOS)
flutter build ios --debug --no-codesign
```

### **2. CodeMagic Build Logs**
1. **Click failed build** → "View build"
2. **Expand all sections** to see detailed logs
3. **Look for first error** (usually near the top of failures)

### **3. Common Log Locations**
- **Android**: "Build APK with Flutter" section
- **iOS**: "Flutter build ipa" section  
- **Dependencies**: "Get Flutter packages" section
- **Code signing**: "Set up code signing" section

### **4. Enable Verbose Logging**
Add to your `codemagic.yaml`:
```yaml
scripts:
  - name: Flutter build with verbose output
    script: |
      flutter build apk --verbose
```

## 🔍 **Debugging Checklist**

### **Before Each Build**:
- [ ] All files committed and pushed to repository
- [ ] No local build errors
- [ ] Firebase files in correct locations
- [ ] Bundle IDs match Firebase console

### **Android Issues**:
- [ ] `google-services.json` in `android/app/`
- [ ] Android bundle ID: `com.mood_ai.moviesapp`
- [ ] No conflicting Gradle plugins

### **iOS Issues**:
- [ ] `GoogleService-Info.plist` in `ios/Runner/`
- [ ] iOS bundle ID: `com.mood-ai.moviesapp`
- [ ] Apple Developer account connected
- [ ] Code signing configured

### **CodeMagic Setup**:
- [ ] Repository connected and webhook active
- [ ] Build triggers configured correctly
- [ ] Environment variables set (if using Firebase distribution)
- [ ] Sufficient build minutes remaining

## 🆘 **Still Having Issues?**

### **1. Test Minimal Configuration**
Remove all optional features and try basic build:
```yaml
# Minimal codemagic.yaml for testing
workflows:
  android-test:
    name: Android Test Build
    environment:
      flutter: stable
    scripts:
      - flutter pub get
      - flutter build apk --debug
    artifacts:
      - build/app/outputs/**/*.apk
```

### **2. Contact Support**
- **CodeMagic Support**: Build-specific issues
- **Firebase Support**: Firebase configuration issues
- **Flutter Community**: General Flutter build issues

### **3. Alternative Testing**
If CodeMagic continues failing:
- **Local builds**: Test Android locally
- **GitHub Actions**: Alternative CI/CD
- **Firebase Test Lab**: Direct IPA upload for testing

## 📊 **Build Status Meanings**

- **✅ Passed**: Build successful, artifacts available
- **❌ Failed**: Build error, check logs  
- **⚠️ Cancelled**: Manually stopped or timeout
- **🔄 Building**: Currently in progress
- **⏸️ Queued**: Waiting for available build slot 