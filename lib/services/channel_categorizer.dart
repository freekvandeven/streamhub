import "package:streamhub/models/category_node.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/utils/logger.dart";

/// Smart channel categorization service
/// Analyzes channel names and metadata to extract meaningful categories
abstract final class ChannelCategorizer {
  /// Categorizes a list of channels based on name patterns
  /// Returns channels with hierarchical category paths
  static List<Channel> categorize(List<Channel> channels) {
    final startTime = DateTime.now();
    final categorized = <Channel>[];

    for (final channel in channels) {
      final categoryPath = _extractHierarchicalCategory(channel);
      categorized.add(
        Channel(
          name: channel.name,
          url: channel.url,
          tvgId: channel.tvgId,
          tvgName: channel.tvgName,
          tvgLogo: channel.tvgLogo,
          groupTitle: categoryPath,
        ),
      );
    }

    final duration = DateTime.now().difference(startTime);
    Logger.success(
      "Categorized ${channels.length} channels in "
      "${duration.inSeconds}.${duration.inMilliseconds % 1000}s",
    );

    return categorized;
  }

  /// Extracts hierarchical category path
  /// (e.g., "Live TV > Sports > UK Sports")
  static String _extractHierarchicalCategory(Channel channel) {
    // Use existing group-title if available and not empty
    if (channel.groupTitle != null &&
        channel.groupTitle!.isNotEmpty &&
        channel.groupTitle!.toLowerCase() != "uncategorized") {
      return channel.groupTitle!;
    }

    final name = channel.name.toLowerCase();

    // 1. Check for VOD content (Movies & Series)
    final vodCategory = _detectVodCategory(name);
    if (vodCategory != null) {
      // VOD gets its own top-level categories
      return vodCategory; // "Movies" or "Series"
    }

    // 2. Check for country-specific channels (creates hierarchical path)
    final countryInfo = _detectCountryInfo(name, channel.name);
    if (countryInfo != null) {
      final country = countryInfo["country"] as String;
      final genre = countryInfo["genre"] as String?;

      if (genre != null) {
        // "Live TV > Sports > UK Sports"
        return "Live TV > $genre > $country $genre";
      }
      // "Live TV > UK"
      return "Live TV > $country";
    }

    // 3. Check for genre without country
    final genre = _detectGenreCategory(name);
    if (genre != null) {
      return "Live TV > $genre";
    }

    // 4. Default to "Live TV"
    return "Live TV";
  }

  /// Detects VOD content (Movies, Series)
  static String? _detectVodCategory(String name) {
    // Movie indicators: [VOD], year (2020-2025), "movie", etc.
    if (name.contains("[vod]") ||
        name.contains("(vod)") ||
        name.contains("movie")) {
      return "Movies";
    }

    // Series indicators: S01E01, Season 1, Episode, etc.
    final seriesPatterns = [
      RegExp(r"s\d{2}e\d{2}"), // S01E01
      RegExp(r"season\s*\d+"), // Season 1
      RegExp(r"episode\s*\d+"), // Episode 1
      RegExp(r"\|\s*s\d+"), // | S1
    ];

    for (final pattern in seriesPatterns) {
      if (pattern.hasMatch(name)) {
        return "Series";
      }
    }

    // Year in parentheses often indicates movies
    if (RegExp(r"\(20[2-9]\d\)").hasMatch(name)) {
      return "Movies";
    }

    return null;
  }

  /// Detects country info and returns map with country and genre
  static Map<String, dynamic>? _detectCountryInfo(
    String lowerName,
    String originalName,
  ) {
    // Country code patterns: [UK], UK:, (UK), |UK|, etc.
    final countryPatterns = {
      // European countries
      "uk": "UK",
      "gb": "UK",
      "us": "USA",
      "usa": "USA",
      "nl": "Netherlands",
      "de": "Germany",
      "fr": "France",
      "es": "Spain",
      "it": "Italy",
      "pt": "Portugal",
      "be": "Belgium",
      "se": "Sweden",
      "no": "Norway",
      "dk": "Denmark",
      "fi": "Finland",
      "pl": "Poland",
      "ro": "Romania",
      "gr": "Greece",
      "tr": "Turkey",
      "ru": "Russia",
      "ie": "Ireland",
      "ch": "Switzerland",
      "at": "Austria",

      // Middle East & Africa
      "ae": "UAE",
      "sa": "Saudi Arabia",
      "eg": "Egypt",
      "za": "South Africa",
      "il": "Israel",

      // Asia Pacific
      "in": "India",
      "pk": "Pakistan",
      "cn": "China",
      "jp": "Japan",
      "kr": "Korea",
      "au": "Australia",
      "nz": "New Zealand",
      "th": "Thailand",
      "sg": "Singapore",

      // Americas
      "ca": "Canada",
      "mx": "Mexico",
      "br": "Brazil",
      "ar": "Argentina",
    };

    for (final entry in countryPatterns.entries) {
      final code = entry.key;
      final country = entry.value;

      // Check various country code formats
      final patterns = [
        RegExp("^\\[$code\\]", caseSensitive: false), // [UK] at start
        RegExp("^$code:", caseSensitive: false), // UK: at start
        RegExp("^$code\\s", caseSensitive: false), // UK at start
        RegExp("\\|$code\\|", caseSensitive: false), // |UK|
        RegExp("\\($code\\)", caseSensitive: false), // (UK)
      ];

      for (final pattern in patterns) {
        if (pattern.hasMatch(lowerName)) {
          // Check for genre suffix (Sports, News, etc.)
          final genre = _detectGenreFromName(lowerName);
          return {
            "country": country,
            "genre": genre,
          };
        }
      }
    }

    return null;
  }

