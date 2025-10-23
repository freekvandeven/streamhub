# StreamHub - M3U Playlist Player

A Flutter application for loading and displaying M3U playlists from various legal streaming sources.

## 🎯 What is StreamHub?

StreamHub is a **provider-agnostic** M3U playlist player that works with any standard M3U playlist source. Think of it as a modern, cross-platform alternative to VLC Media Player, specifically designed for M3U playlist streaming.

### ⚖️ Legal Notice

**StreamHub is designed for streaming legal content only.** This app is a generic M3U playlist player that does not provide, host, or facilitate access to any content. Users are solely responsible for ensuring they have the legal right to stream any content they access through this application.

## � Features

- 📺 Load M3U playlists from any URL
- 🔍 Search and filter channels/streams
- 📂 Channels automatically grouped by category
- 🎯 Clean architecture with Riverpod state management
- 🧭 Modern navigation with go_router
- 🪝 Reactive UI with hooks (zero StatefulWidgets)
- 🔐 Secure environment variable management

## 🏗️ Tech Stack

- **Flutter** - UI framework
- **Riverpod** - State management (manual, no code generation)
- **go_router** - Navigation
- **flutter_hooks** - Reactive state management
- **http** - Network requests

## 📁 Project Structure

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

## 🎬 Supported Content Sources

StreamHub works with M3U playlists from any legitimate source:

### Self-Hosted Media
- **Plex Media Server** - Stream your personal media library
- **Jellyfin** - Open-source media system
- **Emby** - Personal media server
- **Universal Media Server** - DLNA-compliant media server

### Streaming Services
- Services that provide M3U export functionality
- Legal streaming platforms with M3U support

### Audio Content
- **Internet Radio** - Thousands of radio stations via M3U
- **Podcasts** - Podcast feeds in M3U format
- **Personal Music Libraries** - Your own audio content

### Other Legal Sources
- Educational content
- Public domain media
- Licensed content you have access to

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd streamhub
```

2. Install dependencies:
```bash
flutter pub get

```

```

lib/5. Run the app:
```bash
# For Android/iOS
flutter run -d <device-id>

# For Chrome with CORS disabled (development only)
flutter run -d chrome --web-browser-flag="--disable-web-security"

│   └── app_router.dart                # Route configuration# Or use the provided script:

├── screens/./run_chrome.sh   # Linux/macOS

│   ├── home_screen.dart               # URL input screenrun_chrome.bat    # Windows

│   └── channels_screen.dart           # Channels list screen

├── services/# For desktop

│   └── m3u_parser.dart                # M3U playlist parserflutter run -d windows

└── utils/```

    └── logger.dart                    # Debug logging utility

```> **Note:** When running on Chrome, use the `--web-browser-flag="--disable-web-security"` flag to bypass CORS restrictions for development. See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for details.



## 🚀 Getting Started## Usage



### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK

### Installation

1. Clone the repository:
```bash
git clone <your-repo-url>
cd streamhub
```

2. Install dependencies:
```bash
flutter pub get
```

3. Create your environment file:
```bash
touch dotenv
```

4. Add your playlist URL to `dotenv`:
```env
PLAYLIST_URL=http://example.com/playlist.m3u
```

5. Run the app:
```bash
# For Android/iOS
flutter run -d <device-id>

# For Chrome with CORS disabled (development only)
flutter run -d chrome --web-browser-flag="--disable-web-security"

# For desktop
flutter run -d windows
```

## Usage

1. **Enter Playlist URL**: On the home screen, enter your M3U playlist URL in the format:
   ```
   http://example.com/playlist.m3u
   ```

2. **Load Playlist**: Click the "Load Playlist" button to fetch and parse the playlist



1. Clone the repository:3. **View Channels**: Once loaded, click "View Channels" to see the channel list

```bash

git clone <your-repo-url>4. **Browse Channels**:

3. **View Channels**: Once loaded, click "View Channels" to see the channel list

4. **Browse Channels**:
   - Channels are grouped by category
   - Use the search bar to filter channels
   - Expand/collapse categories to browse

## How It Works

### M3U Playlist Parsing



3. Create your environment file:The app parses M3U playlists which have the following format:

```bash

touch dotenv```

```#EXTM3U

#EXTINF:-1 tvg-id="channel1" tvg-name="Channel Name" tvg-logo="logo.png" group-title="Sports",Channel Name

4. Add your playlist URL to `dotenv`:http://stream-url.com/channel1

```env#EXTINF:-1 tvg-id="channel2" tvg-name="Another Channel" group-title="Movies",Another Channel

PLAYLIST_URL=http://your-service.com/playlist.m3uhttp://stream-url.com/channel2

``````



5. Run the app:The parser extracts:

```bash- Channel name

# For Android/iOS- Stream URL

flutter run- TVG metadata (ID, name, logo)

- Group/category information

# For web with CORS disabled (development only)

flutter run -d chrome --web-browser-flag="--disable-web-security"### State Management

# Or use: ./run_chrome.sh (Linux/macOS) or run_chrome.bat (Windows)

The app uses Riverpod for state management without code generation:

# For desktop

flutter run -d windows- `PlaylistNotifier` extends `StateNotifier` to manage playlist state

```- `playlistProvider` is a `StateNotifierProvider` for accessing state

