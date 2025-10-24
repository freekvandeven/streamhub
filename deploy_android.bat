@echo off
echo Building Android APK...
flutter build apk --release

if not exist build\app\outputs\flutter-apk\app-release.apk (
    echo ERROR: APK build failed!
    exit /b 1
)

echo.
echo Uploading to Firebase App Distribution...
echo.
echo NOTE: You need to replace YOUR_APP_ID in this script with your actual Firebase App ID
echo Get it from: https://console.firebase.google.com/project/streamhub-pro/settings/general
echo.

firebase appdistribution:distribute build\app\outputs\flutter-apk\app-release.apk ^
  --app YOUR_APP_ID ^
  --groups testers ^
  --release-notes "StreamHub Android build - %date% %time%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Upload complete!
    echo Testers will receive a notification to download the app.
) else (
    echo.
    echo ERROR: Upload failed. Make sure:
    echo 1. You've registered your Android app in Firebase Console
    echo 2. You've replaced YOUR_APP_ID in this script with your actual App ID
    echo 3. You've created the "testers" group: firebase appdistribution:group:create testers
    echo 4. google-services.json is in android/app/ directory
    echo.
    echo See FIREBASE_ANDROID_SETUP.md for detailed instructions.
)
