# Firebase Deployment Guide

## Prerequisites
- Firebase CLI installed and authenticated
- Flutter SDK installed
- Firebase project: `streamhub-pro`

## Firebase Hosting (Web App)

### Deploy Web App
```bash
# Windows
deploy_web.bat

# Linux/Mac
./deploy_web.sh
```

This will:
1. Build the Flutter web app in release mode
2. Deploy to Firebase Hosting
3. Your app will be available at: https://streamhub-pro.web.app

### Manual Deployment
```bash
# Build the web app
flutter build web --release

# Deploy to Firebase
firebase deploy --only hosting
```

## Firebase App Distribution (Android APK)

### Setup (First Time Only)

1. **Register your Android app in Firebase Console:**
   - Go to https://console.firebase.google.com/project/streamhub-pro
   - Click "Add app" and select Android
   - Package name: `com.example.streamhub` (or your package name from `android/app/build.gradle`)
   - Register app and download `google-services.json`
   - Place `google-services.json` in `android/app/` directory

2. **Add Firebase dependencies to Android:**
   Add to `android/build.gradle`:
   ```gradle
   buildscript {
       dependencies {
           classpath 'com.google.gms:google-services:4.3.15'
       }
   }
   ```

   Add to `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

3. **Get your Android App ID:**
   - In Firebase Console, go to Project Settings > Your apps
   - Copy the App ID (format: `1:123456789:android:abc123def456`)
   - Update the `--app` parameter in `deploy_android.bat` and `deploy_android.sh`

4. **Create a tester group:**
   ```bash
   firebase appdistribution:group:create testers
   ```

5. **Add testers to the group:**
   ```bash
   firebase appdistribution:testers:add tester@example.com --group testers
   ```

### Deploy Android APK
```bash
# Windows
deploy_android.bat

# Linux/Mac
./deploy_android.sh
```

This will:
1. Build the Android APK in release mode
2. Upload to Firebase App Distribution
3. Notify testers in the "testers" group

### Manual Deployment
```bash
# Build the APK
flutter build apk --release

# Upload to Firebase App Distribution
firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
  --app YOUR_APP_ID \
  --groups testers \
  --release-notes "Your release notes here"
```

## Managing Testers

### Add testers
```bash
firebase appdistribution:testers:add email1@example.com email2@example.com --group testers
```

### Remove testers
```bash
firebase appdistribution:testers:remove email@example.com --group testers
```

### List testers
```bash
firebase appdistribution:testers:list --group testers
```

## Troubleshooting

### "App not found" error
- Make sure you've registered your Android app in Firebase Console
- Verify the App ID in the deploy scripts matches your Firebase Android app
- Check that you're using the correct Firebase project: `firebase use streamhub-pro`

### Web deployment shows old version
- Clear browser cache or use incognito mode
- The cache headers in `firebase.json` are configured to cache static assets but not HTML

### APK signing issues
- For release builds, ensure you have a proper keystore configured
- See `android/app/build.gradle` for signing configuration
- For testing, you can use debug builds: `flutter build apk --debug`

## Quick Reference

### Check current Firebase project
```bash
firebase projects:list
firebase use
```

### Switch Firebase project
```bash
firebase use streamhub-pro
```

### View deployment history
```bash
firebase hosting:channel:list
```

### View App Distribution releases
```bash
firebase appdistribution:releases:list --app YOUR_APP_ID
```
