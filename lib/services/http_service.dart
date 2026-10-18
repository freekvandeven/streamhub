import "dart:typed_data";

import "package:http/http.dart" as http;
import "package:streamhub/utils/logger.dart";

/// Thrown when the playlist server responds with a non-success status code
class HttpStatusException implements Exception {
  const HttpStatusException(this.statusCode, [this.reasonPhrase]);

  final int statusCode;
  final String? reasonPhrase;

  @override
  String toString() =>
      ["HTTP $statusCode", if (reasonPhrase != null) reasonPhrase].join(" ");
}

/// Simple HTTP service for fetching playlists
abstract final class HttpService {
  /// Downloads the raw playlist bytes from [url]
  ///
  /// Throws a [FormatException] if [url] is not an absolute http(s) URL and
  /// an [HttpStatusException] if the server doesn't respond with success.
  static Future<Uint8List> fetchPlaylist(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !(uri.isScheme("http") || uri.isScheme("https")) ||
        uri.host.isEmpty) {
      throw FormatException("Expected an http(s) URL", url);
    }

    Logger.network("Fetching playlist from: $uri");
    final response = await http.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpStatusException(response.statusCode, response.reasonPhrase);
    }

    // Return bytes rather than `response.body`, which falls back to Latin-1
    // when the server doesn't send a charset. Playlists are UTF-8.
    return response.bodyBytes;
  }
}
