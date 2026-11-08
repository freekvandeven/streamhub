import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:hive/hive.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/models/playlist.dart";
import "package:streamhub/services/playlist_storage.dart";

List<Channel> _channels(int count, {String prefix = "Channel"}) => [
  for (var i = 0; i < count; i++)
    Channel(
      name: "$prefix $i",
      url: "http://stream/$prefix/$i",
      tvgLogo: i.isEven ? "http://logo/$i" : null,
      groupTitle: i.isEven ? "News" : "Sports",
    ),
];

Playlist _playlist(String id, {String name = "Test", List<Channel>? channels}) {
  return Playlist(
    id: id,
    name: name,
    url: "http://example.com/$id.m3u",
    channels: channels ?? _channels(5),
    lastUpdate: DateTime.utc(2025),
  );
}

void main() {
  late Directory hiveDir;
  // Small chunks, so the tests cover playlists spread over several of them
  final storage = HivePlaylistStorage(chunkSize: 2);

  Future<List<String>> chunkKeys() async {
    final box = await Hive.openLazyBox<dynamic>("playlist_channels");
    return box.keys.cast<String>().toList();
  }

  setUp(() async {
    hiveDir = await Directory.systemTemp.createTemp("streamhub_storage_");
    Hive.init(hiveDir.path);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    await hiveDir.delete(recursive: true);
  });

  test("saves and loads playlists spread over several chunks", () async {
    await storage.savePlaylist(_playlist("1"));
    await storage.savePlaylist(_playlist("2", channels: _channels(3, prefix: "Other")));

    final playlists = await storage.loadAllPlaylists();
    expect(playlists.map((p) => p.id), ["1", "2"]);
    expect(playlists.first.lastUpdate, DateTime.utc(2025));
    expect(playlists.first.channels.map((c) => c.name), [for (var i = 0; i < 5; i++) "Channel $i"]);
    expect(playlists.first.channels.first.tvgLogo, "http://logo/0");
    expect(playlists.first.channels[1].tvgLogo, isNull);
    expect(playlists.last.channels.map((c) => c.groupTitle), ["News", "Sports", "News"]);
    // 5 channels in chunks of 2, and 3 channels
    expect(await chunkKeys(), hasLength(3 + 2));
  });

  test("replaces a playlist and removes the chunks it replaced", () async {
    await storage.savePlaylist(_playlist("1"));
    await storage.savePlaylist(_playlist("1", name: "Renamed", channels: _channels(1)));

    final playlists = await storage.loadAllPlaylists();
    expect(playlists.single.name, "Renamed");
    expect(playlists.single.channels.single.name, "Channel 0");
    expect(await chunkKeys(), hasLength(1));
  });

  test("keeps the stored playlist when a new version is discarded", () async {
    await storage.savePlaylist(_playlist("1"));

    final writer = storage.startWriting("1");
    _channels(4, prefix: "Partial").forEach(writer.add);
    await writer.flush();
    await writer.discard();

    final playlists = await storage.loadAllPlaylists();
    expect(playlists.single.channels.first.name, "Channel 0");
    expect(await chunkKeys(), hasLength(3));
  });

  test("removes a playlist with its chunks", () async {
    await storage.savePlaylist(_playlist("1"));
    await storage.savePlaylist(_playlist("2"));

    await storage.removePlaylist("1");

    expect((await storage.loadAllPlaylists()).map((p) => p.id), ["2"]);
    expect((await chunkKeys()).every((key) => key.startsWith("2/")), isTrue);
  });

  test("stores and clears the active playlist ID", () async {
    expect(await storage.getActivePlaylistId(), isNull);

    await storage.setActivePlaylistId("1");
    expect(await storage.getActivePlaylistId(), "1");

    await storage.setActivePlaylistId(null);
    expect(await storage.getActivePlaylistId(), isNull);
  });

  test("migrates playlists stored by earlier versions", () async {
    final box = await Hive.openBox<dynamic>("playlists");
    // The oldest format kept all playlists in one list...
    await box.put("all_playlists", [_playlist("1").toJson()]);
    // ...and the previous one each playlist with its channels inline
    await box.put("playlist:2", _playlist("2").toJson());
    await box.put("categorized_data", {"categoryTree": <String, dynamic>{}});
    await box.put("active_playlist_id", "2");

    final playlists = await storage.loadAllPlaylists();

    expect(playlists.map((p) => p.id), ["1", "2"]);
    expect(playlists.last.channels.map((c) => c.name), [for (var i = 0; i < 5; i++) "Channel $i"]);
    expect(await storage.getActivePlaylistId(), "2");
    expect(box.containsKey("all_playlists"), isFalse);
    expect(box.containsKey("categorized_data"), isFalse);
    expect((box.get("playlist:2") as Map).containsKey("channels"), isFalse);
  });
}
