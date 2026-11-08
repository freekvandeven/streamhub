import "package:hive_flutter/hive_flutter.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/models/playlist.dart";
import "package:streamhub/utils/logger.dart";

/// Stores playlists on the device
abstract interface class PlaylistStorage {
  /// Loads all playlists, oldest first
  Future<List<Playlist>> loadAllPlaylists();

  /// Starts writing the channels of the playlist with [playlistId]. The stored
  /// playlist is only replaced once [PlaylistWriter.commit] completes.
  PlaylistWriter startWriting(String playlistId);

  /// Removes a playlist by ID
  Future<void> removePlaylist(String playlistId);

  /// Gets the active playlist ID
  Future<String?> getActivePlaylistId();

  /// Sets the active playlist ID, or clears it when [playlistId] is null
  Future<void> setActivePlaylistId(String? playlistId);
}

/// Writes a playlist's channels as they come in, for example while it
/// downloads, so the whole playlist never has to be encoded at once
abstract interface class PlaylistWriter {
  /// Adds a channel. Channels are written in chunks by [flush] and [commit].
  void add(Channel channel);

  /// Writes the channels added so far, once there are enough for a chunk
  Future<void> flush();

  /// Writes the remaining channels and replaces the stored playlist
  Future<void> commit(Playlist playlist);

  /// Throws away the channels written so far
  Future<void> discard();
}

extension SavePlaylist on PlaylistStorage {
  /// Saves a playlist whose channels are all in memory
  Future<void> savePlaylist(Playlist playlist) async {
    final writer = startWriting(playlist.id);
    playlist.channels.forEach(writer.add);
    await writer.commit(playlist);
  }
}

final playlistStorageProvider = Provider<PlaylistStorage>((ref) => HivePlaylistStorage());

/// Stores playlist details in a regular box and their channels in chunks in a
/// lazy box. A regular box loads its whole file into memory, and a playlist
/// can be hundreds of megabytes, so channels are written and read one chunk at
/// a time and never kept in memory by Hive.
class HivePlaylistStorage implements PlaylistStorage {
  HivePlaylistStorage({this.chunkSize = 5000});

  /// Channels per stored chunk
  final int chunkSize;

  static const String _boxName = "playlists";
  static const String _channelsBoxName = "playlist_channels";
  static const String _playlistKeyPrefix = "playlist:";
  static const String _activePlaylistIdKey = "active_playlist_id";

  /// Keys written by earlier versions of the app
  static const String _legacyPlaylistsKey = "all_playlists";
  static const String _legacyCategorizedDataKey = "categorized_data";

  /// Fields stored per channel, in the order of [_encode]
  static const int _fieldsPerChannel = 6;

  Future<Box<dynamic>> _box() async {
    if (Hive.isBoxOpen(_boxName)) return Hive.box<dynamic>(_boxName);
    return Hive.openBox<dynamic>(_boxName);
  }

  Future<LazyBox<dynamic>> _channelsBox() async {
    if (Hive.isBoxOpen(_channelsBoxName)) return Hive.lazyBox<dynamic>(_channelsBoxName);
    return Hive.openLazyBox<dynamic>(_channelsBoxName);
  }

  static String _playlistKey(String playlistId) => "$_playlistKeyPrefix$playlistId";

  /// Chunks are versioned, so a refresh can be written next to the playlist it
  /// replaces and only take its place once complete
  static String _chunkKey(String playlistId, String version, int index) => "$playlistId/$version/$index";

  static List<String?> _encode(List<Channel> channels) => [
    for (final channel in channels) ...[
      channel.name,
      channel.url,
      channel.tvgId,
      channel.tvgName,
      channel.tvgLogo,
      channel.groupTitle,
    ],
  ];

  /// Adds the channels in [values] to [channels]. Category names are shared
  /// through [groups], since thousands of channels can have the same one.
  static void _decodeInto(List<dynamic> values, List<Channel> channels, Map<String, String> groups) {
    for (var i = 0; i + _fieldsPerChannel <= values.length; i += _fieldsPerChannel) {
      final group = values[i + 5] as String?;
      channels.add(
        Channel(
          name: values[i] as String,
          url: values[i + 1] as String,
          tvgId: values[i + 2] as String?,
          tvgName: values[i + 3] as String?,
          tvgLogo: values[i + 4] as String?,
          groupTitle: group == null ? null : groups.putIfAbsent(group, () => group),
        ),
      );
    }
  }

