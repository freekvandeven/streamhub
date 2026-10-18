import "package:channel_categorizer/src/categorizer_interface.dart";

/// Default channel categorizer with smart pattern-based categorization
/// Analyzes channel names, URLs, and metadata to extract hierarchical
/// categories
class DefaultChannelCategorizer implements ChannelCategorizerInterface {
  const DefaultChannelCategorizer();

  /// File extensions that indicate on-demand content. Live stream formats
  /// such as `.ts` and `.m3u8` are deliberately not included.
  static const _vodExtensions = [
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
  ];

  static final _seriesPattern = RegExp(
    [
      r"s\d{1,2}\s*e\d{1,2}", // S01E01, S1E1, S1 E1
      r"season\s*\d+", // Season 1
      r"episode\s*\d+", // Episode 1
      r"\|\s*s\d+", // | S1
      r"\bs\d{2}\b", // S01 (standalone)
    ].join("|"),
  );

  /// Episode-like naming that the stricter series patterns don't cover
  static final _episodePattern = RegExp(r"\b(?:ep|part|pt)\.?\s*\d+");

  static const _movieIndicators = ["[vod]", "(vod)", "movie", "film"];

  static final _yearPattern = RegExp(r"\((?:19|20)\d{2}\)|\[(?:19|20)\d{2}\]");

  static const _countries = {
    // Europe
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

  static final _countryCodes = _countries.keys.join("|");

  /// Tagged country codes: [UK], UK:, |UK| or (UK)
  static final _countryTagPattern = RegExp(
    "^\\[($_countryCodes)\\]|^($_countryCodes):"
    "|\\|($_countryCodes)\\||\\(($_countryCodes)\\)",
    caseSensitive: false,
  );

  /// A bare country code at the start, e.g. "UK BBC One". Only upper case
  /// codes match, so names like "In the Night Garden" aren't seen as India.
  static final _countryPrefixPattern = RegExp(
    "^(${_countryCodes.toUpperCase()})\\s",
  );

  /// Genre keywords for channels with a detected country, checked in order
  static const _countryGenres = {
    "Sports": ["sport"],
    "News": ["news"],
    "Kids": ["kids", "cartoon"],
    "Music": ["music", "mtv"],
    "Documentary": ["docu"],
    "Entertainment": ["entertain"],
    "Movies": ["movie", "cinema"],
    "Series": ["series"],
  };

  /// Genre keywords for live channels without a country, checked in order
  static const _liveGenres = {
    "Sports": ["sport", "espn", "bein", "tsn"],
    "News": ["news", "cnn", "msnbc", "al jazeera"],
    "Kids": [
      "kids",
      "cartoon",
      "disney",
      "nickelodeon",
      "nick jr",
      "baby tv",
    ],
    "Music": ["music", "mtv", "vh1"],
    "Documentary": [
      "documentary",
      "discovery",
      "natgeo",
      "nat geo",
      "history",
      "animal planet",
    ],
    "Entertainment": ["entertainment", "comedy", "hbo", "showtime"],
    "Religious": ["religious", "islam", "christian", "gospel"],
  };

  /// Genre keywords for movies and series, checked in order
  static const _vodGenres = {
    "Action & Adventure": ["action", "adventure", "thriller"],
    "Comedy": ["comedy", "funny"],
    "Drama": ["drama"],
    "Horror": ["horror", "scary", "fear"],
    "Sci-Fi & Fantasy": ["sci-fi", "scifi", "fantasy", "space"],
    "Romance": ["romance", "love"],
    "Animation & Kids": ["animation", "animated", "cartoon", "kids"],
    "Documentary": ["docu", "true story"],
  };

  @override
  String get categorizerId => "default";

  @override
  String get version => "1.1.0";

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
      return _result(groupTitle);
    }

    final lowerName = name.toLowerCase();

    return _detectVodCategory(lowerName, isVideoFile: _isVideoFileUrl(url)) ??
        _detectCountryCategory(name, lowerName) ??
        _detectGenreCategory(lowerName) ??
        _result("Live TV");
  }

  /// Checks if the URL path points to an on-demand video file
  static bool _isVideoFileUrl(String url) {
    final path = (Uri.tryParse(url)?.path ?? url).toLowerCase();
    return _vodExtensions.any(path.endsWith);
  }

  /// Detects movies and series
  static CategorizationResult? _detectVodCategory(
    String name, {
    required bool isVideoFile,
  }) {
    if (_seriesPattern.hasMatch(name)) {
      return _vodResult(name, isSeries: true);
    }

    final hasMovieIndicator = _movieIndicators.any(name.contains);

    if (isVideoFile) {
      // Without explicit movie hints, episode-like naming suggests a series
      final isSeries =
          !hasMovieIndicator &&
          !_yearPattern.hasMatch(name) &&
          _episodePattern.hasMatch(name);
      return _vodResult(name, isSeries: isSeries);
    }

    if (hasMovieIndicator) {
      return _vodResult(name, isSeries: false);
    }

    return null;
  }

  static CategorizationResult _vodResult(
    String name, {
    required bool isSeries,
  }) {
    final root = isSeries ? "Series" : "Movies";
    final genre = _matchGenre(_vodGenres, name);
    return _result(
      genre != null ? "$root > $genre" : root,
      metadata: {"type": isSeries ? "series" : "movie", "genre": genre},
    );
  }

  /// Detects country-specific channels, e.g. "Live TV > Sports > UK Sports"
  static CategorizationResult? _detectCountryCategory(
    String name,
    String lowerName,
  ) {
    final match =
        _countryPrefixPattern.firstMatch(name) ??
        _countryTagPattern.firstMatch(name);
    if (match == null) return null;

    final code = [
      for (var i = 1; i <= match.groupCount; i++) match.group(i),
    ].nonNulls.first.toLowerCase();
    final country = _countries[code]!;
    final genre = _matchGenre(_countryGenres, lowerName);
    final path = genre != null
        ? "Live TV > $genre > $country $genre"
        : "Live TV > $country";

    return _result(path, metadata: {"country": country, "genre": genre});
  }

  /// Detects genre-based live channel categories
  static CategorizationResult? _detectGenreCategory(String name) {
    final genre = _matchGenre(_liveGenres, name);
    if (genre == null) return null;

    return _result("Live TV > $genre", metadata: {"genre": genre});
  }

  /// Returns the first genre whose keywords appear in [name]
  static String? _matchGenre(Map<String, List<String>> genres, String name) {
    for (final MapEntry(key: genre, value: keywords) in genres.entries) {
      if (keywords.any(name.contains)) return genre;
    }
    return null;
  }

  static CategorizationResult _result(
    String path, {
    Map<String, dynamic> metadata = const {},
  }) {
    return CategorizationResult(
      categoryPath: path,
      categoryId: path.toLowerCase().replaceAll(" ", "_"),
      metadata: metadata,
    );
  }
}
