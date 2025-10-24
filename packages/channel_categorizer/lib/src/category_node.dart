/// Represents a hierarchical category node with parent-child relationships
class CategoryNode {
  CategoryNode({
    required this.id,
    required this.name,
    required this.path,
    this.parent,
    this.channelCount = 0,
    this.channelIndices = const [],
    this.children = const [],
  });

  /// Create from JSON
  factory CategoryNode.fromJson(Map<String, dynamic> json) {
    final children =
        (json["children"] as List?)
            ?.map((c) => CategoryNode.fromJson(c as Map<String, dynamic>))
            .toList() ??
        [];

    return CategoryNode(
      id: json["id"] as String,
      name: json["name"] as String,
      path: json["path"] as String,
      channelCount: json["channelCount"] as int? ?? 0,
      channelIndices: (json["channelIndices"] as List?)?.cast<int>() ?? [],
      children: children,
    );
  }

  /// Unique identifier for this category
  final String id;

  /// Display name of the category
  final String name;

  /// Full hierarchical path (e.g., "Live TV > Sports > UK Sports")
  final String path;

  /// Parent category node
  final CategoryNode? parent;

  /// Number of channels directly in this category
  final int channelCount;

  /// Indices of channels in this category (for lazy loading)
  final List<int> channelIndices;

  /// Child categories
  final List<CategoryNode> children;

  /// Total channels including all descendants
  int get totalChannelCount {
    var total = channelCount;
    for (final child in children) {
      total += child.totalChannelCount;
    }
    return total;
  }

  /// Depth level in the hierarchy (0 = root)
  int get depth => path.split(" > ").length - 1;

  /// Check if this is a leaf category (no children)
  bool get isLeaf => children.isEmpty;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "path": path,
      "channelCount": channelCount,
      "channelIndices": channelIndices,
      "children": children.map((c) => c.toJson()).toList(),
    };
  }

  /// Copy with modifications
  CategoryNode copyWith({
    String? id,
    String? name,
    String? path,
    CategoryNode? parent,
    int? channelCount,
    List<int>? channelIndices,
    List<CategoryNode>? children,
  }) {
    return CategoryNode(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      parent: parent ?? this.parent,
      channelCount: channelCount ?? this.channelCount,
      channelIndices: channelIndices ?? this.channelIndices,
      children: children ?? this.children,
    );
  }

  @override
  String toString() => "CategoryNode($path, $totalChannelCount channels)";
}
