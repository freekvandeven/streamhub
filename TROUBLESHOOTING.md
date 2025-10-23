# StreamHub Troubleshooting

## Common Error: "ClientException: Failed to fetch"

If you're seeing this error when trying to load a playlist that works on your TV, here are the likely causes and solutions:

### 🌐 Problem 1: CORS (Cross-Origin Resource Sharing) - Web/Desktop Only

**Why it happens:**
- When running on Chrome, Edge, or desktop, browsers block HTTP requests to servers that don't allow cross-origin requests
- Streaming servers typically don't send CORS headers since they're designed for media players, not web browsers

**Solution:**
- ✅ **Run on Android or iOS** - Mobile apps don't have CORS restrictions
- ✅ **Disable web security in Chrome** (development only):
  ```bash
  flutter run -d chrome --web-browser-flag="--disable-web-security"
  ```
  Or use the provided scripts: `run_chrome.sh` (Linux/macOS) or `run_chrome.bat` (Windows)
- ⚠️ For development on web, you can use a CORS proxy (not recommended for production)

> **Warning:** Running Chrome with `--disable-web-security` disables important security features. Only use this for development and never browse other websites while this flag is active.

### 🔒 Problem 2: SSL/TLS Certificate Issues

**Why it happens:**
- Many streaming providers use self-signed or invalid SSL certificates
- Desktop/web browsers strictly enforce SSL validation

**Solution:**
- Run on mobile devices where you can configure SSL handling
- The app will show "SSL/TLS error" specifically if this is the issue

### 📱 Recommended Testing Platforms

**✅ Best:** Android or iOS device
```bash
flutter run -d <device-id>
```

**✅ Good for Development:** Chrome with CORS disabled
```bash
flutter run -d chrome --web-browser-flag="--disable-web-security"
```

**⚠️ Limited:** Chrome/Edge (CORS issues with external URLs unless security is disabled)
```bash
flutter run -d chrome
```

**⚠️ Limited:** Windows/macOS/Linux desktop
```bash
flutter run -d windows
flutter run -d macos  
flutter run -d linux
```

### 🔍 Debugging Steps

1. **Check the console logs** - Look for detailed error messages with emojis:
   - ℹ️ Info messages
   - ✅ Success messages  
   - ❌ Error messages
   - 🌐 Network details
   - 📦 Response data

2. **Try on mobile first** - If it works on mobile but not desktop/web, it's a CORS issue

3. **Check the error type:**
   - "Connection timeout" = Server is slow or unreachable
   - "Network error" = Internet connection issue
   - "SSL/TLS error" = Certificate problem
   - "HTTP XXX" = Server returned an error code
   - "ClientException" on web = Usually CORS

### 🛠️ Testing on Android

1. Connect your Android device via USB
2. Enable USB debugging on your phone
3. Run: `flutter devices` to see available devices
4. Run: `flutter run -d <your-device-id>`

### 🛠️ Testing on iOS

1. Connect your iPhone via USB
2. Run: `flutter devices`
3. Run: `flutter run -d <your-device-id>`

### 💡 Why Your TV Works

Your TV app likely:
- Uses native HTTP libraries (no browser restrictions)
- Doesn't enforce strict SSL validation
- Runs natively without CORS limitations

### ⚡ Quick Test

Try this test URL that supports CORS:
```
https://iptv-org.github.io/iptv/index.m3u
```

If this works but your playlist URL doesn't, it confirms a CORS issue.

## Platform Compatibility

| Platform | CORS Issues | SSL Issues | Recommended |
|----------|------------|------------|-------------|
| Android  | ❌ No      | ⚠️ Configurable | ✅ Yes |
| iOS      | ❌ No      | ⚠️ Configurable | ✅ Yes |
| Web      | ✅ Yes     | ✅ Yes     | ❌ No |
| Windows  | ⚠️ Sometimes | ⚠️ Sometimes | ⚠️ Limited |
| macOS    | ⚠️ Sometimes | ⚠️ Sometimes | ⚠️ Limited |
| Linux    | ⚠️ Sometimes | ⚠️ Sometimes | ⚠️ Limited |
