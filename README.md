# IPTV Streaming App - Proof of Concept

A Flutter application for loading and displaying IPTV playlists in M3U format.

## Features

- 📺 Load M3U playlists from URL
- 🔍 Search and filter channels
- 📂 Channels grouped by category
- 🎯 Clean architecture with Riverpod state management
- 🧭 Navigation with go_router
- 🪝 Hook-based widgets (no StatefulWidgets)

## Tech Stack

- **Flutter** - UI framework
- **Riverpod** - State management (manual, no code generation)
- **go_router** - Navigation
- **flutter_hooks** - Reactive state management
- **http** - Network requests

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/
│   └── channel.dart                   # Channel data model
├── providers/
│   └── playlist_provider.dart         # Playlist state management
├── router/
│   └── app_router.dart                # Route configuration
├── screens/
│   ├── home_screen.dart               # URL input screen
│   └── channels_screen.dart           # Channels list screen
└── services/
    └── m3u_parser.dart                # M3U playlist parser
```

## Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK

### Installation

1. Navigate to the app directory:
```bash
cd iptv_poc
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
# For Android/iOS (recommended for IPTV URLs)
flutter run -d <device-id>

# For Chrome with CORS disabled (development only)
flutter run -d chrome --web-browser-flag="--disable-web-security"
# Or use the provided script:
./run_chrome.sh   # Linux/macOS
run_chrome.bat    # Windows

# For desktop
flutter run -d windows
```

> **Note:** When running on Chrome, use the `--web-browser-flag="--disable-web-security"` flag to bypass CORS restrictions for development. See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for details.

## Usage

1. **Enter Playlist URL**: On the home screen, enter your IPTV playlist URL in the format:
   ```
   http://odm391.xyz/get.php?username=YOUR_USERNAME&password=YOUR_PASSWORD&type=m3u&output=mpegts
   ```

2. **Load Playlist**: Click the "Load Playlist" button to fetch and parse the playlist

3. **View Channels**: Once loaded, click "View Channels" to see the channel list

4. **Browse Channels**: 
   - Channels are grouped by category
   - Use the search bar to filter channels
   - Expand/collapse categories to browse

## How It Works

### M3U Playlist Parsing

The app parses M3U playlists which have the following format:

```
#EXTM3U
#EXTINF:-1 tvg-id="channel1" tvg-name="Channel Name" tvg-logo="logo.png" group-title="Sports",Channel Name
http://stream-url.com/channel1
#EXTINF:-1 tvg-id="channel2" tvg-name="Another Channel" group-title="Movies",Another Channel
http://stream-url.com/channel2
```

The parser extracts:
- Channel name
- Stream URL
- TVG metadata (ID, name, logo)
- Group/category information

### State Management

The app uses Riverpod for state management without code generation:

- `PlaylistNotifier` extends `StateNotifier` to manage playlist state
- `playlistProvider` is a `StateNotifierProvider` for accessing state
- State is immutable and updates trigger UI rebuilds
- No StatefulWidgets - all state is managed through hooks and providers

### Architecture

- **Models**: Data structures (Channel)
- **Services**: Business logic (M3U parser, HTTP client)
- **Providers**: State management (Riverpod)
- **Screens**: UI components (HookConsumerWidget)
- **Router**: Navigation configuration (go_router)

## Future Enhancements

- [ ] Video playback with media player
- [ ] Favorites/bookmarks
- [ ] EPG (Electronic Program Guide) support
- [ ] Picture-in-Picture mode
- [ ] Chromecast support
- [ ] Offline playlist storage
- [ ] Multiple playlist management

## Notes

- This is a proof of concept focused on playlist loading and parsing
- Video playback is not yet implemented
- Requires a valid IPTV playlist URL to work

## License

This is a proof of concept project for demonstration purposes.

