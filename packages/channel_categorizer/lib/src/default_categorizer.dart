import "package:channel_categorizer/src/categorizer_interface.dart";

/// Default channel categorizer with smart pattern-based categorization
/// Analyzes channel names, URLs, and metadata to extract hierarchical
/// categories
class DefaultChannelCategorizer implements ChannelCategorizerInterface {
  const DefaultChannelCategorizer();

  @override
  String get categorizerId => "default";

  @override
  String get version => "1.0.0";

  @override
  CategorizationResult categorizeChannel({
    required String name,
    required String url,
    String? tvgId,
    String? tvgName,
    String? groupTitle,
  }) {
    // Use existing group-title if available and not empty
    if (groupTitle != null &&
        groupTitle.isNotEmpty &&
        groupTitle.toLowerCase() != "uncategorized") {
      return CategorizationResult(
        categoryPath: groupTitle,
        categoryId: groupTitle.toLowerCase().replaceAll(" ", "_"),
      );
    }

    final lowerName = name.toLowerCase();
    final lowerUrl = url.toLowerCase();

    // 1. Check if URL contains video file extension (VOD indicator)
    final isVideoFile = _isVideoFileUrl(lowerUrl);

    // 2. Check for VOD content (Movies & Series)
    final vodResult = _detectVodCategory(lowerName, lowerUrl, isVideoFile);
    if (vodResult != null) {
      return vodResult;
    }

    // 3. Check for country-specific channels
    final countryResult = _detectCountryInfo(lowerName);
    if (countryResult != null) {
      return countryResult;
    }

    // 4. Check for genre without country
    final genreResult = _detectGenreCategory(lowerName);
    if (genreResult != null) {
      return genreResult;
    }

    // 5. Default to "Live TV"
    return const CategorizationResult(
      categoryPath: "Live TV",
      categoryId: "live_tv",
    );
  }

  /// Checks if URL points to a video file
  bool _isVideoFileUrl(String url) {
    const videoExtensions = [
      ".mkv",
      ".mp4",
      ".avi",
      ".mov",
      ".wmv",
      ".flv",
      ".webm",
      ".m4v",
      ".mpg",
      ".mpeg",
      ".3gp",
      ".ts",
      ".m3u8",
    ];

    return videoExtensions.any((ext) => url.contains(ext));
  }

  /// Detects VOD content with hierarchical categorization
  CategorizationResult? _detectVodCategory(
    String name,
    String url,
    bool isVideoFile,
  ) {
    // Series indicators
    final seriesPatterns = [
      RegExp(r"s\d{2}e\d{2}"),
      RegExp(r"s\d{1,2}\s*e\d{1,2}"),
      RegExp(r"season\s*\d+"),
      RegExp(r"episode\s*\d+"),
      RegExp(r"\|\s*s\d+"),
      RegExp(r"\bs\d{2}\b"),
    ];

    for (final pattern in seriesPatterns) {
      if (pattern.hasMatch(name)) {
        final genre = _detectVodGenre(name);
        final path = genre != null ? "Series > $genre" : "Series";
        return CategorizationResult(
          categoryPath: path,
          categoryId: path.toLowerCase().replaceAll(" ", "_"),
          metadata: {"type": "series", "genre": genre},
        );
      }
    }

    // Movie indicators
    const movieIndicators = ["[vod]", "(vod)", "movie", "film"];
    final hasMovieIndicator = movieIndicators.any((i) => name.contains(i));

    final yearPatterns = [
      RegExp(r"\(19\d{2}\)"),
      RegExp(r"\(20[0-9]{2}\)"),
      RegExp(r"\[19\d{2}\]"),
      RegExp(r"\[20[0-9]{2}\]"),
    ];
    final hasYearPattern = yearPatterns.any((p) => p.hasMatch(name));

    if (isVideoFile && (hasMovieIndicator || hasYearPattern)) {
      final genre = _detectVodGenre(name);
      final path = genre != null ? "Movies > $genre" : "Movies";
      return CategorizationResult(
        categoryPath: path,
        categoryId: path.toLowerCase().replaceAll(" ", "_"),
        metadata: {"type": "movie", "genre": genre},
      );
    }

    if (isVideoFile && !hasMovieIndicator && !hasYearPattern) {
      if (name.contains("ep") || name.contains("part") || name.contains("pt")) {
        final genre = _detectVodGenre(name);
        final path = genre != null ? "Series > $genre" : "Series";
        return CategorizationResult(
          categoryPath: path,
          categoryId: path.toLowerCase().replaceAll(" ", "_"),
          metadata: {"type": "series", "genre": genre},
        );
      }

      final genre = _detectVodGenre(name);
      final path = genre != null ? "Movies > $genre" : "Movies";
      return CategorizationResult(
        categoryPath: path,
        categoryId: path.toLowerCase().replaceAll(" ", "_"),
        metadata: {"type": "movie", "genre": genre},
      );
    }

    if (hasMovieIndicator) {
      final genre = _detectVodGenre(name);
      final path = genre != null ? "Movies > $genre" : "Movies";
      return CategorizationResult(
        categoryPath: path,
        categoryId: path.toLowerCase().replaceAll(" ", "_"),
        metadata: {"type": "movie", "genre": genre},
      );
    }

    return null;
  }

