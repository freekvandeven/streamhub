import "dart:async";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:http/http.dart" as http;
import "package:streamhub/models/channel.dart";
import "package:streamhub/services/channel_categorizer.dart";
import "package:streamhub/services/m3u_parser.dart";
import "package:streamhub/services/playlist_storage.dart";
import "package:streamhub/utils/logger.dart";

/// State for playlist loading
class PlaylistState {
  const PlaylistState({
    this.channels = const [],
    this.isLoading = false,
    this.error,
    this.isFromCache = false,
    this.lastUpdateTime,
  });
  final List<Channel> channels;
  final bool isLoading;
  final String? error;
  final bool isFromCache;
  final DateTime? lastUpdateTime;

  PlaylistState copyWith({
    List<Channel>? channels,
    bool? isLoading,
    String? error,
    bool? isFromCache,
    DateTime? lastUpdateTime,
  }) {
    return PlaylistState(
      channels: channels ?? this.channels,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isFromCache: isFromCache ?? this.isFromCache,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
    );
  }
}

/// Notifier for managing playlist state
class PlaylistNotifier extends StateNotifier<PlaylistState> {
  PlaylistNotifier() : super(const PlaylistState());

  /// Loads playlist from cache if available
  Future<void> loadFromCache() async {
    // Set loading state while loading from cache
    state = state.copyWith(isLoading: true);

    try {
      // Load channels in chunks to keep UI responsive
      final cachedChannels = await _loadPlaylistInChunks();

      if (cachedChannels != null) {
        state = PlaylistState(
          channels: cachedChannels,
          isLoading: false,
          error: null,
          isFromCache: true,
          lastUpdateTime: PlaylistStorage.getLastUpdateTime(),
        );
        Logger.success("Loaded playlist from cache");
      } else {
        state = const PlaylistState(isLoading: false);
        Logger.info("No cached playlist available");
      }
    } on Exception catch (e) {
      Logger.error("Error loading from cache: $e");
      state = const PlaylistState(isLoading: false);
    }
  }

  /// Load playlist in chunks to prevent UI blocking
  Future<List<Channel>?> _loadPlaylistInChunks() async {
    final cachedData = await PlaylistStorage.loadPlaylistData();
    if (cachedData == null) return null;

    final channels = <Channel>[];
    const chunkSize = 1000;

    for (var i = 0; i < cachedData.length; i += chunkSize) {
      final end = (i + chunkSize < cachedData.length)
          ? i + chunkSize
          : cachedData.length;

      // Process chunk
      for (var j = i; j < end; j++) {
        final map = cachedData[j] as Map<dynamic, dynamic>;
        channels.add(
          Channel(
            name: map["name"] as String,
            url: map["url"] as String,
            tvgId: map["tvgId"] as String?,
            tvgName: map["tvgName"] as String?,
            tvgLogo: map["tvgLogo"] as String?,
            groupTitle: map["groupTitle"] as String?,
          ),
        );
      }

      // Yield to UI thread after each chunk
      await Future.delayed(Duration.zero);
    }

    return channels;
  }

  /// Parse playlist in background isolate
  static List<Channel> _parsePlaylistInBackground(String body) {
    return M3uParser.parse(body);
  }

  /// Categorize channels in chunks to prevent UI blocking
  Future<List<Channel>> _categorizeInChunks(List<Channel> channels) async {
    final categorized = <Channel>[];
    const chunkSize = 1000;

    for (var i = 0; i < channels.length; i += chunkSize) {
      final end = (i + chunkSize < channels.length)
          ? i + chunkSize
          : channels.length;

      final chunk = channels.sublist(i, end);
      categorized.addAll(ChannelCategorizer.categorize(chunk));

      // Yield to UI thread after each chunk
      await Future.delayed(Duration.zero);
    }

    return categorized;
  }

