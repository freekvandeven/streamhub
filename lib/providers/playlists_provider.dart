import "dart:async";
import "dart:io";

import "package:channel_categorizer/channel_categorizer.dart";
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/models/playlist.dart";
import "package:streamhub/services/channel_categorizer.dart";
import "package:streamhub/services/http_service.dart";
import "package:streamhub/services/m3u_parser.dart";
import "package:streamhub/services/playlist_storage.dart";
import "package:streamhub/utils/logger.dart";

/// State for playlists management
class PlaylistsState {
  const PlaylistsState({
    this.playlists = const [],
    this.activePlaylistId,
    this.isLoading = false,
    this.error,
  });

  final List<Playlist> playlists;
  final String? activePlaylistId;
  final bool isLoading;
  final String? error;

  Playlist? get activePlaylist =>
      playlists.where((p) => p.id == activePlaylistId).firstOrNull;

  PlaylistsState copyWith({
    List<Playlist>? playlists,
    String? activePlaylistId,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return PlaylistsState(
      playlists: playlists ?? this.playlists,
      activePlaylistId: activePlaylistId ?? this.activePlaylistId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Notifier for managing multiple playlists
class PlaylistsNotifier extends StateNotifier<PlaylistsState> {
  PlaylistsNotifier() : super(const PlaylistsState());

  /// Loads all playlists from storage
  Future<void> loadPlaylists() async {
    state = state.copyWith(isLoading: true);

    final playlists = await PlaylistStorage.loadAllPlaylists();
    final activeId = await PlaylistStorage.getActivePlaylistId();

    state = PlaylistsState(
      playlists: playlists,
      activePlaylistId: activeId,
      isLoading: false,
    );
  }

  /// Parse playlist in background isolate
  static List<dynamic> _parseAndCategorizePlaylistInBackground(String body) {
    final channels = M3uParser.parse(body);
    final categorized = ChannelCategorizer.categorize(channels);
    final categoryTree = ChannelCategorizer.buildCategoryTree(categorized);

    return [categorized, categoryTree];
  }

  /// Fetches a playlist from URL and adds it or updates existing
  Future<void> fetchPlaylist({
    required String url,
    required String name,
    bool forceRefresh = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Check if playlist with this URL already exists
      final existingPlaylist = await PlaylistStorage.findPlaylistByUrl(url);

      if (existingPlaylist != null && !forceRefresh) {
        Logger.info("Playlist already exists, activating it");
        await PlaylistStorage.setActivePlaylistId(existingPlaylist.id);
        await loadPlaylists();
        return;
      }

      Logger.info("Fetching playlist from: $url");

      final fetchStartTime = DateTime.now();

      final body = await HttpService.fetchPlaylist(url)
          .timeout(
            const Duration(seconds: 300),
            onTimeout: () {
              throw TimeoutException("Request timed out after 300 seconds");
            },
          );

      final fetchDuration = DateTime.now().difference(fetchStartTime);

      Logger.data(
        "Response size: ${_formatBytes(body.length)} "
        "(${body.length} bytes)",
      );
      Logger.success(
        "Fetch completed in ${fetchDuration.inSeconds}."
        "${fetchDuration.inMilliseconds % 1000}s",
      );

      Logger.info("Parsing and categorizing M3U playlist...");
      final parseStartTime = DateTime.now();

      // Parse and categorize in background
      final result = await compute(
        _parseAndCategorizePlaylistInBackground,
        body,
      );

      final categorizedChannels = (result[0] as List<dynamic>)
          .cast<Channel>();
      final categoryTree = result[1] as CategoryNode;

      final parseDuration = DateTime.now().difference(parseStartTime);

      Logger.success(
        "Parsed and categorized ${categorizedChannels.length} channels in "
        "${parseDuration.inSeconds}."
        "${parseDuration.inMilliseconds % 1000}s",
      );

      // Create or update playlist
      final playlistId =
          existingPlaylist?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();

      final playlist = Playlist(
        id: playlistId,
        name: name,
        url: url,
        channels: categorizedChannels,
        lastUpdate: DateTime.now(),
      );

      // Save playlist
      await PlaylistStorage.savePlaylist(playlist);

      // Save categorized data
      const categorizer = DefaultChannelCategorizer();
      unawaited(
        PlaylistStorage.saveCategorizedData(
          categoryTree: categoryTree,
          categorizerId: categorizer.categorizerId,
          categorizerVersion: categorizer.version,
          totalChannels: categorizedChannels.length,
        ),
      );

      // Reload playlists
      await loadPlaylists();

      state = state.copyWith(isLoading: false);
    } on TimeoutException catch (e) {
      const errorMsg = "Connection timeout - server took too long to respond";
      Logger.error("Timeout: $e");
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
    } on SocketException catch (e) {
      final errorMsg =
          "Network error: ${e.message}. Check your internet connection.";
      Logger.error("Socket error: $e");
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
    } on HandshakeException catch (e) {
      const errorMsg =
          "SSL/TLS error: Unable to establish secure connection. "
          "The server may have an invalid certificate.";
      Logger.error("SSL error: $e");
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
    } on HttpException catch (e) {
      final errorMsg = "HTTP error: ${e.message}";
      Logger.error("HTTP error: $e");
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
    } on FormatException catch (e) {
      final errorMsg = "Invalid URL format: ${e.message}";
      Logger.error("Format error: $e");
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
    } on Exception catch (e, stackTrace) {
      final errorMsg = "Unexpected error: $e";
      Logger.error("Unexpected error: $e");
      Logger.error("Stack trace: $stackTrace");
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
    }
  }

  /// Sets the active playlist
  Future<void> setActivePlaylist(String playlistId) async {
    await PlaylistStorage.setActivePlaylistId(playlistId);
    state = state.copyWith(activePlaylistId: playlistId);
  }

  /// Removes a playlist
  Future<void> removePlaylist(String playlistId) async {
    await PlaylistStorage.removePlaylist(playlistId);
    await loadPlaylists();
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

/// Provider for playlists state
final playlistsProvider =
    StateNotifierProvider<PlaylistsNotifier, PlaylistsState>(
      (ref) => PlaylistsNotifier(),
    );
