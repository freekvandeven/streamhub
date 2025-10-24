import "package:channel_categorizer/src/category_node.dart";

/// Stores pre-categorized playlist data with metadata for cache invalidation
class CategorizedPlaylist {
  const CategorizedPlaylist({
    required this.categoryTree,
    required this.categorizerId,
    required this.categorizerVersion,
    required this.totalChannels,
    required this.timestamp,
  });

  /// Create from JSON
  factory CategorizedPlaylist.fromJson(Map<String, dynamic> json) {
    return CategorizedPlaylist(
      categoryTree: CategoryNode.fromJson(
        json["categoryTree"] as Map<String, dynamic>,
      ),
      categorizerId: json["categorizerId"] as String,
      categorizerVersion: json["categorizerVersion"] as String,
      totalChannels: json["totalChannels"] as int,
      timestamp: DateTime.parse(json["timestamp"] as String),
    );
  }

  /// The hierarchical category tree with channel indices
  final CategoryNode categoryTree;

  /// ID of the categorizer that created this (e.g., "default", "provider_uk")
  final String categorizerId;

  /// Version of the categorizer for cache invalidation
  final String categorizerVersion;

  /// Total number of channels in the playlist
  final int totalChannels;

  /// When this categorization was created
  final DateTime timestamp;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      "categoryTree": categoryTree.toJson(),
      "categorizerId": categorizerId,
      "categorizerVersion": categorizerVersion,
      "totalChannels": totalChannels,
      "timestamp": timestamp.toIso8601String(),
    };
  }

  /// Check if this cache is valid for the given categorizer
  bool isValidFor(String categorizerId, String version) {
    return this.categorizerId == categorizerId && categorizerVersion == version;
  }

  /// Get age of this categorization
  Duration get age => DateTime.now().difference(timestamp);

  @override
  String toString() =>
      "CategorizedPlaylist($totalChannels channels, $categorizerId "
      "v$categorizerVersion, ${age.inHours}h old)";
}
