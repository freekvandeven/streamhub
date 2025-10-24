# Firebase Android Setup

## Steps to Complete Firebase Android Integration

1. **Register Android App in Firebase Console:**
   - Go to: https://console.firebase.google.com/project/streamhub-pro/overview
   - Click the Android icon or "Add app" button
   - Enter package name: `com.streamhub.app`
   - App nickname: StreamHub (optional)
   - Click "Register app"

2. **Download google-services.json:**
   - After registering, download the `google-services.json` file
   - Place it in: `android/app/google-services.json`

3. **Copy Your Firebase App ID:**
   - In the Firebase Console, go to: Project Settings > Your apps
   - Under the Android app you just created, copy the "App ID"
   - It looks like: `1:123456789012:android:abc123def456ghi789`
   - Update this ID in the deployment scripts:
     - `deploy_android.bat` (line with `--app`)
     - `deploy_android.sh` (line with `--app`)

4. **Create Tester Group:**
   ```bash
   firebase appdistribution:group:create testers
   ```

5. **Add Testers:**
   ```bash
   firebase appdistribution:testers:add your-email@example.com --group testers
   ```

6. **Test the Setup:**
   ```bash
   # Build APK
   flutter build apk --release

   # Upload to App Distribution (replace YOUR_APP_ID with actual ID from step 3)
   firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk \
     --app YOUR_APP_ID \
     --groups testers \
     --release-notes "Test build"
   ```

## What's Already Configured

✅ Package name changed from `com.example.iptv_app` to `com.streamhub.app`
✅ Google Services plugin added to Gradle configuration
✅ Firebase project configured: `streamhub-pro`
✅ Deployment scripts created (`deploy_android.bat` and `deploy_android.sh`)

## Next Steps After Setup

Once you've completed the steps above and updated the scripts with your App ID, you can deploy using:

```bash
# Windows
deploy_android.bat

# Linux/Mac
./deploy_android.sh
```

## Troubleshooting

### "google-services.json not found" error
- Make sure you downloaded the file from Firebase Console
- Place it in `android/app/` directory (not `android/`)
- Restart your IDE/editor after adding the file

### "App not registered" error
- Verify the package name in Firebase Console matches: `com.streamhub.app`
- Make sure you completed step 1 above

### Gradle sync failed
- Run `flutter clean`
- Run `flutter pub get`
- Try building again: `flutter build apk`
