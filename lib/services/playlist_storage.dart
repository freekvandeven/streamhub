import "package:hive_flutter/hive_flutter.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/utils/logger.dart";

/// Service for local storage of playlists using Hive
abstract final class PlaylistStorage {
  static const String _boxName = "playlists";
  static const String _channelsKey = "cached_channels";
  static const String _lastUpdateKey = "last_update";
  static const String _playlistUrlKey = "playlist_url";

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

  /// Saves playlist to local storage
  static Future<void> savePlaylist(
    List<Channel> channels,
    String playlistUrl,
  ) async {
    try {
      final box = await _getBox();
      final startTime = DateTime.now();

      // Convert channels to JSON
      final channelsJson = channels
          .map(
            (c) => {
              "name": c.name,
              "url": c.url,
              "tvgId": c.tvgId,
              "tvgName": c.tvgName,
              "tvgLogo": c.tvgLogo,
              "groupTitle": c.groupTitle,
            },
          )
          .toList();

      await box.put(_channelsKey, channelsJson);
      await box.put(_lastUpdateKey, DateTime.now().toIso8601String());
      await box.put(_playlistUrlKey, playlistUrl);

      final duration = DateTime.now().difference(startTime);
      Logger.success(
        "Saved ${channels.length} channels to local storage in "
        "${duration.inMilliseconds}ms",
      );
    } on Exception catch (e) {
      Logger.error("Failed to save playlist: $e");
    }
  }

  /// Loads playlist from local storage
  static Future<List<Channel>?> loadPlaylist() async {
    try {
      final box = await _getBox();
      final startTime = DateTime.now();

      final channelsJson = box.get(_channelsKey) as List<dynamic>?;
      if (channelsJson == null) {
        Logger.info("No cached playlist found");
        return null;
      }

      final channels = channelsJson.map<Channel>((json) {
        final map = json as Map<dynamic, dynamic>;
        return Channel(
          name: map["name"] as String,
          url: map["url"] as String,
          tvgId: map["tvgId"] as String?,
          tvgName: map["tvgName"] as String?,
          tvgLogo: map["tvgLogo"] as String?,
          groupTitle: map["groupTitle"] as String?,
        );
      }).toList();

      final duration = DateTime.now().difference(startTime);
      Logger.success(
        "Loaded ${channels.length} channels from cache in "
        "${duration.inMilliseconds}ms",
      );

      return channels;
    } on Exception catch (e) {
      Logger.error("Failed to load playlist: $e");
      return null;
    }
  }

  /// Gets the last update time of the cached playlist
  static Future<DateTime?> getLastUpdateTime() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) return null;
      final box = Hive.box<dynamic>(_boxName);
      final lastUpdate = box.get(_lastUpdateKey) as String?;
      if (lastUpdate == null) return null;
      return DateTime.parse(lastUpdate);
    } on Exception catch (e) {
      Logger.error("Failed to get last update time: $e");
      return null;
    }
  }

  /// Gets the URL of the cached playlist
  static Future<String?> getCachedPlaylistUrl() async {
    try {
      if (!Hive.isBoxOpen(_boxName)) return null;
      final box = Hive.box<dynamic>(_boxName);
      return box.get(_playlistUrlKey) as String?;
    } on Exception catch (e) {
      Logger.error("Failed to get cached URL: $e");
      return null;
    }
  }

  /// Checks if there is a cached playlist
  static Future<bool> hasCachedPlaylist() async {
    if (!Hive.isBoxOpen(_boxName)) return false;
    final box = Hive.box<dynamic>(_boxName);
    return box.containsKey(_channelsKey);
  }

  /// Clears the cached playlist
  static Future<void> clearCache() async {
    try {
      final box = await _getBox();
      await box.clear();
      Logger.success("Cache cleared");
    } on Exception catch (e) {
      Logger.error("Failed to clear cache: $e");
    }
  }

  /// Gets cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return {
        "hasCachedData": false,
        "lastUpdate": null,
        "playlistUrl": null,
        "channelCount": 0,
        "cacheAge": null,
      };
    }

    final box = Hive.box<dynamic>(_boxName);
    final lastUpdate = await getLastUpdateTime();
    final playlistUrl = await getCachedPlaylistUrl();
    final channelsJson = box.get(_channelsKey) as List<dynamic>?;

    return {
      "hasCachedData": await hasCachedPlaylist(),
      "lastUpdate": lastUpdate?.toIso8601String(),
      "playlistUrl": playlistUrl,
      "channelCount": channelsJson?.length ?? 0,
      "cacheAge": lastUpdate != null
          ? DateTime.now().difference(lastUpdate).inHours
          : null,
    };
  }
}
