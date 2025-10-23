# Quick Start Guide

## Running the App

```bash
# Chrome with CORS disabled (recommended for development)
flutter run -d chrome --web-browser-flag="--disable-web-security"

# Or use the provided script:
./run_chrome.sh   # Linux/macOS
run_chrome.bat    # Windows

# Android/iOS
flutter run -d <device-id>
```

## What You Can Do

1. **Load a Playlist**
   - Enter your IPTV playlist URL on the home screen
   - Format: `http://domain.com/get.php?username=XXX&password=YYY&type=m3u&output=mpegts`
   - Click "Load Playlist"

2. **View Channels**
   - After loading, click "View Channels"
   - Browse channels grouped by category
   - Search for specific channels

## Key Features Implemented

✅ Clean architecture with Riverpod state management  
✅ Navigation using go_router  
✅ All widgets use HookWidget (no StatefulWidget)  
✅ M3U playlist parser  
✅ HTTP playlist fetching  
✅ Channel grouping and filtering  
✅ Error handling  

## Code Structure

- `lib/main.dart` - App entry with ProviderScope
- `lib/models/channel.dart` - Channel data model
- `lib/services/m3u_parser.dart` - M3U parsing logic
- `lib/providers/playlist_provider.dart` - State management
- `lib/router/app_router.dart` - Route configuration
- `lib/screens/home_screen.dart` - URL input (HookConsumerWidget)
- `lib/screens/channels_screen.dart` - Channel list (HookConsumerWidget)

## Next Steps for Full Implementation

- Add video player (e.g., video_player or better_player package)
- Implement channel playback
- Add favorites/bookmarks
- Persist playlist data locally
- EPG support
