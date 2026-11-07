import "package:hive_flutter/hive_flutter.dart";

/// Local persistence for favorite channels, stored by [Channel.favoriteKey]
abstract final class FavoritesStorage {
  static const String _boxName = "favorites";
  static const String _channelsKey = "channels";

  static Future<Box<dynamic>> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box<dynamic>(_boxName);
    }
    return Hive.openBox<dynamic>(_boxName);
  }

  /// Loads the favorite channel keys in the order they were added
  static Future<List<String>> load() async {
    final box = await _getBox();
    return (box.get(_channelsKey) as List<dynamic>?)?.cast<String>() ?? [];
  }

  /// Replaces the stored favorite channel keys
  static Future<void> save(Iterable<String> keys) async {
    final box = await _getBox();
    await box.put(_channelsKey, keys.toList());
  }
}
