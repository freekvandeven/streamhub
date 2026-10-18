import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/models/playlist.dart";
import "package:streamhub/services/playlist_storage.dart";

Playlist _playlist(String id, {String name = "Test"}) {
  return Playlist(
    id: id,
    name: name,
    url: "http://example.com/$id.m3u",
    channels: const [
      Channel(
        name: "Channel",
        url: "http://stream/1",
        tvgLogo: "http://logo",
        groupTitle: "News",
      ),
    ],
    lastUpdate: DateTime.utc(2025),
  );
}

void main() {
  late Directory hiveDir;

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp("streamhub_storage_");
    Hive.init(hiveDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await hiveDir.delete(recursive: true);
  });

  test("saves, updates and removes playlists", () async {
    await PlaylistStorage.savePlaylist(_playlist("1"));
    await PlaylistStorage.savePlaylist(_playlist("2"));
    await PlaylistStorage.savePlaylist(_playlist("1", name: "Renamed"));

    var playlists = await PlaylistStorage.loadAllPlaylists();
    expect(playlists.map((p) => p.id), ["1", "2"]);
    expect(playlists.first.name, "Renamed");
    expect(playlists.first.lastUpdate, DateTime.utc(2025));
    expect(playlists.first.channels.single.groupTitle, "News");
    expect(playlists.first.channels.single.tvgLogo, "http://logo");

    await PlaylistStorage.removePlaylist("1");
    playlists = await PlaylistStorage.loadAllPlaylists();
    expect(playlists.map((p) => p.id), ["2"]);
  });

  test("stores and clears the active playlist ID", () async {
    expect(await PlaylistStorage.getActivePlaylistId(), isNull);

    await PlaylistStorage.setActivePlaylistId("1");
    expect(await PlaylistStorage.getActivePlaylistId(), "1");

    await PlaylistStorage.setActivePlaylistId(null);
    expect(await PlaylistStorage.getActivePlaylistId(), isNull);
  });

  test("migrates playlists from the legacy single-list format", () async {
    final box = await Hive.openBox<dynamic>("playlists");
    await box.put("all_playlists", [
      _playlist("1").toJson(),
      _playlist("2").toJson(),
    ]);
    await box.put("categorized_data", {"categoryTree": <String, dynamic>{}});
    await box.put("active_playlist_id", "2");

    final playlists = await PlaylistStorage.loadAllPlaylists();

    expect(playlists.map((p) => p.id), ["1", "2"]);
    expect(playlists.first.channels.single.name, "Channel");
    expect(await PlaylistStorage.getActivePlaylistId(), "2");
    expect(box.containsKey("all_playlists"), isFalse);
    expect(box.containsKey("categorized_data"), isFalse);
  });
}
