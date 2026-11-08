import "dart:io";

import "package:http/http.dart" as http;
import "package:http/io_client.dart";

/// Creates a client that gives up connecting to a server after
/// [connectTimeout]
http.Client createHttpClient({required Duration connectTimeout}) {
  return IOClient(HttpClient()..connectionTimeout = connectTimeout);
}
