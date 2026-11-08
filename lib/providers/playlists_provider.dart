import "dart:async";
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
import "package:streamhub/utils/formatting.dart";
import "package:streamhub/utils/logger.dart";
import "package:streamhub/utils/redact.dart";
import "package:streamhub/utils/wakelock.dart";

/// How far a playlist download has come
class DownloadProgress {
  const DownloadProgress({this.receivedBytes = 0, this.totalBytes, this.channels = 0, this.startedAt});

  final int receivedBytes;

  /// The size of the playlist, if the server reported it
  final int? totalBytes;

  /// Channels found so far
  final int channels;

  /// When the download was started
  final DateTime? startedAt;

  /// Whether the server is still preparing the playlist
  bool get isWaiting => receivedBytes == 0;

  /// How much has been downloaded, from 0 to 1, or null if the size is unknown
  double? get fraction {
    final total = totalBytes;
    return total == null || total <= 0 ? null : (receivedBytes / total).clamp(0.0, 1.0);
  }
}

/// State for playlists management
class PlaylistsState {
  const PlaylistsState({
    this.playlists = const [],
    this.activePlaylistId,
    this.isLoading = false,
    this.error,
    this.downloadProgress,
  });

  final List<Playlist> playlists;
  final String? activePlaylistId;
  final bool isLoading;
  final String? error;

  /// Set while a playlist downloads
  final DownloadProgress? downloadProgress;

  Playlist? get activePlaylist => playlists.where((p) => p.id == activePlaylistId).firstOrNull;

  PlaylistsState copyWith({
    List<Playlist>? playlists,
    String? activePlaylistId,
    bool? isLoading,
    String? error,
    bool clearError = false,
    DownloadProgress? downloadProgress,
    bool clearDownloadProgress = false,
  }) {
    return PlaylistsState(
      playlists: playlists ?? this.playlists,
      activePlaylistId: activePlaylistId ?? this.activePlaylistId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      downloadProgress: clearDownloadProgress ? null : (downloadProgress ?? this.downloadProgress),
    );
  }
}

/// Notifier for managing multiple playlists
class PlaylistsNotifier extends Notifier<PlaylistsState> {
  /// How often the progress of a download is logged
  static const _logInterval = Duration(seconds: 5);

  PlaylistStorage get _storage => ref.read(playlistStorageProvider);
  HttpService get _http => ref.read(httpServiceProvider);

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
      playlists = await _storage.loadAllPlaylists();
      activeId = await _storage.getActivePlaylistId();
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
    PlaylistWriter? unfinishedWriter;
    // Large playlists take minutes; don't let the screen turn off meanwhile
    unawaited(Wakelock.acquire());

    // How far the download got, for the log
    final stopwatch = Stopwatch();
    PlaylistDownload? download;
    var receivedBytes = 0;
    final channels = <Channel>[];

