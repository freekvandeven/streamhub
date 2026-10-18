import "dart:async";
import "dart:convert";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:http/http.dart" as http;
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

  Playlist? get activePlaylist => playlists.where((p) => p.id == activePlaylistId).firstOrNull;

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
class PlaylistsNotifier extends Notifier<PlaylistsState> {
  static const _fetchTimeout = Duration(minutes: 5);

  @override
  PlaylistsState build() {
    unawaited(_loadFromStorage());
    return const PlaylistsState(isLoading: true);
  }

  /// Loads all playlists from storage
  Future<void> _loadFromStorage() async {
    var playlists = const <Playlist>[];
    String? activeId;
    String? error;

    try {
      playlists = await PlaylistStorage.loadAllPlaylists();
      activeId = await PlaylistStorage.getActivePlaylistId();
    } on Exception catch (e) {
      Logger.error("Failed to load playlists: $e");
      error = "Could not load saved playlists: $e";
    } finally {
      state = PlaylistsState(
        playlists: playlists,
        activePlaylistId: activeId,
        error: error,
      );
    }
  }

  /// Fetches a playlist from URL and adds it or updates existing
  ///
  /// If a playlist with the same URL already exists it is activated instead,
  /// unless [forceRefresh] is set.
  Future<void> fetchPlaylist({
    required String url,
    required String name,
    bool forceRefresh = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    String? error;

    try {
      final existingPlaylist = state.playlists.where((p) => p.url == url).firstOrNull;

      if (existingPlaylist != null && !forceRefresh) {
        Logger.info("Playlist already exists, activating it");
        await setActivePlaylist(existingPlaylist.id);
        return;
      }

      final stopwatch = Stopwatch()..start();
      final bytes = await HttpService.fetchPlaylist(url).timeout(
        _fetchTimeout,
      );
      Logger.data(
        "Fetched ${_formatBytes(bytes.length)} in "
        "${_formatDuration(stopwatch.elapsed)}",
      );

      stopwatch.reset();
      final channels = await compute(_parsePlaylist, bytes);
      Logger.success(
        "Parsed and categorized ${channels.length} channels in "
        "${_formatDuration(stopwatch.elapsed)}",
      );

      final playlist = Playlist(
        id: existingPlaylist?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        url: url,
        channels: channels,
        lastUpdate: DateTime.now(),
      );
      await PlaylistStorage.savePlaylist(playlist);

      if (existingPlaylist == null) {
        // Newly added playlists become the active one
        await PlaylistStorage.setActivePlaylistId(playlist.id);
        state = state.copyWith(
          playlists: [...state.playlists, playlist],
          activePlaylistId: playlist.id,
        );
      } else {
        state = state.copyWith(
          playlists: [
            for (final p in state.playlists)
              if (p.id == playlist.id) playlist else p,
          ],
        );
      }
    } on Exception catch (e, stackTrace) {
      Logger.error("Failed to fetch playlist: $e\n$stackTrace");
      error = _describeFetchError(e);
    } finally {
      state = state.copyWith(isLoading: false, error: error);
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

    final playlists = [
      for (final p in state.playlists)
        if (p.id != playlistId) p,
    ];

    // If the removed playlist was active, fall back to the first one
    var activeId = state.activePlaylistId;
    if (activeId == playlistId) {
      activeId = playlists.firstOrNull?.id;
      await PlaylistStorage.setActivePlaylistId(activeId);
    }

    state = PlaylistsState(playlists: playlists, activePlaylistId: activeId);
  }
}

/// Decodes, parses and categorizes a playlist. Runs in a background isolate.
List<Channel> _parsePlaylist(Uint8List bytes) {
  final content = utf8.decode(bytes, allowMalformed: true);
  return ChannelCategorizer.categorize(M3uParser.parse(content));
}

/// Converts a fetch failure into a message for the user
String _describeFetchError(Exception error) {
  return switch (error) {
    TimeoutException() => "Connection timeout - server took too long to respond",
    HandshakeException() =>
      "SSL/TLS error: Unable to establish secure connection. "
          "The server may have an invalid certificate.",
    SocketException(:final message) => "Network error: $message. Check your internet connection.",
    // Browsers hide the cause of failed requests, which is usually CORS
    http.ClientException() when kIsWeb =>
      "Failed to load playlist. The server may not allow requests from a "
          "browser (CORS). Try a CORS-enabled playlist or use the "
          "mobile/desktop app.",
    http.ClientException(:final message) => "Network error: $message",
    HttpStatusException() => "Server error: $error",
    FormatException(:final message) => "Invalid URL: $message",
    _ => "Unexpected error: $error",
  };
}

/// Formats bytes to human-readable string
String _formatBytes(int bytes) {
  const units = ["B", "KB", "MB", "GB"];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return unit == 0 ? "$bytes B" : "${size.toStringAsFixed(2)} ${units[unit]}";
}

String _formatDuration(Duration duration) => "${(duration.inMilliseconds / 1000).toStringAsFixed(2)}s";

/// Provider for playlists state
final playlistsProvider = NotifierProvider<PlaylistsNotifier, PlaylistsState>(
  PlaylistsNotifier.new,
);
