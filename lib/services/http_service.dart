import "dart:async";

import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:http/http.dart" as http;
import "package:streamhub/services/http_client_web.dart"
    if (dart.library.io) "package:streamhub/services/http_client_io.dart";
import "package:streamhub/utils/formatting.dart";
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

/// Downloads playlists
///
/// Xtream Codes servers (`get.php`) generate the whole playlist before they
/// send anything, which takes minutes for accounts with many channels. So
/// connecting may only take [connectTimeout], but the server gets
/// [responseTimeout] to start sending the playlist. After that the download
/// may only stall for [idleTimeout].
class HttpService {
  const HttpService({
    this.connectTimeout = const Duration(seconds: 30),
    this.responseTimeout = const Duration(minutes: 5),
    this.idleTimeout = const Duration(seconds: 60),
  });

  /// How long connecting to the server may take. Not supported on web.
  final Duration connectTimeout;

  /// How long the server may take to start sending the playlist, counted
  /// from the request
  final Duration responseTimeout;

  /// How long the download may stall once it has started
  final Duration idleTimeout;

  /// Starts downloading the playlist at [url]. Its content is streamed, so a
  /// large playlist never has to fit in memory at once.
  ///
  /// Throws a [FormatException] if [url] is not an absolute http(s) URL, an
  /// [HttpStatusException] if the server doesn't respond with success and a
  /// [TimeoutException] if it doesn't respond in time.
  Future<PlaylistDownload> downloadPlaylist(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme("http") || uri.isScheme("https")) || uri.host.isEmpty) {
      // Not passing the URL along, as errors end up in the log
      throw const FormatException("Expected an http(s) URL");
    }

    Logger.network("GET $uri");
    final stopwatch = Stopwatch()..start();
    final client = createHttpClient(connectTimeout: connectTimeout);
    var streaming = false;
    try {
      final response = await client
          .send(http.Request("GET", uri))
          .timeout(responseTimeout, onTimeout: () => throw _notStartedError());
      Logger.network("Server responded after ${formatDuration(stopwatch.elapsed)}: ${_describe(response, uri)}");
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpStatusException(response.statusCode, response.reasonPhrase);
      }

      streaming = true;
      return PlaylistDownload(_readBody(client, response.stream, stopwatch), response.contentLength);
    } finally {
      if (!streaming) client.close();
    }
  }

  /// Forwards [body] and closes [client] when it's done. Fails if no data
  /// arrives within [responseTimeout] of the request, or the data then stops
  /// for longer than [idleTimeout]. Time the listener spends paused doesn't
  /// count.
  Stream<List<int>> _readBody(http.Client client, Stream<List<int>> body, Stopwatch stopwatch) {
    final controller = StreamController<List<int>>();
    StreamSubscription<List<int>>? subscription;
    Timer? timer;
    var started = false;

    void close() {
      timer?.cancel();
      client.close();
      unawaited(controller.close());
    }

    void startTimer() {
      timer?.cancel();
      final timeLimit = started ? idleTimeout : responseTimeout - stopwatch.elapsed;
      timer = Timer(timeLimit, () {
        controller.addError(
          started
              ? TimeoutException("The download stalled: no data received for ${formatDuration(idleTimeout)}")
              : _notStartedError(),
        );
        unawaited(subscription?.cancel());
        close();
      });
    }

    controller
      ..onListen = () {
        startTimer();
        subscription = body.listen(
          (chunk) {
            if (!started) {
              started = true;
              Logger.network("Receiving data after ${formatDuration(stopwatch.elapsed)}");
            }
            startTimer();
            controller.add(chunk);
          },
          onError: controller.addError,
          onDone: close,
        );
      }
      ..onPause = () {
        timer?.cancel();
        subscription?.pause();
      }
      ..onResume = () {
        subscription?.resume();
        startTimer();
      }
      ..onCancel = () async {
        timer?.cancel();
        await subscription?.cancel();
        client.close();
      };
    return controller.stream;
  }

  TimeoutException _notStartedError() {
    return TimeoutException(
      "The server didn't start sending the playlist within ${formatDuration(responseTimeout)}",
      responseTimeout,
    );
  }

  /// Summarizes [response] to the request for [uri], for the log
  static String _describe(http.StreamedResponse response, Uri uri) {
    final headers = response.headers;
    return [
      ["HTTP ${response.statusCode}", ?response.reasonPhrase].join(" "),
      if (response case http.BaseResponseWithUrl(:final url) when url != uri) "redirected to $url",
      switch (response.contentLength) {
        final length? => formatBytes(length),
        null => "size unknown",
      },
      for (final name in const ["content-type", "content-encoding", "transfer-encoding", "server"])
        if (headers[name] case final value?) "$name: $value",
    ].join(", ");
  }
}

final httpServiceProvider = Provider<HttpService>((ref) => const HttpService());
