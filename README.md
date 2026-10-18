# StreamHub

A cross-platform M3U playlist player built with Flutter.

## Features

- Load M3U playlists from any URL
- Play live channels, movies, and series
- Search and filter categories and channels
- Automatic category grouping for channels without a `group-title`
- Clean architecture with Riverpod

## Quick Start

```bash
flutter pub get
echo "PLAYLIST_URL=https://your-playlist.m3u" > dotenv
flutter run
```

## Tests

```bash
flutter test
```

## Platforms

- **Mobile/Desktop**: Works with any playlist
- **Web**: Requires CORS-enabled playlists

## License

MIT