  /// Fetches and parses the M3U playlist from the given URL
  Future<void> fetchPlaylist(String url, {bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      Logger.info("Fetching playlist from: $url");

      // Track fetch timing
      final fetchStartTime = DateTime.now();

      // Create HTTP client with custom settings
      final client = http.Client();

      try {
        final response = await client
            .get(Uri.parse(url))
            .timeout(
              const Duration(seconds: 300),
              onTimeout: () {
                throw TimeoutException("Request timed out after 30 seconds");
              },
            );

        final fetchDuration = DateTime.now().difference(fetchStartTime);

        Logger.network("Response status: ${response.statusCode}");
        Logger.data("Response headers: ${response.headers}");
        Logger.data(
          "Response size: ${_formatBytes(response.body.length)} "
          "(${response.body.length} bytes)",
        );
        Logger.success(
          "Fetch completed in ${fetchDuration.inSeconds}."
          "${fetchDuration.inMilliseconds % 1000}s",
        );

        if (response.statusCode == 200) {
          Logger.info("Parsing M3U playlist...");
          final parseStartTime = DateTime.now();

          // Parse in background to avoid UI blocking
          final channels = await compute(
            _parsePlaylistInBackground,
            response.body,
          );

          final parseDuration = DateTime.now().difference(parseStartTime);

          Logger.success(
            "Parsed ${channels.length} channels in "
            "${parseDuration.inSeconds}."
            "${parseDuration.inMilliseconds % 1000}s",
          );

          // Categorize channels in chunks to keep UI responsive
          Logger.info("Categorizing channels...");
          final categorizedChannels = await _categorizeInChunks(channels);

          // Analyze categories
          final categoryStats = ChannelCategorizer.analyzeCategories(
            categorizedChannels,
          );
          Logger.data(
            "Found ${categoryStats['totalCategories']} categories, "
            "largest: '${categoryStats['largestCategory']}' "
            "(${categoryStats['largestCategoryCount']} channels)",
          );

          // Save to local storage
          Logger.info("Saving playlist to local storage...");
          await PlaylistStorage.savePlaylist(
            categorizedChannels,
            url,
          );

          state = PlaylistState(
            channels: categorizedChannels,
            isLoading: false,
            error: null,
            isFromCache: false,
            lastUpdateTime: DateTime.now(),
          );
        } else {
          final errorMsg =
              "HTTP ${response.statusCode}: ${response.reasonPhrase}";
          Logger.error("Failed: $errorMsg");
          final previewLength = response.body.length > 200
              ? 200
              : response.body.length;
          final preview = response.body.substring(0, previewLength);
          Logger.data("Response body preview: $preview");

          state = PlaylistState(
            channels: [],
            isLoading: false,
            error: errorMsg,
          );
        }
      } finally {
        client.close();
      }
    } on TimeoutException catch (e) {
      const errorMsg = "Connection timeout - server took too long to respond";
      Logger.error("Timeout: $e");
      state = const PlaylistState(
        channels: [],
        isLoading: false,
        error: errorMsg,
      );
    } on SocketException catch (e) {
      final errorMsg =
          "Network error: ${e.message}. Check your internet connection.";
      Logger.error("Socket error: $e");
      state = PlaylistState(
        channels: [],
        isLoading: false,
        error: errorMsg,
      );
    } on HandshakeException catch (e) {
      const errorMsg =
          "SSL/TLS error: Unable to establish secure connection. "
          "The server may have an invalid certificate.";
      Logger.error("SSL error: $e");
      state = const PlaylistState(
        channels: [],
        isLoading: false,
        error: errorMsg,
      );
    } on HttpException catch (e) {
      final errorMsg = "HTTP error: ${e.message}";
      Logger.error("HTTP error: $e");
      state = PlaylistState(
        channels: [],
        isLoading: false,
        error: errorMsg,
      );
    } on FormatException catch (e) {
      final errorMsg = "Invalid URL format: ${e.message}";
      Logger.error("Format error: $e");
      state = PlaylistState(
        channels: [],
        isLoading: false,
        error: errorMsg,
      );
    } on Exception catch (e, stackTrace) {
      final errorMsg = "Unexpected error: $e";
      Logger.error("Unexpected error: $e");
      Logger.error("Stack trace: $stackTrace");
      state = PlaylistState(
        channels: [],
        isLoading: false,
        error: errorMsg,
      );
    }
  }

  /// Clears the current playlist
  void clear() {
    state = const PlaylistState();
  }

  /// Formats bytes to human-readable string
  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) {
      return "${(bytes / 1024).toStringAsFixed(2)} KB";
    }
    if (bytes < 1024 * 1024 * 1024) {
      return "${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB";
    }
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB";
  }
}

/// Provider for playlist state
final playlistProvider = StateNotifierProvider<PlaylistNotifier, PlaylistState>(
  (ref) {
    return PlaylistNotifier();
  },
);
