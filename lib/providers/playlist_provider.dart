import "dart:async";
import "dart:io";

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
    final cachedChannels = await PlaylistStorage.loadPlaylist();
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
      Logger.info("No cached playlist available");
    }
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

          var channels = M3uParser.parse(response.body);

          final parseDuration = DateTime.now().difference(parseStartTime);

          Logger.success(
            "Parsed ${channels.length} channels in "
            "${parseDuration.inSeconds}."
            "${parseDuration.inMilliseconds % 1000}s",
          );

          // Categorize channels
          Logger.info("Categorizing channels...");
          channels = ChannelCategorizer.categorize(channels);

          // Analyze categories
          final categoryStats = ChannelCategorizer.analyzeCategories(channels);
          Logger.data(
            "Found ${categoryStats['totalCategories']} categories, "
            "largest: '${categoryStats['largestCategory']}' "
            "(${categoryStats['largestCategoryCount']} channels)",
          );

          // Save to local storage
          Logger.info("Saving playlist to local storage...");
          await PlaylistStorage.savePlaylist(
            channels,
            url,
          );

          state = PlaylistState(
            channels: channels,
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