    try {
      final existingPlaylist = state.playlists.where((p) => p.url == url).firstOrNull;

      if (existingPlaylist != null && !forceRefresh) {
        Logger.info("Playlist already exists, activating it");
        await setActivePlaylist(existingPlaylist.id);
        return;
      }

      Logger.info("${existingPlaylist == null ? "Adding" : "Refreshing"} playlist '$name'");
      stopwatch.start();
      final startedAt = DateTime.now();
      DownloadProgress progress() => DownloadProgress(
        receivedBytes: receivedBytes,
        totalBytes: download?.totalBytes,
        channels: channels.length,
        startedAt: startedAt,
      );
      state = state.copyWith(downloadProgress: progress());
      final currentDownload = download = await _http.downloadPlaylist(url);
      state = state.copyWith(downloadProgress: progress());
      final playlistId = existingPlaylist?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      final writer = unfinishedWriter = _storage.startWriting(playlistId);

      // Parse and store the playlist while it downloads, so a playlist of
      // hundreds of megabytes is never held in memory as a whole
      final parser = M3uParser.parseChunks((channel) {
        final categorized = ChannelCategorizer.categorizeChannel(channel);
        channels.add(categorized);
        writer.add(categorized);
      });
      var reportedBytes = 0;
      final sinceReport = Stopwatch()..start();
      final sinceLog = Stopwatch()..start();
      Duration? waited;
      await for (final chunk in currentDownload.bytes) {
        final transferStart = waited ??= stopwatch.elapsed;
        parser.add(chunk);
        receivedBytes += chunk.length;
        // Report progress regularly, but not for every network packet
        if (sinceReport.elapsedMilliseconds >= 200 || receivedBytes - reportedBytes >= 1 << 20) {
          sinceReport.reset();
          reportedBytes = receivedBytes;
          state = state.copyWith(downloadProgress: progress());
        }
        if (sinceLog.elapsed >= _logInterval) {
          sinceLog.reset();
          Logger.data(
            "Received ${_describeReceived(receivedBytes, currentDownload.totalBytes)} at "
            "${_formatSpeed(receivedBytes, stopwatch.elapsed - transferStart)}, ${channels.length} channels",
          );
        }
        // Also slows the download down if storage can't keep up
        await writer.flush();
      }
      parser.close();
      final downloadTime = stopwatch.elapsed;
      final waitTime = waited ?? downloadTime;
      final transferTime = downloadTime - waitTime;
      Logger.success(
        "Downloaded ${formatBytes(receivedBytes)} with ${channels.length} channels in "
        "${formatDuration(downloadTime)}: waited ${formatDuration(waitTime)} for the server, then "
        "received the playlist in ${formatDuration(transferTime)} at ${_formatSpeed(receivedBytes, transferTime)}",
      );
      if (channels.isEmpty) Logger.warning("The playlist contains no channels");

      final playlist = Playlist(
        id: playlistId,
        name: name,
        url: url,
        channels: channels,
        lastUpdate: DateTime.now(),
      );
      await writer.commit(playlist);
      unfinishedWriter = null;

      if (existingPlaylist == null) {
        // Newly added playlists become the active one
        await _storage.setActivePlaylistId(playlist.id);
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
      final stage = switch (download) {
        null => "before the server responded",
        _ when receivedBytes == 0 => "before the server sent any data",
        PlaylistDownload(:final totalBytes) =>
          "after receiving ${_describeReceived(receivedBytes, totalBytes)} "
              "with ${channels.length} channels",
      };
      Logger.error(
        "Failed to fetch playlist after ${formatDuration(stopwatch.elapsed)}, $stage: $e",
        stackTrace,
      );
      error = _describeFetchError(e);
    } finally {
      // Throw away what was stored of a download that failed partway
      if (unfinishedWriter != null) unawaited(unfinishedWriter.discard());
      state = state.copyWith(isLoading: false, error: error, clearDownloadProgress: true);
      unawaited(Wakelock.release());
    }
  }

  /// Sets the active playlist
  Future<void> setActivePlaylist(String playlistId) async {
    await _storage.setActivePlaylistId(playlistId);
    state = state.copyWith(activePlaylistId: playlistId);
  }

  /// Removes a playlist
  Future<void> removePlaylist(String playlistId) async {
    await _storage.removePlaylist(playlistId);

    final playlists = [
      for (final p in state.playlists)
        if (p.id != playlistId) p,
    ];

    // If the removed playlist was active, fall back to the first one
    var activeId = state.activePlaylistId;
    if (activeId == playlistId) {
      activeId = playlists.firstOrNull?.id;
      await _storage.setActivePlaylistId(activeId);
    }

    state = PlaylistsState(playlists: playlists, activePlaylistId: activeId);
  }
}

/// Converts a fetch failure into a message for the user
String _describeFetchError(Exception error) {
  final message = switch (error) {
    TimeoutException(message: final message?) => message,
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
  // Some errors include the playlist URL, with the account's password
  return redactUrls(message);
}

/// Describes how much of a download was received, e.g. "1.00 MB of 4.00 MB (25%)"
String _describeReceived(int receivedBytes, int? totalBytes) {
  if (totalBytes == null || totalBytes <= 0) return formatBytes(receivedBytes);
  return "${formatBytes(receivedBytes)} of ${formatBytes(totalBytes)} (${receivedBytes * 100 ~/ totalBytes}%)";
}

String _formatSpeed(int bytes, Duration duration) {
  final seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;
  return seconds <= 0 ? "-" : "${formatBytes(bytes ~/ seconds)}/s";
}

/// Provider for playlists state
final playlistsProvider = NotifierProvider<PlaylistsNotifier, PlaylistsState>(
  PlaylistsNotifier.new,
);
