import "dart:convert";
import "dart:io";
import "dart:math";

import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/models/playlist.dart";
import "package:streamhub/providers/playlists_provider.dart";
import "package:streamhub/services/playlist_storage.dart";

import "helpers/memory_playlist_storage.dart";

List<int> _playlist(int count) => utf8.encode(
  [
    "#EXTM3U",
    for (var i = 0; i < count; i++) ...['#EXTINF:-1 group-title="Group ${i % 10}",Channel $i', "http://stream/$i.ts"],
  ].join("\n"),
);

void main() {
  late HttpServer server;
  late String url;

  /// Starts a container with the playlists in [storage] loaded
  Future<ProviderContainer> start(MemoryPlaylistStorage storage) async {
    final container = ProviderContainer(overrides: [playlistStorageProvider.overrideWithValue(storage)]);
    addTearDown(container.dispose);
    container.read(playlistsProvider);
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    url = "http://127.0.0.1:${server.port}/playlist.m3u";
  });

  tearDown(() => server.close(force: true));

  test("streams a large playlist into storage", () async {
    final body = _playlist(20000);
    server.listen((request) async {
      request.response.contentLength = body.length;
      // Send it in pieces, like a real server would
      for (var i = 0; i < body.length; i += 64 * 1024) {
        request.response.add(body.sublist(i, min(i + 64 * 1024, body.length)));
        await request.response.flush();
      }
      await request.response.close();
    });
    final storage = MemoryPlaylistStorage();
    final container = await start(storage);

    await container.read(playlistsProvider.notifier).fetchPlaylist(url: url, name: "Big");

    final state = container.read(playlistsProvider);
    expect(state.error, isNull);
    expect(state.isLoading, isFalse);
    expect(state.playlists.single.channels, hasLength(20000));
    expect(state.playlists.single.channels.last.name, "Channel 19999");
    expect(storage.playlists.values.single.channels, hasLength(20000));
  });

  test("keeps the stored playlist when a refresh fails partway", () async {
    final body = _playlist(1000);
    server.listen((request) async {
      request.response.contentLength = body.length;
      request.response.add(body.sublist(0, body.length ~/ 2));
      await request.response.flush();
      // Drop the connection before the end
      try {
        await request.response.close();
      } on HttpException {
        // Expected: less was sent than announced
      }
    });
    final stored = Playlist(
      id: "1",
      name: "Saved",
      url: url,
      channels: const [Channel(name: "Saved channel", url: "http://stream/saved.ts")],
      lastUpdate: DateTime(2025),
    );
    final storage = MemoryPlaylistStorage([stored]);
    final container = await start(storage);

    await container.read(playlistsProvider.notifier).fetchPlaylist(url: url, name: "Saved", forceRefresh: true);

    final state = container.read(playlistsProvider);
    expect(state.error, isNotNull);
    expect(state.isLoading, isFalse);
    expect(state.playlists.single.channels.single.name, "Saved channel");
    expect(storage.playlists["1"]!.channels.single.name, "Saved channel");
  });
}
