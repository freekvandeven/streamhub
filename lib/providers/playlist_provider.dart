import "dart:async";
import "dart:io";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:http/http.dart" as http;
import "package:iptv_app/models/channel.dart";
import "package:iptv_app/services/m3u_parser.dart";
import "package:iptv_app/utils/logger.dart";

/// State for playlist loading
class PlaylistState {
  const PlaylistState({
    this.channels = const [],
    this.isLoading = false,
    this.error,
  });
  final List<Channel> channels;
  final bool isLoading;
  final String? error;

  PlaylistState copyWith({
    List<Channel>? channels,
    bool? isLoading,
    String? error,
  }) {
    return PlaylistState(
      channels: channels ?? this.channels,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for managing playlist state
class PlaylistNotifier extends StateNotifier<PlaylistState> {
  PlaylistNotifier() : super(const PlaylistState());

  /// Fetches and parses the M3U playlist from the given URL
  Future<void> fetchPlaylist(String url) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      Logger.info("Fetching playlist from: $url");

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

        Logger.network("Response status: ${response.statusCode}");
        Logger.data("Response headers: ${response.headers}");
        Logger.data("Response length: ${response.body.length} bytes");

        if (response.statusCode == 200) {
          Logger.success("Successfully fetched playlist");
          final channels = M3uParser.parse(response.body);
          Logger.success("Parsed ${channels.length} channels");

          state = PlaylistState(
            channels: channels,
            isLoading: false,
            error: null,
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
}

/// Provider for playlist state
final playlistProvider = StateNotifierProvider<PlaylistNotifier, PlaylistState>(
  (ref) {
    return PlaylistNotifier();
  },
);
