import "package:channel_categorizer/channel_categorizer.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/utils/logger.dart";

/// Optimized storage service for categories and channels
/// Stores categories separately for fast browsing without loading all channels
abstract final class CategoryStorage {
  static const String _categoriesBoxName = "categories";
  static const String _channelsByCategory = "channels_by_category";

  /// Initialize category storage
  static Future<void> init() async {
    await Hive.openBox<dynamic>(_categoriesBoxName);
    await Hive.openBox<dynamic>(_channelsByCategory);
    Logger.success("Category storage initialized");
  }

  /// Save category tree and channels organized by category
  static Future<void> saveCategorizedData({
    required CategoryNode rootNode,
    required List<Channel> allChannels,
    required String playlistUrl,
  }) async {
    final startTime = DateTime.now();

    try {
      final categoriesBox = Hive.box<dynamic>(_categoriesBoxName);
      final channelsBox = Hive.box<dynamic>(_channelsByCategory);

      // Save category tree
      await categoriesBox.put("root", rootNode.toJson());
      await categoriesBox.put("playlistUrl", playlistUrl);
      await categoriesBox.put("lastUpdate", DateTime.now().toIso8601String());
      await categoriesBox.put("totalChannels", allChannels.length);

      // Save channels organized by category path
      final channelsByPath = <String, List<Map<String, dynamic>>>{};

      for (var i = 0; i < allChannels.length; i++) {
        final channel = allChannels[i];
        final categoryPath = channel.groupTitle ?? "Uncategorized";

        channelsByPath.putIfAbsent(categoryPath, () => []);
        channelsByPath[categoryPath]!.add({
          "index": i,
          "name": channel.name,
          "url": channel.url,
          "tvgId": channel.tvgId,
          "tvgName": channel.tvgName,
          "tvgLogo": channel.tvgLogo,
          "groupTitle": channel.groupTitle,
        });
      }

      // Save each category's channels separately
      for (final entry in channelsByPath.entries) {
        await channelsBox.put(entry.key, entry.value);
      }

      final duration = DateTime.now().difference(startTime);
      Logger.success(
        "Saved category tree and ${allChannels.length} channels "
        "in ${duration.inMilliseconds}ms",
      );
    } on Exception catch (e) {
      Logger.error("Failed to save categorized data: $e");
      rethrow;
    }
  }

  /// Load category tree (lightweight - no channel data)
  static Future<CategoryNode?> loadCategoryTree() async {
    try {
      final categoriesBox = Hive.box<dynamic>(_categoriesBoxName);
      final rootJson = categoriesBox.get("root") as Map<dynamic, dynamic>?;

      if (rootJson == null) {
        Logger.info("No category tree found in storage");
        return null;
      }

      final root = CategoryNode.fromJson(
        Map<String, dynamic>.from(rootJson),
      );
      Logger.success("Loaded category tree from storage");
      return root;
    } on Exception catch (e) {
      Logger.error("Failed to load category tree: $e");
      return null;
    }
  }

  /// Load channels for a specific category path
  static Future<List<Channel>?> loadChannelsForCategory(
    String categoryPath,
  ) async {
    final startTime = DateTime.now();

    try {
      final channelsBox = Hive.box<dynamic>(_channelsByCategory);
      final channelsJson = channelsBox.get(categoryPath) as List<dynamic>?;

      if (channelsJson == null) {
        Logger.info("No channels found for category: $categoryPath");
        return null;
      }

      final channels = channelsJson.map((json) {
        final map = Map<String, dynamic>.from(json as Map);
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
        "Loaded ${channels.length} channels for '$categoryPath' "
        "in ${duration.inMilliseconds}ms",
      );

      return channels;
    } on Exception catch (e) {
      Logger.error("Failed to load channels for category: $e");
      return null;
    }
  }

  /// Get storage statistics
  static Future<Map<String, dynamic>?> getStats() async {
    try {
      final categoriesBox = Hive.box<dynamic>(_categoriesBoxName);

      final lastUpdateStr = categoriesBox.get("lastUpdate") as String?;
      final totalChannels = categoriesBox.get("totalChannels") as int?;
      final playlistUrl = categoriesBox.get("playlistUrl") as String?;

      if (lastUpdateStr == null) return null;

      return {
        "lastUpdate": DateTime.parse(lastUpdateStr),
        "totalChannels": totalChannels ?? 0,
        "playlistUrl": playlistUrl ?? "",
      };
    } on Exception catch (e) {
      Logger.error("Failed to get storage stats: $e");
      return null;
    }
  }

  /// Check if categorized data exists
  static Future<bool> hasCategorizedData() async {
    final categoriesBox = Hive.box<dynamic>(_categoriesBoxName);
    return categoriesBox.containsKey("root");
  }

  /// Clear all category data
  static Future<void> clearAll() async {
    final startTime = DateTime.now();

    try {
      await Hive.box<dynamic>(_categoriesBoxName).clear();
      await Hive.box<dynamic>(_channelsByCategory).clear();

      final duration = DateTime.now().difference(startTime);
      Logger.success(
        "Cleared all category data in ${duration.inMilliseconds}ms",
      );
    } on Exception catch (e) {
      Logger.error("Failed to clear category data: $e");
      rethrow;
    }
  }

  /// Build search index for fast lookups
  static Future<void> buildSearchIndex(List<Channel> channels) async {
    final startTime = DateTime.now();

    try {
      final categoriesBox = Hive.box<dynamic>(_categoriesBoxName);

      // Build simple search index: lowercase name -> channel indices
      final searchIndex = <String, List<int>>{};

      for (var i = 0; i < channels.length; i++) {
        final channel = channels[i];
        final words = channel.name.toLowerCase().split(RegExp(r"\s+"));

        for (final word in words) {
          if (word.length >= 2) {
            // Only index words with 2+ chars
            searchIndex.putIfAbsent(word, () => []);
            searchIndex[word]!.add(i);
          }
        }
      }

      await categoriesBox.put("searchIndex", searchIndex);

      final duration = DateTime.now().difference(startTime);
      Logger.success(
        "Built search index with ${searchIndex.length} terms "
        "in ${duration.inMilliseconds}ms",
      );
    } on Exception catch (e) {
      Logger.error("Failed to build search index: $e");
    }
  }

  /// Search channels by query
  static Future<List<int>> searchChannels(String query) async {
    try {
      final categoriesBox = Hive.box<dynamic>(_categoriesBoxName);
      final searchIndex =
          categoriesBox.get("searchIndex") as Map<dynamic, dynamic>?;

      if (searchIndex == null) {
        Logger.warning("Search index not found");
        return [];
      }

      final queryWords = query.toLowerCase().split(RegExp(r"\s+"));
      final matchingSets = <Set<int>>[];

      for (final word in queryWords) {
        if (word.length >= 2) {
          final indices = searchIndex[word] as List<dynamic>?;
          if (indices != null) {
            matchingSets.add(indices.cast<int>().toSet());
          }
        }
      }

      if (matchingSets.isEmpty) return [];

      // Intersect all sets to find channels matching all words
      var result = matchingSets.first;
      for (var i = 1; i < matchingSets.length; i++) {
        result = result.intersection(matchingSets[i]);
      }

      return result.toList()..sort();
    } on Exception catch (e) {
      Logger.error("Failed to search channels: $e");
      return [];
    }
  }
}