  /// Detects genre for VOD content
  String? _detectVodGenre(String name) {
    if (name.contains("action") ||
        name.contains("adventure") ||
        name.contains("thriller")) {
      return "Action & Adventure";
    }
    if (name.contains("comedy") || name.contains("funny")) return "Comedy";
    if (name.contains("drama")) return "Drama";
    if (name.contains("horror") ||
        name.contains("scary") ||
        name.contains("fear"))
      return "Horror";
    if (name.contains("sci-fi") ||
        name.contains("scifi") ||
        name.contains("fantasy") ||
        name.contains("space"))
      return "Sci-Fi & Fantasy";
    if (name.contains("romance") || name.contains("love")) return "Romance";
    if (name.contains("animation") ||
        name.contains("animated") ||
        name.contains("cartoon") ||
        name.contains("kids"))
      return "Animation & Kids";
    if (name.contains("documentary") ||
        name.contains("docu") ||
        name.contains("true story"))
      return "Documentary";

    return null;
  }

  /// Detects country info
  CategorizationResult? _detectCountryInfo(String name) {
    const countryPatterns = {
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
      "ae": "UAE",
      "sa": "Saudi Arabia",
      "eg": "Egypt",
      "za": "South Africa",
      "il": "Israel",
      "in": "India",
      "pk": "Pakistan",
      "cn": "China",
      "jp": "Japan",
      "kr": "Korea",
      "au": "Australia",
      "nz": "New Zealand",
      "th": "Thailand",
      "sg": "Singapore",
      "ca": "Canada",
      "mx": "Mexico",
      "br": "Brazil",
      "ar": "Argentina",
    };

    for (final entry in countryPatterns.entries) {
      final code = entry.key;
      final country = entry.value;

      final patterns = [
        RegExp("^\\[$code\\]", caseSensitive: false),
        RegExp("^$code:", caseSensitive: false),
        RegExp("^$code\\s", caseSensitive: false),
        RegExp("\\|$code\\|", caseSensitive: false),
        RegExp("\\($code\\)", caseSensitive: false),
      ];

      for (final pattern in patterns) {
        if (pattern.hasMatch(name)) {
          final genre = _detectGenreFromName(name);
          final path = genre != null
              ? "Live TV > $genre > $country $genre"
              : "Live TV > $country";
          return CategorizationResult(
            categoryPath: path,
            categoryId: path.toLowerCase().replaceAll(" ", "_"),
            metadata: {"country": country, "genre": genre},
          );
        }
      }
    }

    return null;
  }

  /// Detects genre from channel name
  String? _detectGenreFromName(String name) {
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
  CategorizationResult? _detectGenreCategory(String name) {
    String? genre;

    if (name.contains("sport") ||
        name.contains("espn") ||
        name.contains("bein") ||
        name.contains("sky sports") ||
        name.contains("fox sports") ||
        name.contains("tsn") ||
        name.contains("eurosport")) {
      genre = "Sports";
    } else if (name.contains("news") ||
        name.contains("cnn") ||
        name.contains("bbc news") ||
        name.contains("fox news") ||
        name.contains("msnbc") ||
        name.contains("al jazeera")) {
      genre = "News";
    } else if (name.contains("kids") ||
        name.contains("cartoon") ||
        name.contains("disney") ||
        name.contains("nickelodeon") ||
        name.contains("nick jr") ||
        name.contains("baby tv")) {
      genre = "Kids";
    } else if (name.contains("music") ||
        name.contains("mtv") ||
        name.contains("vh1") ||
        name.contains("hit music")) {
      genre = "Music";
    } else if (name.contains("documentary") ||
        name.contains("discovery") ||
        name.contains("natgeo") ||
        name.contains("nat geo") ||
        name.contains("history") ||
        name.contains("animal planet")) {
      genre = "Documentary";
    } else if (name.contains("entertainment") ||
        name.contains("comedy") ||
        name.contains("hbo") ||
        name.contains("showtime")) {
      genre = "Entertainment";
    } else if (name.contains("religious") ||
        name.contains("islam") ||
        name.contains("christian") ||
        name.contains("gospel")) {
      genre = "Religious";
    }

    if (genre != null) {
      final path = "Live TV > $genre";
      return CategorizationResult(
        categoryPath: path,
        categoryId: path.toLowerCase().replaceAll(" ", "_"),
        metadata: {"genre": genre},
      );
    }

    return null;
  }
}