  /// Detects genre from channel name
  static String? _detectGenreFromName(String name) {
    if (name.contains("sport")) return "Sports";
    if (name.contains("news")) return "News";
    if (name.contains("kids") || name.contains("cartoon")) return "Kids";
    if (name.contains("music") || name.contains("mtv")) return "Music";
    if (name.contains("documentary") || name.contains("docu")) {
      return "Documentary";
    }
    if (name.contains("entertainment") || name.contains("entertain")) {
      return "Entertainment";
    }
    if (name.contains("movie") || name.contains("cinema")) return "Movies";
    if (name.contains("series")) return "Series";
    return null;
  }

  /// Detects genre-based categories
  static String? _detectGenreCategory(String name) {
    // Sports channels
    if (name.contains("sport") ||
        name.contains("espn") ||
        name.contains("bein") ||
        name.contains("sky sports") ||
        name.contains("fox sports") ||
        name.contains("tsn") ||
        name.contains("eurosport")) {
      return "Sports";
    }

    // News channels
    if (name.contains("news") ||
        name.contains("cnn") ||
        name.contains("bbc news") ||
        name.contains("fox news") ||
        name.contains("msnbc") ||
        name.contains("al jazeera")) {
      return "News";
    }

    // Kids channels
    if (name.contains("kids") ||
        name.contains("cartoon") ||
        name.contains("disney") ||
        name.contains("nickelodeon") ||
        name.contains("nick jr") ||
        name.contains("baby tv")) {
      return "Kids";
    }

    // Music channels
    if (name.contains("music") ||
        name.contains("mtv") ||
        name.contains("vh1") ||
        name.contains("hit music")) {
      return "Music";
    }

    // Documentary channels
    if (name.contains("documentary") ||
        name.contains("discovery") ||
        name.contains("natgeo") ||
        name.contains("nat geo") ||
        name.contains("history") ||
        name.contains("animal planet")) {
      return "Documentary";
    }

    // Entertainment channels
    if (name.contains("entertainment") ||
        name.contains("comedy") ||
        name.contains("hbo") ||
        name.contains("showtime")) {
      return "Entertainment";
    }

    // Religious channels
    if (name.contains("religious") ||
        name.contains("islam") ||
        name.contains("christian") ||
        name.contains("gospel")) {
      return "Religious";
    }

    return null;
  }

  /// Build hierarchical category tree from categorized channels
  static CategoryNode buildCategoryTree(List<Channel> channels) {
    final root = CategoryNode(
      id: "root",
      name: "All Categories",
      path: "Root",
    );

    final pathToNode = <String, CategoryNode>{"Root": root};
    final pathToChannelIndices = <String, List<int>>{};

    // Build tree structure
    for (var i = 0; i < channels.length; i++) {
      final channel = channels[i];
      final fullPath = channel.groupTitle ?? "Live TV";
      final segments = fullPath.split(" > ");

      var currentPath = "Root";
      CategoryNode? parentNode = root;

      for (var j = 0; j < segments.length; j++) {
        final segment = segments[j].trim();
        final newPath = j == 0 ? segment : "$currentPath > $segment";

        if (!pathToNode.containsKey(newPath)) {
          // Create new node
          final newNode = CategoryNode(
            id: newPath.toLowerCase().replaceAll(" ", "_"),
            name: segment,
            path: newPath,
            parent: parentNode,
          );

          pathToNode[newPath] = newNode;
          pathToChannelIndices[newPath] = [];

          // Add to parent's children
          if (parentNode != null) {
            final updatedChildren = List<CategoryNode>.from(
              parentNode.children,
            )..add(newNode);
            pathToNode[parentNode.path] = parentNode.copyWith(
              children: updatedChildren,
            );
          }
        }

        parentNode = pathToNode[newPath];
        currentPath = newPath;
      }

      // Add channel index to leaf category
      pathToChannelIndices.putIfAbsent(currentPath, () => []);
      pathToChannelIndices[currentPath]!.add(i);
    }

    // Update channel counts in nodes
    for (final entry in pathToChannelIndices.entries) {
      final path = entry.key;
      final indices = entry.value;
      final node = pathToNode[path];

      if (node != null) {
        pathToNode[path] = node.copyWith(
          channelCount: indices.length,
          channelIndices: indices,
        );
      }
    }

    return pathToNode["Root"]!;
  }

  /// Analyzes categorized channels and returns statistics
  static Map<String, dynamic> analyzeCategories(List<Channel> channels) {
    final categoryCounts = <String, int>{};

    for (final channel in channels) {
      final category = channel.groupTitle ?? "Uncategorized";
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    // Sort by count descending
    final sorted = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      "totalCategories": categoryCounts.length,
      "categories": Map.fromEntries(sorted),
      "largestCategory": sorted.isNotEmpty ? sorted.first.key : null,
      "largestCategoryCount": sorted.isNotEmpty ? sorted.first.value : 0,
    };
  }
}
