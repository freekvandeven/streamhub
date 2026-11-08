import "dart:async";

import "package:http/http.dart" as http;
import "package:streamhub/utils/logger.dart";

/// Thrown when the playlist server responds with a non-success status code
class HttpStatusException implements Exception {
  const HttpStatusException(this.statusCode, [this.reasonPhrase]);

  final int statusCode;
  final String? reasonPhrase;

  @override
  String toString() => ["HTTP $statusCode", if (reasonPhrase != null) reasonPhrase].join(" ");
}

/// A playlist being downloaded, whose content arrives as a stream
class PlaylistDownload {
  const PlaylistDownload(this.bytes, this.totalBytes);

  /// The playlist's content as it arrives. Must be listened to, to release
  /// the connection.
  final Stream<List<int>> bytes;

  /// The size of the playlist, if the server reported it
  final int? totalBytes;
}

/// Simple HTTP service for fetching playlists
abstract final class HttpService {
  static const _connectTimeout = Duration(seconds: 30);

  /// How long a download may stall before it's given up
  static const _idleTimeout = Duration(seconds: 60);

  /// Starts downloading the playlist at [url]. Its content is streamed, so a
  /// large playlist never has to fit in memory at once.
  ///
  /// Throws a [FormatException] if [url] is not an absolute http(s) URL and
  /// an [HttpStatusException] if the server doesn't respond with success.
  static Future<PlaylistDownload> downloadPlaylist(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme("http") || uri.isScheme("https")) || uri.host.isEmpty) {
      throw FormatException("Expected an http(s) URL", url);
    }

    Logger.network("Fetching playlist from: $uri");
    final client = http.Client();
    var streaming = false;
    try {
      final response = await client.send(http.Request("GET", uri)).timeout(_connectTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpStatusException(response.statusCode, response.reasonPhrase);
      }

      streaming = true;
      return PlaylistDownload(_readBody(client, response), response.contentLength);
    } finally {
      if (!streaming) client.close();
    }
  }

  static Stream<List<int>> _readBody(http.Client client, http.StreamedResponse response) async* {
    try {
      yield* response.stream.timeout(
        _idleTimeout,
        onTimeout: (sink) => sink
          ..addError(TimeoutException("No data received for ${_idleTimeout.inSeconds} seconds"))
          ..close(),
      );
    } finally {
      client.close();
    }
  }
}
