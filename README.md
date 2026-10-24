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

## Test Playlists

Legal, free playlists to try the app with:

- [`samples/test_playlist.m3u`](samples/test_playlist.m3u): a few openly
  licensed films (Blender Foundation, CC BY) and public test streams.
  Load it from
  `https://raw.githubusercontent.com/freekvandeven/streamhub/master/samples/test_playlist.m3u`.
- [Free-TV/IPTV](https://github.com/Free-TV/IPTV): about 2,000 channels that
  broadcasters offer for free. Load it from
  `https://raw.githubusercontent.com/Free-TV/IPTV/master/playlist.m3u8`.

## Tests

```bash
flutter test
```

## Platforms

- **Mobile/Desktop**: Works with any playlist
- **Web**: Requires CORS-enabled playlists

## License

MIT
