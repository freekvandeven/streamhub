import "package:hive_flutter/hive_flutter.dart";
import "package:streamhub/models/playlist.dart";
import "package:streamhub/utils/logger.dart";

/// Service for local storage of playlists using Hive
///
/// Each playlist is stored under its own key, so saving or removing one
/// playlist doesn't rewrite all the others.
abstract final class PlaylistStorage {
  static const String _boxName = "playlists";
  static const String _playlistKeyPrefix = "playlist:";
  static const String _activePlaylistIdKey = "active_playlist_id";

  /// Keys written by earlier versions of the app
  static const String _legacyPlaylistsKey = "all_playlists";
  static const String _legacyCategorizedDataKey = "categorized_data";

  /// Initializes Hive storage (lightweight - just initializes Hive)
  static Future<void> init() async {
    await Hive.initFlutter();
    Logger.success("Hive initialized");
  }

  /// Gets or opens the storage box (lazy loading)
  static Future<Box<dynamic>> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<dynamic>(_boxName);
    }
    return Hive.openBox<dynamic>(_boxName);
  }

  static String _playlistKey(String playlistId) => "$_playlistKeyPrefix$playlistId";

  /// Loads all playlists, oldest first
  static Future<List<Playlist>> loadAllPlaylists() async {
    final box = await _getBox();
    await _migrateLegacyData(box);

    // Hive returns keys sorted, and playlist IDs are creation timestamps
    final playlists = [
      for (final key in box.keys)
        if (key is String && key.startsWith(_playlistKeyPrefix))
          Playlist.fromJson(Map<String, dynamic>.from(box.get(key) as Map)),
    ];

    Logger.info("Loaded ${playlists.length} playlists from storage");
    return playlists;
  }

  /// Saves a playlist (adds new or updates existing)
  static Future<void> savePlaylist(Playlist playlist) async {
    final box = await _getBox();
    await box.put(_playlistKey(playlist.id), playlist.toJson());
    Logger.success(
      "Saved playlist '${playlist.name}' with ${playlist.channels.length} "
      "channels",
    );
  }

  /// Removes a playlist by ID
  static Future<void> removePlaylist(String playlistId) async {
    final box = await _getBox();
    await box.delete(_playlistKey(playlistId));
    Logger.success("Removed playlist");
  }

  /// Gets the active playlist ID
  static Future<String?> getActivePlaylistId() async {
    final box = await _getBox();
    return box.get(_activePlaylistIdKey) as String?;
  }

  /// Sets the active playlist ID, or clears it when [playlistId] is null
  static Future<void> setActivePlaylistId(String? playlistId) async {
    final box = await _getBox();
    if (playlistId == null) {
      await box.delete(_activePlaylistIdKey);
    } else {
      await box.put(_activePlaylistIdKey, playlistId);
    }
  }

  /// Moves playlists from the old single-list format to per-playlist keys
  /// and drops the unused categorized data cache
  static Future<void> _migrateLegacyData(Box<dynamic> box) async {
    final legacyKeys = [
      _legacyPlaylistsKey,
      _legacyCategorizedDataKey,
    ].where(box.containsKey).toList();
    if (legacyKeys.isEmpty) return;

    final legacyPlaylists = box.get(_legacyPlaylistsKey) as List<dynamic>?;
    if (legacyPlaylists != null) {
      await box.putAll({
        for (final json in legacyPlaylists) _playlistKey((json as Map)["id"] as String): json,
      });
      Logger.info("Migrated ${legacyPlaylists.length} playlists");
    }

    await box.deleteAll(legacyKeys);
  }
}