- State is immutable and updates trigger UI rebuilds

> **Note:** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for platform-specific issues.- No StatefulWidgets - all state is managed through hooks and providers



## 📖 Usage### Architecture



1. **Enter Playlist URL**: On the home screen, enter your M3U playlist URL- **Models**: Data structures (Channel)

2. **Load Playlist**: Click "Load Playlist" to fetch and parse the playlist- **Services**: Business logic (M3U parser, HTTP client)

3. **View Channels**: Click "View Channels" to see the parsed streams- **Providers**: State management (Riverpod)

4. **Browse & Search**: - **Screens**: UI components (HookConsumerWidget)

   - Channels are automatically grouped by category- **Router**: Navigation configuration (go_router)

   - Use the search bar to filter by name or category

   - Expand/collapse categories to browse## Future Enhancements



## 🔧 How It Works- [ ] Video playback with media player

- [ ] Favorites/bookmarks

### Provider-Agnostic Architecture- [ ] EPG (Electronic Program Guide) support

- [ ] Picture-in-Picture mode

StreamHub is intentionally provider-agnostic by design:- [ ] Chromecast support

- [ ] Offline playlist storage

1. **Standard M3U Format**: Uses the universal M3U playlist format that 90%+ of streaming services support- [ ] Multiple playlist management

2. **No Hardcoded Providers**: No provider-specific URLs, authentication, or logic

3. **User-Provided Sources**: Users bring their own legitimate playlist URLs## Notes

4. **Generic Parser**: The M3U parser works with any standard-compliant M3U file

### Limitations

- This is a proof of concept focused on playlist loading and parsing
- Video playback is not yet implemented
- Requires a valid M3U playlist URL to work

### M3U Playlist Format

M3U is an open standard playlist format supported by:

- VLC Media Player
- iTunes
- Winamp

## License

This is a proof of concept project for demonstration purposes.

- Most media servers and streaming services


Example M3U format:
```
#EXTM3U
#EXTINF:-1 tvg-id="ch1" tvg-name="Channel 1" tvg-logo="logo.png" group-title="Category",Channel Name
http://stream-url.com/channel1
#EXTINF:-1 tvg-id="ch2" tvg-name="Channel 2" group-title="Category",Another Channel
http://stream-url.com/channel2
```

The parser extracts:
- Channel/Stream name
- Stream URL
- Metadata (ID, logo, category)
- Group/category information

### State Management

- **Riverpod** without code generation for simplicity
- `PlaylistNotifier` extends `StateNotifier` for immutable state
- `playlistProvider` provides global state access
- All widgets are `HookConsumerWidget` (no StatefulWidgets)

## 🔒 Privacy & Security

### Environment Variables

All sensitive data is managed through environment variables:
- Credentials never committed to git
- `.gitignore` pattern blocks all `dotenv*` files
- Each developer maintains their own local configuration

See [ENVIRONMENT.md](ENVIRONMENT.md) for detailed setup.

### Network Security

- Comprehensive error handling for network issues
- SSL/TLS error detection
- Timeout protection (300 second default)
- CORS handling for web development

## 🛠️ Development

### Pre-commit Hooks

The project uses pre-commit hooks to maintain code quality:

```bash
# Install pre-commit hooks
pre-commit install

# Hooks include:
# - Dart formatting (dart format)
# - Flutter analysis (flutter analyze)
# - Unit tests (flutter test)
# - YAML validation
# - Line ending fixes
```

See [HOOKS.md](HOOKS.md) for more information.

### Code Quality

- Custom linter rules via `flutter_iconica_analysis`
- All code formatted with `dart format`
- Zero linter warnings
- Comprehensive error handling

### Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## 🚧 Future Enhancements

- [ ] **Video playback** with media player integration
- [ ] **EPG support** (Electronic Program Guide)
- [ ] **Favorites/Bookmarks** for quick access
- [ ] **Picture-in-Picture** mode
- [ ] **Chromecast** support
- [ ] **Offline playlist** storage
- [ ] **Multiple playlist** management
- [ ] **XSPF playlist** format support
- [ ] **JSON playlist** format support
- [ ] **Adaptive streaming** (HLS, DASH)

## 🤝 Contributing

Contributions are welcome! This project is designed to:
- Remain provider-agnostic
- Support legal content streaming only
- Follow Flutter best practices
- Maintain clean architecture

## 📄 License

This is a proof of concept project for demonstration purposes.

## 🙏 Acknowledgments

- Built with Flutter and Dart
- Uses the M3U standard format
- Inspired by VLC Media Player's approach to playlist handling

---

**Remember**: StreamHub is a tool for playing M3U playlists. The legality of content depends entirely on what you choose to stream. Always ensure you have proper authorization for any content you access.