  @override
  Future<List<Playlist>> loadAllPlaylists() async {
    final box = await _box();
    await _migrateLegacyData(box);
    final channelsBox = await _channelsBox();

    final groups = <String, String>{};
    final playlists = <Playlist>[];
    // Hive returns keys sorted, and playlist IDs are creation timestamps
    for (final key in box.keys) {
      if (key is! String || !key.startsWith(_playlistKeyPrefix)) continue;

      final details = Map<String, dynamic>.from(box.get(key) as Map);
      final id = details["id"] as String;
      final version = details["version"] as String;
      final channels = <Channel>[];
      for (var index = 0; index < (details["chunkCount"] as int); index++) {
        final values = await channelsBox.get(_chunkKey(id, version, index)) as List<dynamic>?;
        if (values != null) _decodeInto(values, channels, groups);
      }

      playlists.add(
        Playlist(
          id: id,
          name: details["name"] as String,
          url: details["url"] as String,
          channels: channels,
          lastUpdate: DateTime.parse(details["lastUpdate"] as String),
        ),
      );
    }

    Logger.info("Loaded ${playlists.length} playlists from storage");
    return playlists;
  }

  @override
  PlaylistWriter startWriting(String playlistId) => _HivePlaylistWriter(this, playlistId);

  @override
  Future<void> removePlaylist(String playlistId) async {
    final box = await _box();
    await box.delete(_playlistKey(playlistId));
    await _deleteChunks(playlistId);
    Logger.success("Removed playlist");
  }

  @override
  Future<String?> getActivePlaylistId() async {
    final box = await _box();
    return box.get(_activePlaylistIdKey) as String?;
  }

  @override
  Future<void> setActivePlaylistId(String? playlistId) async {
    final box = await _box();
    if (playlistId == null) {
      await box.delete(_activePlaylistIdKey);
    } else {
      await box.put(_activePlaylistIdKey, playlistId);
    }
  }

  /// Deletes the stored chunks of [playlistId]: only those of [version] if
  /// given, otherwise all of them except those of [keepVersion]
  Future<void> _deleteChunks(String playlistId, {String? version, String? keepVersion}) async {
    final channelsBox = await _channelsBox();
    final prefix = version == null ? "$playlistId/" : "$playlistId/$version/";
    final keep = keepVersion == null ? null : "$playlistId/$keepVersion/";
    final keys = [
      for (final key in channelsBox.keys)
        if (key is String && key.startsWith(prefix) && (keep == null || !key.startsWith(keep))) key,
    ];
    await channelsBox.deleteAll(keys);
  }

  /// Moves playlists stored with their channels inline, by earlier versions,
  /// into chunks
  Future<void> _migrateLegacyData(Box<dynamic> box) async {
    final legacyPlaylists = [
      ...?(box.get(_legacyPlaylistsKey) as List<dynamic>?),
      for (final key in box.keys)
        if (key is String && key.startsWith(_playlistKeyPrefix) && (box.get(key) as Map).containsKey("channels"))
          box.get(key),
    ];
    final legacyKeys = [_legacyPlaylistsKey, _legacyCategorizedDataKey].where(box.containsKey).toList();
    if (legacyPlaylists.isEmpty && legacyKeys.isEmpty) return;

    for (final json in legacyPlaylists) {
      await savePlaylist(Playlist.fromJson(Map<String, dynamic>.from(json as Map)));
    }
    await box.deleteAll(legacyKeys);
    // Remove the replaced data from the file, which is loaded at startup
    await box.compact();
    Logger.info("Migrated ${legacyPlaylists.length} playlists to chunked storage");
  }
}

class _HivePlaylistWriter implements PlaylistWriter {
  _HivePlaylistWriter(this._storage, this._playlistId) : _version = "${DateTime.now().microsecondsSinceEpoch}";

  final HivePlaylistStorage _storage;
  final String _playlistId;
  final String _version;
  final _pending = <Channel>[];
  var _chunkCount = 0;

  @override
  void add(Channel channel) => _pending.add(channel);

  @override
  Future<void> flush() async {
    final chunkSize = _storage.chunkSize;
    while (_pending.length >= chunkSize) {
      await _writeChunk(_pending.sublist(0, chunkSize));
      _pending.removeRange(0, chunkSize);
    }
  }

  Future<void> _writeChunk(List<Channel> channels) async {
    final channelsBox = await _storage._channelsBox();
    final key = HivePlaylistStorage._chunkKey(_playlistId, _version, _chunkCount);
    await channelsBox.put(key, HivePlaylistStorage._encode(channels));
    _chunkCount++;
  }

  @override
  Future<void> commit(Playlist playlist) async {
    await flush();
    if (_pending.isNotEmpty) {
      await _writeChunk(List.of(_pending));
      _pending.clear();
    }

    final box = await _storage._box();
    await box.put(HivePlaylistStorage._playlistKey(_playlistId), {
      "id": _playlistId,
      "name": playlist.name,
      "url": playlist.url,
      "lastUpdate": playlist.lastUpdate.toIso8601String(),
      "version": _version,
      "chunkCount": _chunkCount,
    });
    // Drop the chunks of the version this one replaces
    await _storage._deleteChunks(_playlistId, keepVersion: _version);
    Logger.success("Saved playlist '${playlist.name}' with ${playlist.channels.length} channels");
  }

  @override
  Future<void> discard() async {
    _pending.clear();
    await _storage._deleteChunks(_playlistId, version: _version);
  }
}
