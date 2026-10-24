@echo off

rem Firebase App ID of the Android app in the streamhub-pro project
set FIREBASE_APP_ID=1:419674510389:android:877f11c87bbeab4c784d7c

echo Building Android APK...
flutter build apk --release

if not exist build\app\outputs\flutter-apk\app-release.apk (
    echo ERROR: APK build failed!
    exit /b 1
)

echo.
echo Uploading to Firebase App Distribution...
echo.

firebase appdistribution:distribute build\app\outputs\flutter-apk\app-release.apk ^
  --app %FIREBASE_APP_ID% ^
  --groups testers ^
  --release-notes "StreamHub Android build - %date% %time%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo Upload complete!
    echo Testers will receive a notification to download the app.
) else (
    echo.
    echo ERROR: Upload failed. Make sure:
    echo 1. App Distribution is enabled: open
    echo    https://console.firebase.google.com/project/streamhub-pro/appdistribution
    echo    and click "Get started"
    echo 2. The "testers" group exists:
    echo    firebase appdistribution:groups:create Testers testers
    echo.
    exit /b 1
)
