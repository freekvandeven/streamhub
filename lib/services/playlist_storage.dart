import "package:channel_categorizer/channel_categorizer.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:streamhub/models/playlist.dart";
import "package:streamhub/utils/logger.dart";

/// Service for local storage of playlists using Hive
abstract final class PlaylistStorage {
  static const String _boxName = "playlists";
  static const String _playlistsKey = "all_playlists";
  static const String _activePlaylistIdKey = "active_playlist_id";
  static const String _categorizedDataKey = "categorized_data";

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

  /// Loads all playlists
  static Future<List<Playlist>> loadAllPlaylists() async {
    try {
      final box = await _getBox();
      final playlistsJson = box.get(_playlistsKey) as List<dynamic>?;
      if (playlistsJson == null || playlistsJson.isEmpty) {
        return [];
      }

      final playlists = playlistsJson
          .map((json) => Playlist.fromJson(json as Map<String, dynamic>))
          .toList();

      Logger.info("Loaded ${playlists.length} playlists from storage");
      return playlists;
    } on Exception catch (e) {
      Logger.error("Failed to load playlists: $e");
      return [];
    }
  }

  /// Saves a playlist (adds new or updates existing)
  static Future<void> savePlaylist(Playlist playlist) async {
    try {
      final box = await _getBox();
      final playlists = await loadAllPlaylists();

      // Check if playlist with same ID exists
      final existingIndex = playlists.indexWhere((p) => p.id == playlist.id);

      if (existingIndex >= 0) {
        // Update existing
        playlists[existingIndex] = playlist;
        Logger.info("Updated playlist: ${playlist.name}");
      } else {
        // Add new
        playlists.add(playlist);
        Logger.info("Added new playlist: ${playlist.name}");
      }

      // Save all playlists
      final playlistsJson = playlists.map((p) => p.toJson()).toList();
      await box.put(_playlistsKey, playlistsJson);

      // Set as active if it's the only one or newly added
      if (playlists.length == 1 || existingIndex < 0) {
        await setActivePlaylistId(playlist.id);
      }

      Logger.success(
        "Saved playlist '${playlist.name}' with ${playlist.channels.length} "
        "channels",
      );
    } on Exception catch (e) {
      Logger.error("Failed to save playlist: $e");
    }
  }

  /// Removes a playlist by ID
  static Future<void> removePlaylist(String playlistId) async {
    try {
      final box = await _getBox();
      final playlists = await loadAllPlaylists();

      playlists.removeWhere((p) => p.id == playlistId);

      final playlistsJson = playlists.map((p) => p.toJson()).toList();
      await box.put(_playlistsKey, playlistsJson);

      // If removed playlist was active, set first playlist as active
      final activeId = await getActivePlaylistId();
      if (activeId == playlistId && playlists.isNotEmpty) {
        await setActivePlaylistId(playlists.first.id);
      } else if (playlists.isEmpty) {
        await box.delete(_activePlaylistIdKey);
      }

      Logger.success("Removed playlist");
    } on Exception catch (e) {
      Logger.error("Failed to remove playlist: $e");
    }
  }

  /// Gets the active playlist ID
  static Future<String?> getActivePlaylistId() async {
    try {
      final box = await _getBox();
      return box.get(_activePlaylistIdKey) as String?;
    } on Exception catch (e) {
      Logger.error("Failed to get active playlist ID: $e");
      return null;
    }
  }

  /// Sets the active playlist ID
  static Future<void> setActivePlaylistId(String playlistId) async {
    try {
      final box = await _getBox();
      await box.put(_activePlaylistIdKey, playlistId);
    } on Exception catch (e) {
      Logger.error("Failed to set active playlist ID: $e");
    }
  }

  /// Gets the active playlist
  static Future<Playlist?> getActivePlaylist() async {
    try {
      final activeId = await getActivePlaylistId();
      if (activeId == null) return null;

      final playlists = await loadAllPlaylists();
      return playlists.where((p) => p.id == activeId).firstOrNull;
    } on Exception catch (e) {
      Logger.error("Failed to get active playlist: $e");
      return null;
    }
  }

  /// Finds a playlist by URL
  static Future<Playlist?> findPlaylistByUrl(String url) async {
    try {
      final playlists = await loadAllPlaylists();
      return playlists.where((p) => p.url == url).firstOrNull;
    } on Exception catch (e) {
      Logger.error("Failed to find playlist by URL: $e");
      return null;
    }
  }

  /// Clears all playlists
  static Future<void> clearAllPlaylists() async {
    try {
      final box = await _getBox();
      await box.clear();
      Logger.success("All playlists cleared");
    } on Exception catch (e) {
      Logger.error("Failed to clear playlists: $e");
    }
  }

  // ==========================================================================
  // Categorized Playlist Storage
  // ==========================================================================

  /// Saves categorized playlist data
  /// Stores the category tree with channel indices and categorizer
  /// metadata
  static Future<void> saveCategorizedData({
    required CategoryNode categoryTree,
    required String categorizerId,
    required String categorizerVersion,
    required int totalChannels,
  }) async {
    try {
      final box = await _getBox();
      final startTime = DateTime.now();

      final data = {
        "categoryTree": categoryTree.toJson(),
        "categorizerId": categorizerId,
        "categorizerVersion": categorizerVersion,
        "totalChannels": totalChannels,
        "timestamp": DateTime.now().toIso8601String(),
      };

      await box.put(_categorizedDataKey, data);

      final duration = DateTime.now().difference(startTime);
      Logger.success(
        "Saved categorized data ($totalChannels channels, "
        "$categorizerId v$categorizerVersion) in "
        "${duration.inMilliseconds}ms",
      );
    } on Exception catch (e) {
      Logger.error("Failed to save categorized data: $e");
    }
  }

  /// Loads categorized playlist data
  /// Returns null if no cached data or if invalid JSON
  static Future<Map<String, dynamic>?> loadCategorizedData() async {
    try {
      final box = await _getBox();
      final data = box.get(_categorizedDataKey) as Map<dynamic, dynamic>?;

      if (data == null) {
        Logger.info("No cached categorized data found");
        return null;
      }

      // Convert to proper types
      return {
        "categoryTree": data["categoryTree"] as Map<dynamic, dynamic>,
        "categorizerId": data["categorizerId"] as String,
        "categorizerVersion": data["categorizerVersion"] as String,
        "totalChannels": data["totalChannels"] as int,
        "timestamp": data["timestamp"] as String,
      };
    } on Exception catch (e) {
      Logger.error("Failed to load categorized data: $e");
      return null;
    }
  }

  /// Checks if categorized data is valid for the given categorizer
  static Future<bool> hasValidCategorizedData({
    required String categorizerId,
    required String version,
  }) async {
    final data = await loadCategorizedData();
    if (data == null) return false;

    return data["categorizerId"] == categorizerId &&
        data["categorizerVersion"] == version;
  }

  /// Clears only the categorized data (keeps raw channels)
  static Future<void> clearCategorizedData() async {
    try {
      final box = await _getBox();
      await box.delete(_categorizedDataKey);
      Logger.success("Categorized data cleared");
    } on Exception catch (e) {
      Logger.error("Failed to clear categorized data: $e");
    }
  }
}
