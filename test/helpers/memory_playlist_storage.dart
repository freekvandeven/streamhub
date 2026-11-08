import "package:streamhub/models/channel.dart";
import "package:streamhub/models/playlist.dart";
import "package:streamhub/services/playlist_storage.dart";

/// Keeps playlists in memory, for tests that can't wait for file IO
class MemoryPlaylistStorage implements PlaylistStorage {
  MemoryPlaylistStorage([List<Playlist> playlists = const []]) {
    for (final playlist in playlists) {
      this.playlists[playlist.id] = playlist;
    }
  }

  final playlists = <String, Playlist>{};
  String? activePlaylistId;

  @override
  Future<List<Playlist>> loadAllPlaylists() async => playlists.values.toList();

  @override
  PlaylistWriter startWriting(String playlistId) => _MemoryPlaylistWriter(this);

  @override
  Future<void> removePlaylist(String playlistId) async => playlists.remove(playlistId);

  @override
  Future<String?> getActivePlaylistId() async => activePlaylistId;

  @override
  Future<void> setActivePlaylistId(String? playlistId) async => activePlaylistId = playlistId;
}

class _MemoryPlaylistWriter implements PlaylistWriter {
  _MemoryPlaylistWriter(this._storage);

  final MemoryPlaylistStorage _storage;
  final _channels = <Channel>[];

  @override
  void add(Channel channel) => _channels.add(channel);

  @override
  Future<void> flush() async {}

  @override
  Future<void> commit(Playlist playlist) async {
    _storage.playlists[playlist.id] = playlist.copyWith(channels: List.of(_channels));
  }

  @override
  Future<void> discard() async => _channels.clear();
}
