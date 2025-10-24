/// A categorization result containing the categorized channel and metadata
class CategorizationResult {
  const CategorizationResult({
    required this.categoryPath,
    required this.categoryId,
    this.confidence = 1.0,
    this.metadata = const {},
  });

  /// Create from JSON
  factory CategorizationResult.fromJson(Map<String, dynamic> json) {
    return CategorizationResult(
      categoryPath: json["categoryPath"] as String,
      categoryId: json["categoryId"] as String,
      confidence: (json["confidence"] as num?)?.toDouble() ?? 1.0,
      metadata: (json["metadata"] as Map<String, dynamic>?) ?? {},
    );
  }

  /// Hierarchical category path (e.g., "Live TV > Sports > UK Sports")
  final String categoryPath;

  /// Unique category identifier
  final String categoryId;

  /// Confidence score (0.0 - 1.0) for this categorization
  final double confidence;

  /// Additional metadata about the categorization
  final Map<String, dynamic> metadata;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      "categoryPath": categoryPath,
      "categoryId": categoryId,
      "confidence": confidence,
      "metadata": metadata,
    };
  }
}

/// Abstract interface for channel categorization strategies
abstract class ChannelCategorizerInterface {
  /// Categorize a single channel and return categorization result
  CategorizationResult categorizeChannel({
    required String name,
    required String url,
    String? tvgId,
    String? tvgName,
    String? groupTitle,
  });

  /// Get a unique identifier for this categorizer implementation
  String get categorizerId;

  /// Get the version of this categorizer (for cache invalidation)
  String get version;
}
